import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/features/track/domain/manager/download_manager.dart';
import 'package:provider/provider.dart';

class CurrentDownloadInfo extends StatelessWidget {
  const CurrentDownloadInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadManager = context.read<DownloadManager>();

    return ListenableBuilder(
      listenable: downloadManager,
      builder: (context, child) {
        final currentTask = downloadManager.state.currentTask;

        final isDownloadManagerRunning = downloadManager.state.isDownloading;

        if (!isDownloadManagerRunning) {
          return const SizedBox.shrink();
        }

        if (currentTask == null) {
          return const SizedBox.shrink();
        }

        final currentTrack = currentTask.track;

        final infoWidget = GestureDetector(
          onTap: () {},
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 250.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8.0),
              ),
              height: 56,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: StreamBuilder(
                              stream: currentTask.progress,
                              builder: (context, snapshot) {
                                return CircularProgressIndicator(
                                  strokeWidth: 3.0,
                                  value: snapshot.data,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTrack.title,
                              style: const TextStyle(
                                fontSize: 14,
                                letterSpacing: 14 * 0.03,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTrack.artists
                                  .map((artist) => artist.name)
                                  .join(", "),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 14 * 0.03,
                                color: Colors.grey[350],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 24),
                        const AdwaitaIcon(
                          AdwaitaIcons.folder_download,
                          size: 24,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppScreenTypeLayoutBuilders(
            desktop: (_) => IntrinsicWidth(child: infoWidget),
            mobile: (_) => infoWidget,
          ),
        );
      },
    );
  }
}
