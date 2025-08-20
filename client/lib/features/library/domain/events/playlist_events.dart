import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';

class CreatePlaylistEvent extends EventBusEvent {
  final Playlist createdPlaylist;

  CreatePlaylistEvent({required this.createdPlaylist});
}

class EditPlaylistEvent extends EventBusEvent {
  final Playlist updatedPlaylist;

  EditPlaylistEvent({required this.updatedPlaylist});
}

class DeletePlaylistEvent extends EventBusEvent {
  final Playlist deletedPlaylist;

  DeletePlaylistEvent({required this.deletedPlaylist});
}
