import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class CreateArtistViewModel extends ChangeNotifier {
  final EventBus eventBus;

  final ArtistRepository artistRepository;

  CreateArtistViewModel({
    required this.eventBus,
    required this.artistRepository,
  });

  final formKey = GlobalKey<FormState>();

  bool autoValidate = false;

  bool isLoading = false;

  bool hasError = false;

  final nameTextController = TextEditingController();

  @override
  void dispose() {
    nameTextController.dispose();

    super.dispose();
  }

  Future<void> createArtist(
    BuildContext context,
    bool pushRouteToNewArtist,
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
      Artist newArtist = await artistRepository.createArtist(
        Artist(
          id: -1,
          name: nameTextController.text,
          albums: [],
          appearAlbums: [],
          hasRoleAlbums: [],
        ),
      );

      isLoading = false;

      notifyListeners();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop(newArtist);

      if (pushRouteToNewArtist) {
        GoRouter.of(context).push("/artist/${newArtist.id}");
      }

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.artistHaveBeenCreated.message(
          name: newArtist.name,
        ),
      );
    } catch (_) {
      isLoading = false;
      hasError = true;
      notifyListeners();
    }
  }
}
