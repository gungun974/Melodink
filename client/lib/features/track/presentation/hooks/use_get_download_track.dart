import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:melodink_client/features/track/domain/events/download_events.dart';

DownloadTrack? useGetDownloadTrack(int trackId, WidgetRef ref) {
  return useAsyncGetDownloadTrack(trackId, ref).data;
}

AsyncSnapshot<DownloadTrack?> useAsyncGetDownloadTrack(
  int trackId,
  WidgetRef ref,
) {
  final eventBus = ref.read(eventBusProvider);
  final downloadTrackRepository = ref.read(downloadTrackRepositoryProvider);

  final reloadKey = useState(UniqueKey());

  final downloadTrackFuture = useMemoized(() {
    return downloadTrackRepository.getDownloadedTrackByTrackId(trackId);
  }, [reloadKey.value]);

  useEffect(() {
    final subscribe = eventBus.on<DownloadTrackEvent>().listen((event) {
      if (event.trackId != trackId) {
        return;
      }

      reloadKey.value = UniqueKey();
    });

    return () {
      subscribe.cancel();
    };
  }, []);

  return useFuture(downloadTrackFuture, preserveState: true);
}
