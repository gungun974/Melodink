import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/tracks/presentation/widgets/tracks_list.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  const SliverContainer(
                    maxWidth: 1200,
                    padding: 32,
                    sliver: SliverPadding(
                      padding: EdgeInsets.only(top: 48),
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
                  ...(state.previousTrack.isNotEmpty
                      ? [
                          const SliverContainer(
                            maxWidth: 1200,
                            padding: 32,
                            sliver: SliverPadding(
                              padding: EdgeInsets.only(top: 8),
                              sliver: SliverToBoxAdapter(
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
                            padding: 32,
                            sliver: SliverPadding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 16),
                              sliver: SliverFixedExtentList(
                                itemExtent: 56,
                                delegate: SliverChildBuilderDelegate(
                                  (context, _) {
                                    return buildTableRow(
                                      context,
                                      state.previousTrack.last,
                                      1,
                                      () {},
                                    );
                                  },
                                  childCount: 1,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : []),
                  ...(state.queueTracks.isNotEmpty
                      ? [
                          const SliverContainer(
                            maxWidth: 1200,
                            padding: 32,
                            sliver: SliverPadding(
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
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 48),
                              sliver: SliverFixedExtentList(
                                itemExtent: 56,
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return buildTableRow(
                                      context,
                                      state.queueTracks[index],
                                      index + 2,
                                      () {},
                                    );
                                  },
                                  childCount: state.queueTracks.length,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : []),
                  const SliverContainer(
                    maxWidth: 1200,
                    padding: 32,
                    sliver: SliverPadding(
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
                    padding: 32,
                    sliver: SliverPadding(
                      padding: const EdgeInsets.only(top: 8, bottom: 48),
                      sliver: SliverFixedExtentList(
                        itemExtent: 56,
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return buildTableRow(
                              context,
                              state.nextTracks[index],
                              index + 1 + state.queueTracks.length,
                              () {},
                            );
                          },
                          childCount: state.nextTracks.length,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
