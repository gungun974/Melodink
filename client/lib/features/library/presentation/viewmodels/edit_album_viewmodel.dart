import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/helpers/pick_audio_files.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/domain/events/album_events.dart';
import 'package:melodink_client/features/library/presentation/modals/select_artists_modal.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class EditAlbumViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final AlbumRepository albumRepository;

  EditAlbumViewModel({required this.eventBus, required this.albumRepository});

  final formKey = GlobalKey<FormState>();

  bool autoValidate = false;

  bool isLoading = false;

  bool hasError = false;

  Album? originalAlbum;

  // Form

  final nameTextController = TextEditingController();

  List<Artist> artists = [];

  @override
  void dispose() {
    nameTextController.dispose();

    super.dispose();
  }

  Future<void> loadAlbum(int id) async {
    isLoading = true;
    notifyListeners();

    try {
      final album = await albumRepository.getAlbumById(id);

      originalAlbum = album;

      nameTextController.text = album.name;
      artists = album.artists;

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectArtists(BuildContext context) async {
    final album = originalAlbum;

    if (album == null) {
      return;
    }

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

  Future<void> addCustomCover(BuildContext context) async {
    final album = originalAlbum;

    if (album == null || isLoading) {
      return;
    }

    final file = await pickImageFile();

    if (file == null) {
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      final newAlbum = await albumRepository.changeAlbumCover(album.id, file);

      await ImageCacheManager.clearCache(newAlbum.getOrignalCoverUri());
      await ImageCacheManager.clearCache(
        newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.small),
      );
      await ImageCacheManager.clearCache(
        newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
      );
      await ImageCacheManager.clearCache(
        newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.high),
      );

      PaintingBinding.instance.imageCache.clearLiveImages();
      WidgetsBinding.instance.reassembleApplication();

      eventBus.fire(EditAlbumEvent(updatedAlbum: newAlbum));

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        AppNotificationManager.of(context).notify(
          context,
          title: t.notifications.somethingWentWrong.title,
          message: t.notifications.somethingWentWrong.message,
          type: AppNotificationType.danger,
        );
      }
      rethrow;
    }

    if (!context.mounted) {
      return;
    }

    AppNotificationManager.of(context).notify(
      context,
      message: t.notifications.albumCoverHaveBeenChanged.message(
        name: album.name,
      ),
    );
  }

  Future<void> removeCustomCover(BuildContext context) async {
    final album = originalAlbum;

    if (album == null || isLoading) {
      return;
    }

    if (!await appConfirm(
      context,
      title: t.confirms.title,
      content: t.confirms.removeCustomCover,
      textOK: t.confirms.confirm,
    )) {
      return;
    }

    isLoading = true;

    notifyListeners();
    try {
      final newAlbum = await albumRepository.removeAlbumCover(album.id);

      await ImageCacheManager.clearCache(newAlbum.getOrignalCoverUri());
      await ImageCacheManager.clearCache(
        newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.small),
      );
      await ImageCacheManager.clearCache(
        newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
      );
      await ImageCacheManager.clearCache(
        newAlbum.getCompressedCoverUri(TrackCompressedCoverQuality.high),
      );

      PaintingBinding.instance.imageCache.clearLiveImages();
      WidgetsBinding.instance.reassembleApplication();

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        AppNotificationManager.of(context).notify(
          context,
          title: t.notifications.somethingWentWrong.title,
          message: t.notifications.somethingWentWrong.message,
          type: AppNotificationType.danger,
        );
      }
      rethrow;
    }

    if (!context.mounted) {
      return;
    }

    AppNotificationManager.of(context).notify(
      context,
      message: t.notifications.albumCoverHaveBeenRemoved.message(
        name: album.name,
      ),
    );
  }

  Future<void> saveAlbum(BuildContext context) async {
    final album = originalAlbum;

    if (album == null || isLoading) {
      return;
    }

    if (!NetworkInfo().isServerRecheable()) {
      AppNotificationManager.of(context).notify(
        context,
        title: t.notifications.offline.title,
        message: t.notifications.offline.message,
        type: AppNotificationType.danger,
      );

      return;
    }

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
      Album newAlbum = await albumRepository.saveAlbum(
        Album(
          id: album.id,
          name: nameTextController.text,
          tracks: [],
          artists: artists,
          coverSignature: "",
        ),
      );

      newAlbum = await albumRepository.setAlbumArtists(newAlbum.id, artists);

      eventBus.fire(EditAlbumEvent(updatedAlbum: newAlbum));

      isLoading = false;
      notifyListeners();

      if (!context.mounted) {
        return;
      }

      GoRouter.of(context).pop();

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.albumHaveBeenSaved.message(
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
