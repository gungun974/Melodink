import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/presentation/modals/show_track_modal.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class SingleTrackContextMenu extends ConsumerWidget {
  const SingleTrackContextMenu({
    super.key,
    required this.track,
    required this.menuController,
    required this.child,
    this.customActionsBuilder,
  });

  final MinimalTrack track;

  final MenuController menuController;

  final List<Widget> Function(
    BuildContext context,
    MenuController menuController,
    MinimalTrack track,
  )? customActionsBuilder;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(audioControllerProvider);
    final asyncPlaylists = ref.watch(playlistContextMenuNotifierProvider);

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.playlist,
            size: 20,
          ),
          child: Text(t.actions.addToQueue),
          onPressed: () {
            audioController.addTrackToQueue(track);
            menuController.close();

            AppNotificationManager.of(context).notify(
              context,
              message: t.notifications.haveBeenAddedToQueue.message(n: 1),
            );
          },
        ),
        SubmenuButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.playlist2,
            size: 20,
          ),
          menuChildren: switch (asyncPlaylists) {
            AsyncData(:final value) => value.map((playlist) {
                return MenuItemButton(
                  child: Text(playlist.name),
                  onPressed: () async {
                    menuController.close();

                    if (!NetworkInfo().isServerRecheable()) {
                      AppNotificationManager.of(context).notify(
                        context,
                        title: t.notifications.offline.title,
                        message: t.notifications.offline.message,
                        type: AppNotificationType.danger,
                      );
                      return;
                    }

                    try {
                      await ref
                          .read(playlistContextMenuNotifierProvider.notifier)
                          .addTracks(
                        playlist,
                        [track],
                      );
                    } catch (_) {
                      if (context.mounted) {
                        AppNotificationManager.of(context).notify(
                          context,
                          title: t.notifications.somethingWentWrong.title,
                          message: t.notifications.somethingWentWrong.message,
                          type: AppNotificationType.danger,
                        );
                      }

                      rethrow;
                    }

                    if (!context.mounted) {
                      return;
                    }

                    AppNotificationManager.of(context).notify(
                      context,
                      message:
                          t.notifications.playlistTrackHaveBeenAdded.message(
                        n: 1,
                        name: playlist.name,
                      ),
                    );
                  },
                );
              }).toList(),
            _ => const [],
          },
          child: Text(t.actions.addToPlaylist),
        ),
        const Divider(height: 8),
        MenuItemButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.media_optical,
            size: 20,
          ),
          child: Text(t.actions.goToAlbum),
          onPressed: () {
            while (
                GoRouter.of(context).location?.startsWith("/queue") ?? true) {
              GoRouter.of(context).pop();
            }

            while (
                GoRouter.of(context).location?.startsWith("/player") ?? true) {
              GoRouter.of(context).pop();
            }

            GoRouter.of(context).push("/album/${track.albumId}");
          },
        ),
        if (track.artists.length == 1)
          MenuItemButton(
            leadingIcon: const AdwaitaIcon(
              AdwaitaIcons.person2,
              size: 20,
            ),
            child: Text(t.actions.goToArtist),
            onPressed: () {
              while (
                  GoRouter.of(context).location?.startsWith("/queue") ?? true) {
                GoRouter.of(context).pop();
              }

              while (GoRouter.of(context).location?.startsWith("/player") ??
                  true) {
                GoRouter.of(context).pop();
              }

              GoRouter.of(context).push("/artist/${track.artists.first.id}");
            },
          ),
        if (track.artists.length > 1)
          SubmenuButton(
            leadingIcon: const AdwaitaIcon(
              AdwaitaIcons.person2,
              size: 20,
            ),
            menuChildren: track.artists.map(
              (artist) {
                return MenuItemButton(
                  leadingIcon: const AdwaitaIcon(
                    AdwaitaIcons.person2,
                    size: 20,
                  ),
                  child: Text(artist.name),
                  onPressed: () {
                    while (
                        GoRouter.of(context).location?.startsWith("/queue") ??
                            true) {
                      GoRouter.of(context).pop();
                    }

                    while (
                        GoRouter.of(context).location?.startsWith("/player") ??
                            true) {
                      GoRouter.of(context).pop();
                    }

                    GoRouter.of(context).push("/artist/${artist.id}");
                  },
                );
              },
            ).toList(),
            child: Text(t.actions.goToArtist),
          ),
        if (customActionsBuilder != null)
          ...customActionsBuilder!(context, menuController, track),
        const Divider(height: 8),
        MenuItemButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.folder_download,
            size: 20,
          ),
          child: Text(t.actions.exportFileToDevice),
          onPressed: () async {
            menuController.close();

            if (!NetworkInfo().isServerRecheable()) {
              AppNotificationManager.of(context).notify(
                context,
                title: t.notifications.offline.title,
                message: t.notifications.offline.message,
                type: AppNotificationType.danger,
              );
              return;
            }

            AppNotificationManager.of(context).notify(
              context,
              message: t.notifications.exportingTrackStart.message(
                title: track.title,
              ),
            );

            try {
              final extensionResponse = await AppApi()
                  .dio
                  .get<String>("/track/${track.id}/extension");

              final extension = extensionResponse.data;

              if (extension == null) {
                throw ServerTimeoutException();
              }

              await FileSaver.instance.saveFile(
                name:
                    "${track.trackNumber.toString().padLeft(2, '0')} - ${track.title}"
                        .trim(),
                link: LinkDetails(
                  link: track.getUrl(AppSettingAudioQuality.directFile),
                  headers: {"Cookie": AppApi().generateCookieHeader()},
                  method: "GET",
                ),
                ext: extension,
              );

              if (!context.mounted) {
                return;
              }

              AppNotificationManager.of(context).notify(
                context,
                message: t.notifications.exportingTrackEnd.message(
                  title: track.title,
                ),
              );
            } catch (e) {
              if (context.mounted) {
                AppNotificationManager.of(context).notify(
                  context,
                  title: t.notifications.somethingWentWrong.title,
                  message: t.notifications.somethingWentWrong.message,
                  type: AppNotificationType.danger,
                );
              }

              rethrow;
            }
          },
        ),
        MenuItemButton(
          leadingIcon: const AdwaitaIcon(
            AdwaitaIcons.info,
            size: 20,
          ),
          child: Text(t.general.properties),
          onPressed: () {
            menuController.close();

            if (!NetworkInfo().isServerRecheable()) {
              AppNotificationManager.of(context).notify(
                context,
                title: t.notifications.offline.title,
                message: t.notifications.offline.message,
                type: AppNotificationType.danger,
              );
              return;
            }

            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "ShowTrackModal",
              pageBuilder: (_, __, ___) {
                return Center(
                  child: MaxContainer(
                    maxWidth: 800,
                    maxHeight: 540,
                    padding: const EdgeInsets.all(16),
                    child: ShowTrackModal(
                      trackId: track.id,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
      controller: menuController,
      child: child,
    );
  }
}
