import 'package:equatable/equatable.dart';

class DownloadTrack extends Equatable {
  final int trackId;

  final String audioFile;
  final String imageFile;

  final String fileSignature;

  const DownloadTrack({
    required this.trackId,
    required this.audioFile,
    required this.imageFile,
    required this.fileSignature,
  });

  @override
  List<Object> get props => [
        trackId,
        audioFile,
        imageFile,
        fileSignature,
      ];
}
