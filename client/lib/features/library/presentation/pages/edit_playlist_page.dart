import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart' hide ReorderableList;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/helpers/pick_audio_files.dart';
import 'package:melodink_client/core/hooks/use_provider.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/providers/edit_playlist_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_context_menu_provider.dart';
import 'package:melodink_client/features/library/domain/providers/playlist_provider.dart';
import 'package:melodink_client/features/library/presentation/hooks/use_dragable_tracks.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class PlaylistPageEdit extends HookConsumerWidget {
  final int playlistId;

  const PlaylistPageEdit({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final asyncPlaylist = ref.watch(playlistByIdProvider(playlistId));

    final playlist = asyncPlaylist.valueOrNull;

    final rawTracks = useProviderAsync<List<Track>>(
      ref,
      playlistSortedTracksProvider(playlistId),
      [],
    );

    final (
      tracks,
      orderKeys,
      reorderCallback,
      reorderDone,
      dragCancelToken,
    ) = useDragableTracks(
      rawTracks,
      (List<Track> newTracks) async {},
      [],
    );

    final isLoading = useState(false);

    final hasError = useState(false);

    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

    final autoValidate = useState(false);

    if (playlist == null) {
      return AppNavigationHeader(
        title: AppScreenTypeLayoutBuilders(
          mobile: (_) => Text(t.general.editPlaylist(
            name: "",
          )),
        ),
        child: Container(),
      );
    }

    final nameTextController = useTextEditingController(
      text: playlist.name,
    );

    final descriptionTextController = useTextEditingController(
      text: playlist.description,
    );

    final refreshKey = useState(0);

    final fetchSignature = useMemoized(
      () => AppApi()
          .dio
          .get<String>("/playlist/${playlist.id}/cover/custom/signature"),
      [refreshKey.value],
    );

    final coverSignature = useFuture(fetchSignature, preserveState: false).data;

    return Stack(
      children: [
        AppNavigationHeader(
          alwayShow: true,
          title: Text(t.general.editPlaylist(
            name: playlist.name,
          )),
          actions: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: AppButton(
                    text: t.general.save,
                    type: AppButtonType.primary,
                    onPressed: () async {
                      if (!NetworkInfo().isServerRecheable()) {
                        AppNotificationManager.of(context).notify(
                          context,
                          title: t.notifications.offline.title,
                          message: t.notifications.offline.message,
                          type: AppNotificationType.danger,
                        );

                        return;
                      }

                      hasError.value = false;
                      final currentState = formKey.currentState;
                      if (currentState == null) {
                        return;
                      }

                      if (!currentState.validate()) {
                        autoValidate.value = true;
                        return;
                      }

                      isLoading.value = true;

                      try {
                        final newPlaylist = await ref
                            .read(editPlaylistStreamProvider.notifier)
                            .savePlaylist(Playlist(
                              id: playlist.id,
                              name: nameTextController.text,
                              description: descriptionTextController.text,
                              tracks: tracks.value,
                              coverSignature: "",
                            ));

                        await ref
                            .read(playlistContextMenuNotifierProvider.notifier)
                            .setTracks(
                              playlist,
                              tracks.value,
                            );

                        isLoading.value = false;

                        if (!context.mounted) {
                          return;
                        }

                        GoRouter.of(context).pop();

                        AppNotificationManager.of(context).notify(
                          context,
                          message:
                              t.notifications.playlistHaveBeenSaved.message(
                            name: newPlaylist.name,
                          ),
                        );
                      } catch (_) {
                        isLoading.value = false;
                        hasError.value = true;
                      }
                    },
                  ),
                ),
              ],
            )
          ],
          child: AppScreenTypeLayoutBuilder(
            builder: (context, size) {
              final maxWidth = size == AppScreenTypeLayout.desktop ? 1200 : 512;
              final padding = size == AppScreenTypeLayout.desktop ? 24.0 : 16.0;

              final separator =
                  size == AppScreenTypeLayout.desktop ? 16.0 : 12.0;

              return Form(
                key: formKey,
                child: ReorderableList(
                  onReorder: reorderCallback,
                  onReorderDone: reorderDone,
                  cancellationToken: dragCancelToken,
                  child: CustomScrollView(
                    key: scrollViewKey,
                    controller: scrollController,
                    slivers: [
                      if (hasError.value)
                        SliverToBoxAdapter(
                            child: Column(
                          children: [
                            AppErrorBox(
                              title: t.notifications.somethingWentWrong.title,
                              message:
                                  t.notifications.somethingWentWrong.message,
                            ),
                            const SizedBox(height: 16),
                          ],
                        )),
                      SliverContainer(
                        maxWidth: maxWidth,
                        padding: EdgeInsets.only(
                          left: padding,
                          right: padding,
                          top: padding,
                          bottom: separator,
                        ),
                        sliver: Builder(builder: (context) {
                          final editCoverWidget = Column(
                            children: [
                              if (size == AppScreenTypeLayout.desktop)
                                AuthCachedNetworkImage(
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  imageUrl: playlist.getCompressedCoverUrl(
                                    TrackCompressedCoverQuality.high,
                                  ),
                                  placeholder: (context, url) => Image.asset(
                                    "assets/melodink_track_cover_not_found.png",
                                  ),
                                  errorWidget: (context, url, error) {
                                    return Image.asset(
                                      "assets/melodink_track_cover_not_found.png",
                                    );
                                  },
                                  width: 256,
                                  height: 256,
                                  gaplessPlayback: true,
                                ),
                              if (size == AppScreenTypeLayout.mobile)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48.0,
                                    vertical: 6.0,
                                  ),
                                  child: AuthCachedNetworkImage(
                                    fit: BoxFit.contain,
                                    imageUrl: playlist.getCompressedCoverUrl(
                                      TrackCompressedCoverQuality.high,
                                    ),
                                    placeholder: (context, url) => Image.asset(
                                      "assets/melodink_track_cover_not_found.png",
                                    ),
                                    errorWidget: (context, url, error) {
                                      return Image.asset(
                                        "assets/melodink_track_cover_not_found.png",
                                      );
                                    },
                                    gaplessPlayback: true,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (coverSignature?.data?.trim() == "")
                                Row(
                                  children: [
                                    Expanded(
                                      flex: size == AppScreenTypeLayout.mobile
                                          ? 1
                                          : 0,
                                      child: SizedBox(
                                        width: 256,
                                        child: AppButton(
                                          text: t.actions.changeCover,
                                          type: AppButtonType.secondary,
                                          onPressed: () async {
                                            final file = await pickImageFile();

                                            if (file == null) {
                                              return;
                                            }

                                            isLoading.value = true;
                                            try {
                                              await ref
                                                  .read(
                                                      editPlaylistStreamProvider
                                                          .notifier)
                                                  .changePlaylistCover(
                                                      playlist.id, file);
                                              isLoading.value = false;
                                            } catch (_) {
                                              isLoading.value = false;

                                              if (context.mounted) {
                                                AppNotificationManager.of(
                                                        context)
                                                    .notify(
                                                  context,
                                                  title: t.notifications
                                                      .somethingWentWrong.title,
                                                  message: t
                                                      .notifications
                                                      .somethingWentWrong
                                                      .message,
                                                  type: AppNotificationType
                                                      .danger,
                                                );
                                              }
                                              rethrow;
                                            }

                                            refreshKey.value += 1;

                                            if (!context.mounted) {
                                              return;
                                            }

                                            AppNotificationManager.of(context)
                                                .notify(context,
                                                    message: t.notifications
                                                        .playlistCoverHaveBeenChanged
                                                        .message(
                                                      name: playlist.name,
                                                    ));
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (coverSignature?.data?.trim() != "")
                                Row(
                                  children: [
                                    Expanded(
                                      flex: size == AppScreenTypeLayout.mobile
                                          ? 1
                                          : 0,
                                      child: SizedBox(
                                        width: 256,
                                        child: AppButton(
                                          text: t.actions.removeCover,
                                          type: AppButtonType.secondary,
                                          onPressed: () async {
                                            if (!await appConfirm(
                                              context,
                                              title: t.confirms.title,
                                              content:
                                                  t.confirms.removeCustomCover,
                                              textOK: t.confirms.confirm,
                                            )) {
                                              return;
                                            }

                                            isLoading.value = true;
                                            try {
                                              await ref
                                                  .read(
                                                      editPlaylistStreamProvider
                                                          .notifier)
                                                  .removePlaylistCover(
                                                      playlist.id);
                                              isLoading.value = false;
                                            } catch (_) {
                                              isLoading.value = false;

                                              if (context.mounted) {
                                                AppNotificationManager.of(
                                                        context)
                                                    .notify(
                                                  context,
                                                  title: t.notifications
                                                      .somethingWentWrong.title,
                                                  message: t
                                                      .notifications
                                                      .somethingWentWrong
                                                      .message,
                                                  type: AppNotificationType
                                                      .danger,
                                                );
                                              }
                                              rethrow;
                                            }

                                            refreshKey.value += 1;

                                            if (!context.mounted) {
                                              return;
                                            }

                                            AppNotificationManager.of(context)
                                                .notify(
                                              context,
                                              message: t.notifications
                                                  .playlistCoverHaveBeenRemoved
                                                  .message(
                                                name: playlist.name,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );

                          final editFields = Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextFormField(
                                  labelText: t.general.name,
                                  controller: nameTextController,
                                  autovalidateMode: autoValidate.value
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose(
                                    [
                                      FormBuilderValidators.required(
                                        errorText:
                                            t.validators.fieldShouldNotBeEmpty(
                                          field: t.general.name,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: AppTextFormField(
                                    labelText: t.general.description,
                                    controller: descriptionTextController,
                                    maxLines: null,
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (size == AppScreenTypeLayout.desktop) {
                            return SliverToBoxAdapter(
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    editCoverWidget,
                                    const SizedBox(width: 16),
                                    editFields,
                                  ],
                                ),
                              ),
                            );
                          }

                          return SliverToBoxAdapter(
                            child: IntrinsicHeight(
                              child: Column(
                                children: [
                                  editFields,
                                  const SizedBox(height: 16),
                                  editCoverWidget,
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      SliverContainer(
                        maxWidth: maxWidth,
                        padding: EdgeInsets.only(
                          left: padding,
                          right: padding,
                        ),
                        sliver: StickyDesktopTrackHeader(
                          modules: [
                            DesktopTrackModule.remove,
                            DesktopTrackModule.title,
                            DesktopTrackModule.album,
                            DesktopTrackModule.lastPlayed,
                            DesktopTrackModule.playedCount,
                            DesktopTrackModule.quality,
                            DesktopTrackModule.duration,
                            DesktopTrackModule.score,
                            DesktopTrackModule.reorderable,
                          ],
                          scrollController: scrollController,
                          scrollViewKey: scrollViewKey,
                        ),
                      ),
                      SliverContainer(
                        maxWidth: maxWidth,
                        padding: EdgeInsets.only(
                          left: padding,
                          right: padding,
                        ),
                        sliver: TrackList(
                          tracks: tracks.value,
                          orderKeys: orderKeys.value,
                          size: size,
                          showTrackIndex: false,
                          showPlayButton: false,
                          modules: const [
                            DesktopTrackModule.remove,
                            DesktopTrackModule.title,
                            DesktopTrackModule.album,
                            DesktopTrackModule.lastPlayed,
                            DesktopTrackModule.playedCount,
                            DesktopTrackModule.quality,
                            DesktopTrackModule.duration,
                            DesktopTrackModule.score,
                            DesktopTrackModule.reorderable,
                          ],
                          playCallback: (_, __) {},
                          showDefaultActions: false,
                          removeCallback: (_, index) {
                            tracks.value = tracks.value.indexed
                                .where((entry) => entry.$1 != index)
                                .map((entry) => entry.$2)
                                .toList();
                          },
                          singleCustomActionsBuilder: (
                            context,
                            menuController,
                            _,
                            index,
                            unselect,
                          ) {
                            return [
                              MenuItemButton(
                                leadingIcon: const AdwaitaIcon(
                                  AdwaitaIcons.list_remove,
                                  size: 20,
                                ),
                                child: Text(t.actions.removeFromPlaylist),
                                onPressed: () async {
                                  menuController.close();

                                  tracks.value = tracks.value.indexed
                                      .where((entry) => entry.$1 != index)
                                      .map((entry) => entry.$2)
                                      .toList();

                                  unselect();
                                },
                              ),
                            ];
                          },
                          multiCustomActionsBuilder: (
                            context,
                            menuController,
                            _,
                            selectedIndexes,
                            unselect,
                          ) {
                            return [
                              MenuItemButton(
                                leadingIcon: const AdwaitaIcon(
                                  AdwaitaIcons.list_remove,
                                  size: 20,
                                ),
                                child: Text(t.actions.removeFromPlaylist),
                                onPressed: () async {
                                  menuController.close();

                                  tracks.value = tracks.value.indexed
                                      .where(
                                        (entry) =>
                                            !selectedIndexes.contains(entry.$1),
                                      )
                                      .map((entry) => entry.$2)
                                      .toList();

                                  menuController.close();
                                  unselect();
                                },
                              ),
                            ];
                          },
                          source: "${t.general.playlist} \"${playlist.name}\"",
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (isLoading.value) const AppPageLoader(),
      ],
    );
  }
}
