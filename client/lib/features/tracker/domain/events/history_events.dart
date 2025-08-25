import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/tracker/domain/entities/played_track.dart';

class NewPlayedTrackEvent extends EventBusEvent {
  final PlayedTrack newPlayedTrack;

  NewPlayedTrackEvent({required this.newPlayedTrack});
}
