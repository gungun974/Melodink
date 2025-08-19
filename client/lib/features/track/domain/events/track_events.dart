import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';

class CreateTrackEvent extends EventBusEvent {
  final Track createdTrack;

  CreateTrackEvent({required this.createdTrack});
}

class EditTrackEvent extends EventBusEvent {
  final Track updatedTrack;

  EditTrackEvent({required this.updatedTrack});
}

class DeleteTrackEvent extends EventBusEvent {
  final Track deletedTrack;

  DeleteTrackEvent({required this.deletedTrack});
}
