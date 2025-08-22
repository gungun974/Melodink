import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/download_track.dart';
import 'package:melodink_client/features/track/domain/events/download_events.dart';
import 'package:provider/provider.dart';

DownloadTrack? useGetDownloadTrack(BuildContext context, int trackId) {
  return useAsyncGetDownloadTrack(context, trackId).data;
}

AsyncSnapshot<DownloadTrack?> useAsyncGetDownloadTrack(
  BuildContext context,
  int trackId,
) {
  final eventBus = context.read<EventBus>();
  final downloadTrackRepository = context.read<DownloadTrackRepository>();

  final reloadKey = useState(UniqueKey());

  final downloadTrackFuture = useMemoized(() {
    return downloadTrackRepository.getDownloadedTrackByTrackId(trackId);
  }, [trackId, reloadKey.value]);

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
