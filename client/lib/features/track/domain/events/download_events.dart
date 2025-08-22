import 'package:melodink_client/core/event_bus/event_bus.dart';

class DownloadTrackEvent extends EventBusEvent {
  final int trackId;

  final bool downloaded;

  DownloadTrackEvent({required this.trackId, required this.downloaded});
}
