import 'dart:async';
import 'dart:io';

import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/helpers/pick_audio_files.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/import_tracks_provider.dart';
import 'package:melodink_client/features/track/presentation/modals/edit_track_modal.dart';
import 'package:melodink_client/features/track/presentation/modals/scan_configuration_modal.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class ImportTracksModal extends HookConsumerWidget {
  const ImportTracksModal({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackRepository = ref.watch(trackRepositoryProvider);

    final state = ref.watch(importTracksProvider);

    final isLoading = useState(false);

    return Stack(
      children: [
        AppModal(
          title: Text(t.general.imports),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DropTarget(
                    onDragDone: (detail) {
                      ref.read(importTracksProvider.notifier).uploadAudios(
                            detail.files
                                .map(
                                  (file) => File(file.path),
                                )
                                .toList(),
                          );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount:
                            state.uploads.length + state.uploadedTracks.length,
                        itemBuilder: (context, index) {
                          if (index < state.uploads.length) {
                            final upload = state.uploads[index];

                            return Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: UploadTrack(
                                trackUploadProgress: upload,
                                removeOnTap: () {
                                  ref
                                      .read(importTracksProvider.notifier)
                                      .removeErrorUpload(upload);
                                },
                              ),
                            );
                          }

                          final track = state
                              .uploadedTracks[index - state.uploads.length];
                          return Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ImportTrack(
                              track: track,
                              onTap: () async {
                                isLoading.value = true;

                                late Track detailedTrack;

                                try {
                                  detailedTrack = await trackRepository
                                      .getTrackById(track.id);
                                } catch (_) {
                                  isLoading.value = false;
                                  return;
                                }

                                isLoading.value = false;

                                if (!context.mounted) {
                                  return;
                                }

                                EditTrackModal.showModal(
                                  context,
                                  detailedTrack,
                                  displayDateAdded: false,
                                );
                              },
                              removeOnTap: () {
                                ref
                                    .read(importTracksProvider.notifier)
                                    .removeTrack(track);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 192,
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: t.actions.addFileOrFiles,
                          type: AppButtonType.primary,
                          onPressed: () async {
                            final files = await pickAudioFiles();

                            ref
                                .read(importTracksProvider.notifier)
                                .uploadAudios(files);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: t.general.advancedScan,
                          type: AppButtonType.primary,
                          onPressed: state.uploadedTracks.isNotEmpty
                              ? () async {
                                  final configuration =
                                      await ScanConfigurationModal.showModal(
                                    context,
                                    hideAdvancedScanQuestion: true,
                                  );

                                  if (configuration == null) {
                                    return;
                                  }

                                  final streamController =
                                      StreamController<double>();

                                  final stream = streamController.stream
                                      .asBroadcastStream();

                                  final loadingWidget = OverlayEntry(
                                    builder: (context) => StreamBuilder(
                                        stream: stream,
                                        builder: (context, snapshot) {
                                          return AppPageLoader(
                                            value: snapshot.data,
                                          );
                                        }),
                                  );

                                  if (context.mounted) {
                                    Overlay.of(context, rootOverlay: true)
                                        .insert(loadingWidget);
                                  }

                                  try {
                                    await ref
                                        .read(importTracksProvider.notifier)
                                        .performAnAdvancedScans(
                                          configuration.onlyReplaceEmptyFields,
                                          streamController,
                                        );
                                    streamController.close();

                                    loadingWidget.remove();

                                    if (!context.mounted) {
                                      return;
                                    }

                                    AppNotificationManager.of(context).notify(
                                      context,
                                      message: t
                                          .notifications.trackHaveBeenScanned
                                          .message(
                                        n: state.uploadedTracks.length,
                                      ),
                                    );
                                  } catch (_) {
                                    streamController.close();
                                    if (context.mounted) {
                                      AppNotificationManager.of(context).notify(
                                        context,
                                        title: t.notifications
                                            .somethingWentWrong.title,
                                        message: t.notifications
                                            .somethingWentWrong.message,
                                        type: AppNotificationType.danger,
                                      );
                                    }
                                    loadingWidget.remove();
                                  }
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: t.general.import,
                          type: AppButtonType.primary,
                          onPressed: state.uploadedTracks.isNotEmpty
                              ? () async {
                                  final numberOfTracks =
                                      state.uploadedTracks.length;

                                  final result = await ref
                                      .read(importTracksProvider.notifier)
                                      .imports();

                                  if (!context.mounted) {
                                    return;
                                  }

                                  if (result) {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();

                                    AppNotificationManager.of(context).notify(
                                      context,
                                      message: t
                                          .notifications.trackHaveBeenImported
                                          .message(
                                        n: numberOfTracks,
                                      ),
                                    );
                                  } else {
                                    AppNotificationManager.of(context).notify(
                                      context,
                                      title: t.notifications.somethingWentWrong
                                          .title,
                                      message: t.notifications
                                          .somethingWentWrong.message,
                                      type: AppNotificationType.danger,
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isLoading.value || state.isLoading) const AppPageLoader(),
      ],
    );
  }

  static showModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ShowTrackModal",
      pageBuilder: (_, __, ___) {
        return HookConsumer(
          builder: (context, ref, _) {
            useEffect(() {
              Future(() {
                ref.read(importTracksProvider.notifier).refresh();
              });
              return null;
            }, []);

            return const Center(
              child: MaxContainer(
                maxWidth: 850,
                maxHeight: 540,
                padding: EdgeInsets.all(32),
                child: ImportTracksModal(),
              ),
            );
          },
        );
      },
    );
  }
}

class UploadTrack extends HookWidget {
  final TrackUploadProgress trackUploadProgress;

  final VoidCallback removeOnTap;

  const UploadTrack({
    super.key,
    required this.trackUploadProgress,
    required this.removeOnTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHovering = useState(false);

    return MouseRegion(
      onEnter: (_) {
        isHovering.value = true;
      },
      onExit: (_) {
        isHovering.value = false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: isHovering.value
              ? const Color.fromRGBO(0, 0, 0, 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: trackUploadProgress.error
                  ? const Center(
                      child: AdwaitaIcon(
                        size: 24,
                        AdwaitaIcons.dialog_warning,
                        color: Colors.redAccent,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trackUploadProgress.file.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 14 * 0.03,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<double>(
                      stream: trackUploadProgress.progress,
                      builder: (context, snapshot) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 8,
                            child: LinearProgressIndicator(
                              value: snapshot.data ?? 0,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Opacity(
              opacity: isHovering.value ? 1 : 0,
              child: GestureDetector(
                onTap: removeOnTap,
                child: Container(
                  height: 50,
                  color: Colors.transparent,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: AppIconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: AdwaitaIcon(AdwaitaIcons.edit_delete),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportTrack extends HookWidget {
  final MinimalTrack track;

  final VoidCallback onTap;
  final VoidCallback removeOnTap;

  const ImportTrack({
    super.key,
    required this.track,
    required this.onTap,
    required this.removeOnTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHovering = useState(false);

    return MouseRegion(
      onEnter: (_) {
        isHovering.value = true;
      },
      onExit: (_) {
        isHovering.value = false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isHovering.value
                ? const Color.fromRGBO(0, 0, 0, 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  "${track.trackNumber}",
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 14 * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AuthCachedNetworkImage(
                        imageUrl: track.getCompressedCoverUrl(
                          TrackCompressedCoverQuality.small,
                        ),
                        placeholder: (context, url) => Image.asset(
                          "assets/melodink_track_cover_not_found.png",
                        ),
                        errorWidget: (context, url, error) {
                          return Image.asset(
                            "assets/melodink_track_cover_not_found.png",
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tooltip(
                              message: track.title,
                              waitDuration: const Duration(milliseconds: 800),
                              child: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 14 * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: IgnorePointer(
                                    child: ArtistsLinksText(
                                      artists: track.artists,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 14 * 0.03,
                                        color: Colors.grey[350],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: IntrinsicWidth(
                  child: Text(
                    track.album,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 14 * 0.03,
                      color: Colors.grey[350],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 128,
                child: Text(
                  track.getQualityText(),
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 14 * 0.03,
                    color: Colors.grey[350],
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  durationToTime(track.duration),
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 14 * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Opacity(
                opacity: isHovering.value ? 1 : 0,
                child: GestureDetector(
                  onTap: removeOnTap,
                  child: Container(
                    height: 50,
                    color: Colors.transparent,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: AppIconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: AdwaitaIcon(AdwaitaIcons.edit_delete),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
