import 'package:audio_service/audio_service.dart';
import 'package:melodink_client/injection_container.dart';
import 'package:mpris_service/mpris_service.dart';

Future<void> initAudioMPRIS() async {
  final instance = await MPRIS.create(
    busName: 'org.mpris.MediaPlayer2.melodink',
    identity: 'Melodink',
    desktopEntry: '/usr/share/applications/melodink',
  );

  final audioHandler = sl<AudioHandler>();

  instance.setEventHandler(
    MPRISEventHandler(
      playPause: () async {
        if (audioHandler.playbackState.value.playing) {
          await audioHandler.pause();
          instance.playbackStatus = MPRISPlaybackStatus.paused;
          return;
        }
        await audioHandler.play();
        instance.playbackStatus = MPRISPlaybackStatus.playing;
      },
      play: () async {
        await audioHandler.play();
        instance.playbackStatus = MPRISPlaybackStatus.playing;
      },
      pause: () async {
        await audioHandler.pause();
        instance.playbackStatus = MPRISPlaybackStatus.paused;
      },
      next: () async {
        await audioHandler.skipToNext();
      },
      previous: () async {
        await audioHandler.skipToPrevious();
      },
    ),
  );

  audioHandler.playbackState.listen((state) {
    final queueIndex = state.queueIndex;
    if (queueIndex == null) {
      return;
    }

    if (queueIndex < 0 || queueIndex >= audioHandler.queue.value.length) {
      return;
    }

    final medatadata = audioHandler.queue.value[queueIndex];

    instance.metadata = MPRISMetadata(
      Uri.parse('https://music.youtube.com/watch?v=Gr6g3-6VQoE'),
      length: state.position,
      artUrl: medatadata.artUri,
      album: medatadata.album,
      albumArtist: medatadata.artist != null ? [medatadata.artist!] : [],
      artist: medatadata.artist != null ? [medatadata.artist!] : [],
      // discNumber: 1,
      title: medatadata.title,
      // trackNumber: 2,
    );

    instance.playbackStatus = state.playing
        ? MPRISPlaybackStatus.playing
        : MPRISPlaybackStatus.paused;
  });
}
