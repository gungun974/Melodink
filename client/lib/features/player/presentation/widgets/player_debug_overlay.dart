import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/features/player/domain/audio/melodink_player.dart';

class PlayerDebugOverlay extends HookWidget {
  const PlayerDebugOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final debugTracks = useState<List<MelodinkDebugTrack>>([]);

    useEffect(() {
      debugTracks.value = MelodinkPlayer().getDebugTracks();

      final timer = Timer.periodic(const Duration(milliseconds: 15), (_) {
        debugTracks.value = MelodinkPlayer().getDebugTracks();
      });

      return () {
        timer.cancel();
      };
    });

    final style = TextStyle(color: Colors.black);

    return IgnorePointer(
      child: Opacity(
        opacity: 0.75,
        child: IntrinsicHeight(
          child: Container(
            color: Colors.white.withAlpha(220),
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Id",
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Quality",
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Hit Cache",
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Status",
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Current",
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Buffered",
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Format",
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (debugTracks.value.isNotEmpty) SizedBox(height: 4),
                ...debugTracks.value.map((debugTrack) {
                  return Container(
                    color: debugTrack.currentTrack
                        ? Colors.greenAccent
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${debugTrack.id}",
                            style: style,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            debugTrack.quality.name,
                            style: style,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            debugTrack.cacheHitRatio.isNaN
                                ? "N/A"
                                : "${(debugTrack.cacheHitRatio * 100).toStringAsFixed(2)}%",
                            style: style,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            debugTrack.status.name,
                            style: style,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            debugTrack.currentPlayback.toStringAsFixed(2),
                            style: style,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            debugTrack.bufferedPlayback.toStringAsFixed(2),
                            style: style,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${debugTrack.sampleRate}hz ${debugTrack.sampleFormat.name} ${debugTrack.sampleSize} ${debugTrack.channelCount}ch",
                            style: style,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
