import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/events/playlist_events.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class CreatePlaylistViewModel extends ChangeNotifier {
  final EventBus eventBus;

  final PlaylistRepository playlistRepository;

  CreatePlaylistViewModel({
    required this.eventBus,
    required this.playlistRepository,
  });

  final formKey = GlobalKey<FormState>();

  bool autoValidate = false;

  bool isLoading = false;

  bool hasError = false;

  final nameTextController = TextEditingController();

  final descriptionTextController = TextEditingController();

  @override
  void dispose() {
    nameTextController.dispose();
    descriptionTextController.dispose();

    super.dispose();
  }

  Future<void> createPlaylist(
    BuildContext context,
    List<Track> tracks,
    bool pushRouteToNewPlaylist,
  ) async {
    hasError = false;

    final currentState = formKey.currentState;
    if (currentState == null) {
      notifyListeners();
      return;
    }

    if (!currentState.validate()) {
      autoValidate = true;
      notifyListeners();
      return;
    }

    isLoading = true;

    notifyListeners();

    try {
      Playlist newPlaylist = await playlistRepository.createPlaylist(
        Playlist(
          id: -1,
          name: nameTextController.text,
          description: descriptionTextController.text,
          tracks: [],
          coverSignature: "",
        ),
      );

      if (tracks.isNotEmpty) {
        newPlaylist = await playlistRepository.setPlaylistTracks(
          newPlaylist.id,
          tracks,
        );
      }

      eventBus.fire(CreatePlaylistEvent(createdPlaylist: newPlaylist));

      isLoading = false;

      notifyListeners();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop(newPlaylist);

      if (pushRouteToNewPlaylist) {
        context.read<AppRouter>().push("/playlist/${newPlaylist.id}");
      }

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.playlistHaveBeenCreated.message(
          name: newPlaylist.name,
        ),
      );
    } catch (_) {
      isLoading = false;
      hasError = true;
      notifyListeners();
    }
  }
}
