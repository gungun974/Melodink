import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'track_provider.g.dart';

@Riverpod()
Future<DownloadTrack?> isTrackDownloaded(
  IsTrackDownloadedRef ref,
  int trackId,
) async {
  final downloadTrackRepository = ref.watch(downloadTrackRepositoryProvider);

  return await downloadTrackRepository.getDownloadedTrackByTrackId(trackId);
}
