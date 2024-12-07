import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:melodink_client/core/helpers/duration_to_time.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/features/track/presentation/modals/edit_track_modal.dart';

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
      actions: [
        AppIconButton(
          iconSize: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const AdwaitaIcon(AdwaitaIcons.edit),
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "EditTrackModal",
              pageBuilder: (_, __, ___) {
                return Center(
                  child: MaxContainer(
                    maxWidth: 800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 64,
                    ),
                    child: EditTrackModal(track: track),
                  ),
                );
              },
            );
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
                              AppValueTextField(
                                labelText: "Title",
                                value: track.title,
                                readOnly: true,
                              ),
                              const SizedBox(height: 8),
                              AppValueTextField(
                                labelText: "Duration",
                                value: durationToTime(track.duration),
                                readOnly: true,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppValueTextField(
                                      labelText: "Tags Format",
                                      value: track.tagsFormat,
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppValueTextField(
                                      labelText: "File Type",
                                      value: track.fileType,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AppValueTextField(
                                labelText: "File Signature",
                                value: track.fileSignature,
                                readOnly: true,
                              ),
                              const SizedBox(height: 8),
                              AppValueTextField(
                                labelText: "Date Added",
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
                                  (artist) => AppValueTextField(
                                    labelText: "Album Artist",
                                    value: artist.name,
                                    readOnly: true,
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
                                  (artist) => AppValueTextField(
                                    labelText: "Artist",
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
                        children: [
                          AppValueTextField(
                            labelText: "Album",
                            value: track.metadata.album,
                            readOnly: true,
                          ),
                          const Divider(
                            height: 24,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: AppValueTextField(
                                  labelText: "Track Number",
                                  value: "${track.metadata.trackNumber}",
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppValueTextField(
                                  labelText: "Total Tracks",
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
                                  labelText: "Track Disc",
                                  value: "${track.metadata.discNumber}",
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppValueTextField(
                                  labelText: "Total Disc",
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
                            labelText: "Date",
                            value: track.metadata.date,
                            readOnly: true,
                          ),
                          const SizedBox(height: 8),
                          AppValueTextField(
                            labelText: "Year",
                            value: "${track.metadata.year}",
                            readOnly: true,
                          ),
                          const Divider(
                            height: 24,
                          ),
                          AppValueTextField(
                            labelText: "Genres",
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
                            labelText: "MusicBrainz Release Id",
                            value: track.metadata.musicBrainzReleaseId,
                            readOnly: true,
                          ),
                          const SizedBox(height: 8),
                          AppValueTextField(
                            labelText: "MusicBrainz Track Id",
                            value: track.metadata.musicBrainzTrackId,
                            readOnly: true,
                          ),
                          const SizedBox(height: 8),
                          AppValueTextField(
                            labelText: "MusicBrainz Recording Id",
                            value: track.metadata.musicBrainzRecordingId,
                            readOnly: true,
                          ),
                          const Divider(
                            height: 24,
                          ),
                          AppValueTextField(
                            labelText: "Composer",
                            value: track.metadata.composer,
                            readOnly: true,
                          ),
                          const SizedBox(height: 8),
                          AppValueTextField(
                            labelText: "Comment",
                            value: track.metadata.comment,
                            readOnly: true,
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
