import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/injection_container.dart';

class TestPlayerPage extends StatefulWidget {
  const TestPlayerPage({super.key});

  @override
  State<TestPlayerPage> createState() => _TestPlayerPageState();
}

class _TestPlayerPageState extends State<TestPlayerPage> {
  final AudioController audioController = sl();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 260,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text("Previous"),
                      StreamBuilder(
                        initialData: audioController.previousTracks.value,
                        stream: audioController.previousTracks.stream,
                        builder: (context, snapshot) {
                          return Column(
                            children: snapshot.data!
                                .asMap()
                                .entries
                                .map((entry) =>
                                    Text("${entry.key}: ${entry.value.title}"))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 64),
                  Column(
                    children: [
                      const Text("Queue"),
                      StreamBuilder(
                        initialData: audioController.queueTracks.value,
                        stream: audioController.queueTracks.stream,
                        builder: (context, snapshot) {
                          return Column(
                            children: snapshot.data!
                                .asMap()
                                .entries
                                .map((entry) =>
                                    Text("${entry.key}: ${entry.value.title}"))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 64),
                  Column(
                    children: [
                      const Text("Next"),
                      StreamBuilder(
                        initialData: audioController.nextTracks.value,
                        stream: audioController.nextTracks.stream,
                        builder: (context, snapshot) {
                          return Column(
                            children: snapshot.data!
                                .asMap()
                                .entries
                                .map((entry) =>
                                    Text("${entry.key}: ${entry.value.title}"))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder(
                    stream: audioController.playbackState.stream,
                    builder: (context, snapshot) {
                      return Text("playing : ${snapshot.data?.playing}");
                    }),
                const SizedBox(width: 16),
                StreamBuilder(
                    stream: AudioService.position,
                    builder: (context, snapshot) {
                      return Text(
                          "position : ${snapshot.data?.inMilliseconds}");
                    }),
                const SizedBox(width: 16),
                StreamBuilder(
                    stream: audioController.playbackState.stream,
                    builder: (context, snapshot) {
                      return Text(
                          "buffered : ${snapshot.data?.bufferedPosition.inMilliseconds}");
                    }),
                const SizedBox(width: 16),
                StreamBuilder(
                    stream: audioController.playbackState.stream,
                    builder: (context, snapshot) {
                      return Text("index : ${snapshot.data?.queueIndex}");
                    }),
                const SizedBox(width: 16),
                StreamBuilder(
                  stream: audioController.currentTrack.stream,
                  builder: (context, snapshot) {
                    return Text(
                      "current : ${snapshot.data?.title ?? 'None'}",
                    );
                  },
                ),
                const SizedBox(width: 16),
                StreamBuilder(
                  stream: audioController.playbackState.stream,
                  builder: (context, snapshot) {
                    return Text(
                      "shuffle : ${snapshot.data?.shuffleMode == AudioServiceShuffleMode.all ? 'All' : 'None'}",
                    );
                  },
                ),
                const SizedBox(width: 16),
                StreamBuilder(
                  stream: audioController.playbackState.stream,
                  builder: (context, snapshot) {
                    return Text(
                      "loop : ${snapshot.data?.repeatMode == AudioServiceRepeatMode.all ? 'All' : (snapshot.data?.repeatMode == AudioServiceRepeatMode.one ? 'One' : 'No')}",
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await audioController.skipToPrevious();
                  },
                  child: const Text("previous"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController.play();
                  },
                  child: const Text("play"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController.seek(const Duration(seconds: 15));
                  },
                  child: const Text("seek 15s"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController.pause();
                  },
                  child: const Text("pause"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController.skipToNext();
                  },
                  child: const Text("next"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    audioController.loadTracks([
                      MinimalTrack(
                        id: 10,
                        title: "Test 1",
                        duration: const Duration(minutes: 2, seconds: 39),
                        album: "test",
                        trackNumber: 1,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 11,
                        title: "Test 2",
                        duration: const Duration(minutes: 4, seconds: 11),
                        album: "test",
                        trackNumber: 1,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                    ]);
                  },
                  child: const Text("load playlist 1"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    audioController.loadTracks([
                      MinimalTrack(
                        id: 18,
                        title: "Track 1",
                        duration: const Duration(minutes: 4, seconds: 5),
                        album: "test",
                        trackNumber: 1,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 19,
                        title: "Track 2",
                        duration: const Duration(minutes: 4, seconds: 3),
                        album: "test",
                        trackNumber: 2,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 20,
                        title: "Track 3",
                        duration: const Duration(minutes: 4, seconds: 20),
                        album: "test",
                        trackNumber: 3,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 21,
                        title: "Track 4",
                        duration: const Duration(minutes: 4, seconds: 26),
                        album: "test",
                        trackNumber: 4,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 22,
                        title: "Track 5",
                        duration: const Duration(minutes: 4, seconds: 1),
                        album: "test",
                        trackNumber: 5,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 23,
                        title: "Track 6",
                        duration: const Duration(minutes: 4, seconds: 2),
                        album: "test",
                        trackNumber: 6,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 24,
                        title: "Track 7",
                        duration: const Duration(minutes: 5, seconds: 14),
                        album: "test",
                        trackNumber: 7,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 25,
                        title: "Track 8",
                        duration: const Duration(minutes: 4, seconds: 0),
                        album: "test",
                        trackNumber: 8,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 26,
                        title: "Track 9",
                        duration: const Duration(minutes: 4, seconds: 0),
                        album: "test",
                        trackNumber: 9,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 27,
                        title: "Track 10",
                        duration: const Duration(minutes: 3, seconds: 51),
                        album: "test",
                        trackNumber: 10,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 28,
                        title: "Track 11",
                        duration: const Duration(minutes: 4, seconds: 51),
                        album: "test",
                        trackNumber: 11,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 29,
                        title: "Track 12",
                        duration: const Duration(minutes: 4, seconds: 32),
                        album: "test",
                        trackNumber: 12,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 30,
                        title: "Track 13",
                        duration: const Duration(minutes: 5, seconds: 23),
                        album: "test",
                        trackNumber: 13,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 31,
                        title: "Track 14",
                        duration: const Duration(minutes: 5, seconds: 17),
                        album: "test",
                        trackNumber: 14,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                    ]);
                  },
                  child: const Text("load playlist 2"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController.addTrackToQueue(
                      MinimalTrack(
                        id: 32,
                        title: "Queue test",
                        duration: const Duration(minutes: 2, seconds: 55),
                        album: "test",
                        trackNumber: 1,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                    );
                  },
                  child: const Text("add to queue"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    audioController.loadTracks([
                      MinimalTrack(
                        id: 10,
                        title: "Test 1",
                        duration: const Duration(minutes: 2, seconds: 39),
                        album: "test",
                        trackNumber: 1,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 11,
                        title: "Test 2",
                        duration: const Duration(minutes: 4, seconds: 11),
                        album: "test",
                        trackNumber: 1,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                      MinimalTrack(
                        id: 12,
                        title: "Test 3",
                        duration: const Duration(minutes: 4, seconds: 26),
                        album: "test",
                        trackNumber: 1,
                        discNumber: 1,
                        date: "2023",
                        year: 2023,
                        genre: "pop",
                        artist: "y",
                        albumArtist: "y",
                        composer: "y",
                        dateAdded: DateTime.now(),
                      ),
                    ], startAt: 2);
                  },
                  child: const Text("start at end"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await audioController
                        .setShuffleMode(AudioServiceShuffleMode.all);
                  },
                  child: const Text("shuffle"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController
                        .setShuffleMode(AudioServiceShuffleMode.none);
                  },
                  child: const Text("unshuffle"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController
                        .setRepeatMode(AudioServiceRepeatMode.none);
                  },
                  child: const Text("no loop"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController
                        .setRepeatMode(AudioServiceRepeatMode.all);
                  },
                  child: const Text("loop"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await audioController
                        .setRepeatMode(AudioServiceRepeatMode.one);
                  },
                  child: const Text("loop one"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
