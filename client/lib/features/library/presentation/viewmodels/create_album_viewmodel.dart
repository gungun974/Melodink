import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/domain/events/album_events.dart';
import 'package:melodink_client/features/library/presentation/modals/select_artists_modal.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class CreateAlbumViewModel extends ChangeNotifier {
  final EventBus eventBus;

  final AlbumRepository albumRepository;

  CreateAlbumViewModel({required this.eventBus, required this.albumRepository});

  final formKey = GlobalKey<FormState>();

  bool autoValidate = false;

  bool isLoading = false;

  bool hasError = false;

  final nameTextController = TextEditingController();

  List<Artist> artists = [];

  @override
  void dispose() {
    nameTextController.dispose();

    super.dispose();
  }

  Future<void> selectArtists(BuildContext context) async {
    final newArtists = await SelectArtistsModal.showModal(
      context,
      artists.map((artist) => artist.id).toList(),
    );

    if (newArtists != null) {
      if (newArtists.isEmpty) {
        artists.clear();
        notifyListeners();
      } else {
        artists = newArtists;
        notifyListeners();
      }
    }
  }

  Future<void> createAlbum(
    BuildContext context,
    bool pushRouteToNewAlbum,
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
      Album newAlbum = await albumRepository.createAlbum(
        Album(
          id: -1,
          name: nameTextController.text,
          tracks: [],
          coverSignature: "",
          artists: artists,
        ),
      );

      if (artists.isNotEmpty) {
        newAlbum = await albumRepository.setAlbumArtists(newAlbum.id, artists);
      }

      eventBus.fire(CreateAlbumEvent(createdAlbum: newAlbum));

      isLoading = false;

      notifyListeners();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop(newAlbum);

      if (pushRouteToNewAlbum) {
        GoRouter.of(context).push("/album/${newAlbum.id}");
      }

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.albumHaveBeenCreated.message(
          name: newAlbum.name,
        ),
      );
    } catch (_) {
      isLoading = false;
      hasError = true;
      notifyListeners();
    }
  }
}
