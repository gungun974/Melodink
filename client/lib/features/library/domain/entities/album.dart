import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class Album extends Equatable {
  final String id;

  final String name;

  final String albumArtist;

  final List<MinimalTrack> tracks;

  const Album({
    required this.id,
    required this.name,
    required this.albumArtist,
    required this.tracks,
  });

  @override
  List<Object> get props => [
        id,
        name,
        albumArtist,
        tracks,
      ];

  String getCoverUrl() {
    return "${AppApi().getServerUrl()}album/$id/cover";
  }
}
