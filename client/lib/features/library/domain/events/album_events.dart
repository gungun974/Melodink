import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';

class CreateAlbumEvent extends EventBusEvent {
  final Album createdAlbum;

  CreateAlbumEvent({required this.createdAlbum});
}

class EditAlbumEvent extends EventBusEvent {
  final Album updatedAlbum;

  EditAlbumEvent({required this.updatedAlbum});
}

class DeleteAlbumEvent extends EventBusEvent {
  final Album deletedAlbum;

  DeleteAlbumEvent({required this.deletedAlbum});
}
