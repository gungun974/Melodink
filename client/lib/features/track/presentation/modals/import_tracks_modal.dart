import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/viewmodels/import_tracks_viewmodel.dart';
import 'package:melodink_client/features/track/presentation/widgets/artists_links_text.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class ImportTracksModal extends StatelessWidget {
  const ImportTracksModal({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onDragDone: (detail) => context
                        .read<ImportTracksViewModel>()
                        .uploadAudiosFromDropZone(detail),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Consumer<ImportTracksViewModel>(
                        builder: (context, viewModel, _) {
                          return ListView.builder(
                            itemCount:
                                viewModel.state.uploads.length +
                                viewModel.state.uploadedTracks.length,
                            itemBuilder: (context, index) {
                              if (index < viewModel.state.uploads.length) {
                                final upload = viewModel.state.uploads[index];

                                return Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: UploadTrack(
                                    trackUploadProgress: upload,
                                    removeOnTap: () =>
                                        viewModel.removeErrorUpload(upload),
                                  ),
                                );
                              }

                              final track =
                                  viewModel.state.uploadedTracks[index -
                                      viewModel.state.uploads.length];
                              return Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ImportTrack(
                                  track: track,
                                  onTap: () =>
                                      viewModel.showImportTrack(context, track),
                                  removeOnTap: () =>
                                      viewModel.removeTrack(track),
                                ),
                              );
                            },
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
                          onPressed: () => context
                              .read<ImportTracksViewModel>()
                              .uploadAudios(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Selector<ImportTracksViewModel, bool>(
                          selector: (_, viewModel) =>
                              viewModel.state.uploadedTracks.isNotEmpty,
                          builder: (context, enable, _) {
                            return AppButton(
                              text: t.general.advancedScan,
                              type: AppButtonType.primary,
                              onPressed: enable
                                  ? () {
                                      context
                                          .read<ImportTracksViewModel>()
                                          .handleAdvancedScans(context);
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Selector<ImportTracksViewModel, bool>(
                          selector: (_, viewModel) =>
                              viewModel.state.uploadedTracks.isNotEmpty,
                          builder: (context, enable, _) {
                            return AppButton(
                              text: t.general.import,
                              type: AppButtonType.primary,
                              onPressed: enable
                                  ? () => context
                                        .read<ImportTracksViewModel>()
                                        .importTracks(context)
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Selector<ImportTracksViewModel, bool>(
          selector: (_, viewModel) => viewModel.state.isLoading,
          builder: (context, isLoading, _) {
            if (!isLoading) {
              return const SizedBox.shrink();
            }
            return const AppPageLoader();
          },
        ),
      ],
    );
  }

  static void showModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ImportTracksModal",
      pageBuilder: (_, _, _) {
        return Center(
          child: MaxContainer(
            maxWidth: 850,
            maxHeight: 540,
            padding: EdgeInsets.all(32),
            child: ChangeNotifierProvider(
              create: (context) => ImportTracksViewModel(
                eventBus: context.read(),
                trackRepository: context.read(),
              ),
              child: ImportTracksModal(),
            ),
          ),
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
  final Track track;

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
                    track.albums.map((album) => album.name).join(", "),
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
