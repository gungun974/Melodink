import 'package:flutter/material.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/track/presentation/widgets/tracks_list.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:responsive_builder/responsive_builder.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({
    super.key,
  });

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final AudioController audioController = sl();

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (
      context,
      sizingInformation,
    ) {
      return Scaffold(
        appBar: sizingInformation.deviceScreenType != DeviceScreenType.desktop
            ? AppBar(
                title: const Text("Queue"),
              )
            : null,
        body: Stack(
          children: [
            Container(
              color: Colors.black87,
            ),
            const GradientBackground(),
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.08),
              child: StreamBuilder(
                stream: audioController.currentTrack.stream,
                builder: (context, snapshot) {
                  final currentTrack = snapshot.data;
                  if (currentTrack == null) {
                    return Container();
                  }

                  return CustomScrollView(
                    slivers: [
                      if (sizingInformation.deviceScreenType ==
                          DeviceScreenType.desktop)
                        const SliverContainer(
                          maxWidth: 1200,
                          padding: 32,
                          sliver: SliverPadding(
                            padding: EdgeInsets.only(top: 24),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                'Queue',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (audioController.previousTracks.value.isNotEmpty) ...[
                        SliverContainer(
                          maxWidth: 1200,
                          padding: sizingInformation.deviceScreenType ==
                                  DeviceScreenType.desktop
                              ? 32
                              : 16,
                          sliver: SliverPadding(
                            padding: EdgeInsets.only(
                                top: sizingInformation.deviceScreenType ==
                                        DeviceScreenType.desktop
                                    ? 8
                                    : 16),
                            sliver: const SliverToBoxAdapter(
                              child: Text(
                                'Now Playing',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverContainer(
                          maxWidth: 1200,
                          padding: sizingInformation.deviceScreenType ==
                                  DeviceScreenType.desktop
                              ? 32
                              : 0,
                          sliver: SliverPadding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            sliver: TracksList(
                              tracks: [
                                audioController.previousTracks.value.last,
                              ],
                              playCallback: (int index, _) {
                                audioController.skipToQueueItem(
                                  index +
                                      audioController
                                          .previousTracks.value.length -
                                      1,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      if (audioController.queueTracks.value.isNotEmpty) ...[
                        SliverContainer(
                          maxWidth: 1200,
                          padding: sizingInformation.deviceScreenType ==
                                  DeviceScreenType.desktop
                              ? 32
                              : 16,
                          sliver: const SliverPadding(
                            padding: EdgeInsets.only(top: 8),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                'Next in queue',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverContainer(
                          maxWidth: 1200,
                          padding: 32,
                          sliver: SliverPadding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            sliver: TracksList(
                              tracks: audioController.queueTracks.value,
                              numberOffset: 1,
                              playCallback: (int index, _) {
                                audioController.skipToQueueItem(
                                  index +
                                      audioController.queueTracks.value.length,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      SliverContainer(
                        maxWidth: 1200,
                        padding: sizingInformation.deviceScreenType ==
                                DeviceScreenType.desktop
                            ? 32
                            : 16,
                        sliver: const SliverPadding(
                          padding: EdgeInsets.only(top: 8),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Next up',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverContainer(
                        maxWidth: 1200,
                        padding: sizingInformation.deviceScreenType ==
                                DeviceScreenType.desktop
                            ? 32
                            : 0,
                        sliver: SliverPadding(
                          padding: const EdgeInsets.only(top: 8, bottom: 48),
                          sliver: TracksList(
                            tracks: audioController.nextTracks.value,
                            numberOffset:
                                1 + audioController.queueTracks.value.length,
                            playCallback: (int index, _) {
                              audioController.skipToQueueItem(
                                index +
                                    audioController
                                        .previousTracks.value.length +
                                    audioController.queueTracks.value.length,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
