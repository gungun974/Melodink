import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';

class ShowTrackModal extends ConsumerWidget {
  final int trackId;

  const ShowTrackModal({
    super.key,
    required this.trackId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTrack = ref.watch(trackByIdProvider(trackId));

    final track = asyncTrack.valueOrNull;

    if (track == null) {
      return const AppPageLoader();
    }

    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

    return AppModal(
      title: Text(track.title),
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
                        SizedBox(
                          width: 256,
                          height: 256,
                          child: AuthCachedNetworkImage(
                            imageUrl: track.getOriginalCoverUrl(),
                            placeholder: (context, url) => Image.asset(
                              "assets/melodink_track_cover_not_found.png",
                            ),
                            errorWidget: (context, url, error) {
                              return Image.asset(
                                "assets/melodink_track_cover_not_found.png",
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppReadTextField(
                                labelText: "Title",
                                value: track.title,
                              ),
                              const SizedBox(height: 8),
                              AppReadTextField(
                                labelText: "Duration",
                                value: durationToTime(track.duration),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppReadTextField(
                                      labelText: "Tags Format",
                                      value: track.tagsFormat,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppReadTextField(
                                      labelText: "File Type",
                                      value: track.fileType,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AppReadTextField(
                                labelText: "File Signature",
                                value: track.fileSignature,
                              ),
                              const SizedBox(height: 8),
                              AppReadTextField(
                                labelText: "Date Added",
                                value: formatter.format(track.dateAdded),
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
                          const Text(
                            "Album Artists",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 24,
                              letterSpacing: 24 * 0.04,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Column(
                            children: track.metadata.albumArtists
                                .map(
                                  (artist) => AppReadTextField(
                                    labelText: "Album Artist",
                                    value: artist.name,
                                  ),
                                )
                                .toList(),
                          ),
                          const Divider(
                            height: 24,
                          ),
                          const Text(
                            "Artists",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 24,
                              letterSpacing: 24 * 0.04,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Column(
                            children: track.metadata.artists
                                .map(
                                  (artist) => AppReadTextField(
                                    labelText: "Artist",
                                    value: artist.name,
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
                        children: [
                          AppReadTextField(
                            labelText: "Album",
                            value: track.metadata.album,
                          ),
                          const Divider(
                            height: 24,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: AppReadTextField(
                                  labelText: "Track Number",
                                  value: "${track.metadata.trackNumber}",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppReadTextField(
                                  labelText: "Total Tracks",
                                  value: "${track.metadata.totalTracks}",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppReadTextField(
                                  labelText: "Track Disc",
                                  value: "${track.metadata.discNumber}",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppReadTextField(
                                  labelText: "Total Disc",
                                  value: "${track.metadata.totalDiscs}",
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            height: 24,
                          ),
                          AppReadTextField(
                            labelText: "Date",
                            value: track.metadata.date,
                          ),
                          const SizedBox(height: 8),
                          AppReadTextField(
                            labelText: "Year",
                            value: "${track.metadata.year}",
                          ),
                          const Divider(
                            height: 24,
                          ),
                          AppReadTextField(
                            labelText: "Genres",
                            value: track.metadata.genres.join(";"),
                          ),
                          const Divider(
                            height: 24,
                          ),
                          AppReadTextField(
                            labelText: "AcoustId",
                            value: track.metadata.acoustId,
                          ),
                          const SizedBox(height: 8),
                          AppReadTextField(
                            labelText: "MusicBrainz Release Id",
                            value: track.metadata.musicBrainzReleaseId,
                          ),
                          const SizedBox(height: 8),
                          AppReadTextField(
                            labelText: "MusicBrainz Track Id",
                            value: track.metadata.musicBrainzTrackId,
                          ),
                          const SizedBox(height: 8),
                          AppReadTextField(
                            labelText: "MusicBrainz Recording Id",
                            value: track.metadata.musicBrainzRecordingId,
                          ),
                          const Divider(
                            height: 24,
                          ),
                          AppReadTextField(
                            labelText: "Composer",
                            value: track.metadata.composer,
                          ),
                          const SizedBox(height: 8),
                          AppReadTextField(
                            labelText: "Comment",
                            value: track.metadata.comment,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdwaitaIcon(AdwaitaIcons.preferences_system_details),
                      SizedBox(width: 8),
                      Text('Basic'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdwaitaIcon(AdwaitaIcons.text_justify_left),
                      SizedBox(width: 8),
                      Text('Lyrics'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdwaitaIcon(AdwaitaIcons.music_artist2),
                      SizedBox(width: 8),
                      Text('Artists'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdwaitaIcon(AdwaitaIcons.list),
                      SizedBox(width: 8),
                      Text('Details'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
