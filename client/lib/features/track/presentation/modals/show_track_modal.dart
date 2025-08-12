import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/features/track/domain/providers/delete_track_provider.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/modals/edit_track_modal.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class ShowTrackModal extends HookConsumerWidget {
  final int trackId;

  const ShowTrackModal({
    super.key,
    required this.trackId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTrack = ref.watch(trackByIdProvider(trackId));

    final isLoading = useState(false);

    final track = asyncTrack.valueOrNull;

    if (track == null) {
      return const AppPageLoader();
    }

    final DateFormat formatter = DateFormat.yMd().add_Hm();

    return Stack(
      children: [
        AppModal(
          title: Text(track.title),
          actions: [
            AppIconButton(
              iconSize: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              icon: const AdwaitaIcon(AdwaitaIcons.edit),
              onPressed: () {
                EditTrackModal.showModal(context, track);
              },
            ),
          ],
          body: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            AuthCachedNetworkImage(
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              imageUrl: track.getOriginalCoverUrl(),
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
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppValueTextField(
                                    labelText: t.general.trackTitle,
                                    value: track.title,
                                    readOnly: true,
                                  ),
                                  const SizedBox(height: 8),
                                  AppValueTextField(
                                    labelText: t.general.duration,
                                    value: durationToTime(track.duration),
                                    readOnly: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppValueTextField(
                                          labelText: t.general.tagsFormat,
                                          value: track.tagsFormat,
                                          readOnly: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AppValueTextField(
                                          labelText: t.general.fileType,
                                          value: track.fileType,
                                          readOnly: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  AppValueTextField(
                                    labelText: t.general.fileSignature,
                                    value: track.fileSignature,
                                    readOnly: true,
                                  ),
                                  const SizedBox(height: 8),
                                  AppValueTextField(
                                    labelText: t.general.dateAdded,
                                    value: formatter.format(track.dateAdded),
                                    readOnly: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(0, 0, 0, 0.37),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              track.metadata.lyrics,
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 16,
                                letterSpacing: 16 * 0.04,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.general.albumArtists,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                  letterSpacing: 24 * 0.04,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Column(
                                children: track.artists
                                    .map(
                                      (artist) => AppValueTextField(
                                        labelText: t.general.albumArtist,
                                        value: artist.name,
                                        readOnly: true,
                                      ),
                                    )
                                    .toList(),
                              ),
                              const Divider(
                                height: 24,
                              ),
                              Text(
                                t.general.artists,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                  letterSpacing: 24 * 0.04,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Column(
                                children: track.artists
                                    .map(
                                      (artist) => AppValueTextField(
                                        labelText: t.general.artist,
                                        value: artist.name,
                                        readOnly: true,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppValueTextField(
                                labelText: t.general.album,
                                value: track.albums
                                    .map((album) => album.name)
                                    .join(", "),
                                readOnly: true,
                              ),
                              const Divider(
                                height: 24,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppValueTextField(
                                      labelText: t.general.trackNumber,
                                      value: "${track.trackNumber}",
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppValueTextField(
                                      labelText: t.general.totalTracks,
                                      value: "${track.metadata.totalTracks}",
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppValueTextField(
                                      labelText: t.general.trackDisc,
                                      value: "${track.discNumber}",
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppValueTextField(
                                      labelText: t.general.totalDiscs,
                                      value: "${track.metadata.totalDiscs}",
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 24,
                              ),
                              AppValueTextField(
                                labelText: t.general.date,
                                value: track.metadata.date,
                                readOnly: true,
                              ),
                              const SizedBox(height: 8),
                              AppValueTextField(
                                labelText: t.general.year,
                                value: "${track.metadata.year}",
                                readOnly: true,
                              ),
                              const Divider(
                                height: 24,
                              ),
                              AppValueTextField(
                                labelText: t.general.genres,
                                value: track.metadata.genres.join(";"),
                                readOnly: true,
                              ),
                              const Divider(
                                height: 24,
                              ),
                              AppValueTextField(
                                labelText: "AcoustId",
                                value: track.metadata.acoustId,
                                readOnly: true,
                              ),
                              const SizedBox(height: 8),
                              AppValueTextField(
                                labelText: t.general.musicBrainzReleaseId,
                                value: track.metadata.musicBrainzReleaseId,
                                readOnly: true,
                              ),
                              const SizedBox(height: 8),
                              AppValueTextField(
                                labelText: t.general.musicBrainzTrackId,
                                value: track.metadata.musicBrainzTrackId,
                                readOnly: true,
                              ),
                              const SizedBox(height: 8),
                              AppValueTextField(
                                labelText: t.general.musicBrainzRecordingId,
                                value: track.metadata.musicBrainzRecordingId,
                                readOnly: true,
                              ),
                              const Divider(
                                height: 24,
                              ),
                              AppValueTextField(
                                labelText: t.general.composer,
                                value: track.metadata.composer,
                                readOnly: true,
                              ),
                              const SizedBox(height: 8),
                              AppValueTextField(
                                labelText: t.general.comment,
                                value: track.metadata.comment,
                                readOnly: true,
                              ),
                              const Divider(
                                height: 24,
                              ),
                              AppButton(
                                text: t.general.delete,
                                type: AppButtonType.danger,
                                onPressed: () async {
                                  if (!await appConfirm(
                                    context,
                                    title: t.confirms.title,
                                    content: t.confirms.deleteTrack,
                                    textOK: t.confirms.delete,
                                    isDangerous: true,
                                  )) {
                                    return;
                                  }

                                  isLoading.value = true;

                                  try {
                                    await ref
                                        .read(
                                            trackDeleteStreamProvider.notifier)
                                        .deleteTrack(track.id);

                                    isLoading.value = false;

                                    if (!context.mounted) {
                                      return;
                                    }

                                    AppNotificationManager.of(context).notify(
                                        context,
                                        message: t
                                            .notifications.trackHaveBeenDeleted
                                            .message(
                                          title: track.title,
                                        ));

                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                  } catch (_) {}
                                  isLoading.value = false;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AdwaitaIcon(
                              AdwaitaIcons.preferences_system_details),
                          const SizedBox(width: 8),
                          Text(t.general.basic),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AdwaitaIcon(AdwaitaIcons.text_justify_left),
                          const SizedBox(width: 8),
                          Text(t.general.lyrics),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AdwaitaIcon(AdwaitaIcons.music_artist2),
                          const SizedBox(width: 8),
                          Text(t.general.artists),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AdwaitaIcon(AdwaitaIcons.list),
                          const SizedBox(width: 8),
                          Text(t.general.details),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isLoading.value) const AppPageLoader(),
      ],
    );
  }
}
