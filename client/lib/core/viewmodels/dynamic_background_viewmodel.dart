import 'dart:async';
import 'dart:io';

import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:rxdart/rxdart.dart';

class DynamicBackgroundViewModel extends ChangeNotifier {
  final AudioController audioController;
  final DownloadTrackRepository downloadTrackRepository;

  List<List<int>>? currentPalette;

  StreamSubscription? _changeTrackStream;

  DynamicBackgroundViewModel({
    required this.audioController,
    required this.downloadTrackRepository,
  }) {
    _changeTrackStream = audioController.currentTrack.stream
        .startWith(audioController.currentTrack.value)
        .distinct((prev, next) => prev?.id == next?.id)
        .listen((currentTrack) async {
          if (currentTrack == null) {
            return;
          }

          final downloadedTrack = await downloadTrackRepository
              .getDownloadedTrackByTrackId(currentTrack.id);

          final imageUrl =
              downloadedTrack?.getCoverUrl() ??
              currentTrack.getCompressedCoverUrl(
                TrackCompressedCoverQuality.medium,
              );

          Uri? uri = Uri.tryParse(imageUrl);

          ImageProvider imageProvider;

          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            imageProvider = FileImage(await ImageCacheManager.getImage(uri));
          } else {
            imageProvider = FileImage(File(imageUrl));
          }

          final image = await getImageFromProvider(imageProvider);

          currentPalette = await getPaletteFromImage(image, 5, 5);
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _changeTrackStream?.cancel();
    super.dispose();
  }
}
