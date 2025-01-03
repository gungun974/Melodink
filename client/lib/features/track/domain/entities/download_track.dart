import 'package:equatable/equatable.dart';

class DownloadTrack extends Equatable {
  final int trackId;

  final String audioFile;
  final String? imageFile;

  final String fileSignature;
  final String coverSignature;

  const DownloadTrack({
    required this.trackId,
    required this.audioFile,
    required this.imageFile,
    required this.fileSignature,
    required this.coverSignature,
  });

  @override
  List<Object?> get props => [
        trackId,
        audioFile,
        imageFile,
        fileSignature,
        coverSignature,
      ];

  String getUrl() {
    return audioFile;
  }

  String? getCoverUrl() {
    return imageFile;
  }

  Uri getCoverUri() {
    final url = getCoverUrl();
    return Uri.parse("file://$url");
  }
}
