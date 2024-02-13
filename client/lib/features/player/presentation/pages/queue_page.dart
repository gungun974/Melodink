import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/tracks/presentation/widgets/tracks_list.dart';
import 'package:responsive_builder/responsive_builder.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({
    super.key,
  });

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
              child: BlocBuilder<PlayerCubit, PlayerState>(
                builder: (BuildContext context, PlayerState state) {
                  if (state is! PlayerPlaying) {
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
                      if (state.previousTrack.isNotEmpty) ...[
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
                                state.previousTrack.last,
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (state.queueTracks.isNotEmpty) ...[
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
                              tracks: state.queueTracks,
                              numberOffset: 1,
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
                            tracks: state.nextTracks,
                            numberOffset: 1 + state.queueTracks.length,
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
