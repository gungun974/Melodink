import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';

class CreatePlaylistEvent extends EventBusEvent {
  final Playlist createdPlaylist;

  CreatePlaylistEvent({required this.createdPlaylist});
}
