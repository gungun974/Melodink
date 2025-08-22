import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/helpers/pick_audio_files.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/events/playlist_events.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class EditPlaylistViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final PlaylistRepository playlistRepository;

  EditPlaylistViewModel({
    required this.eventBus,
    required this.playlistRepository,
  });

  final formKey = GlobalKey<FormState>();

  bool autoValidate = false;

  bool isLoading = false;

  bool hasError = false;

  Playlist? originalPlaylist;

  // Form

  final nameTextController = TextEditingController();
  final descriptionTextController = TextEditingController();

  final tracks = ValueNotifier<List<Track>>([]);

  @override
  void dispose() {
    nameTextController.dispose();
    descriptionTextController.dispose();

    tracks.dispose();

    super.dispose();
  }

  Future<void> loadPlaylist(int id) async {
    isLoading = true;
    notifyListeners();

    try {
      final playlist = await playlistRepository.getPlaylistById(id);

      originalPlaylist = playlist;

      nameTextController.text = playlist.name;
      descriptionTextController.text = playlist.description;

      tracks.value = playlist.tracks;

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void removeTracks(Set<int> selectedIndexes) {
    tracks.value = tracks.value.indexed
        .where((entry) => !selectedIndexes.contains(entry.$1))
        .map((entry) => entry.$2)
        .toList();
  }

  Future<void> addCustomCover(BuildContext context) async {
    final playlist = originalPlaylist;

    if (playlist == null || isLoading) {
      return;
    }

    final file = await pickImageFile();

    if (file == null) {
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      final newPlaylist = await playlistRepository.changePlaylistCover(
        playlist.id,
        file,
      );

      await ImageCacheManager.clearCache(newPlaylist.getOrignalCoverUri());
      await ImageCacheManager.clearCache(
        newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.small),
      );
      await ImageCacheManager.clearCache(
        newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
      );
      await ImageCacheManager.clearCache(
        newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.high),
      );

      PaintingBinding.instance.imageCache.clearLiveImages();
      WidgetsBinding.instance.reassembleApplication();

      eventBus.fire(EditPlaylistEvent(updatedPlaylist: newPlaylist));

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
      message: t.notifications.playlistCoverHaveBeenChanged.message(
        name: playlist.name,
      ),
    );
  }

  Future<void> removeCustomCover(BuildContext context) async {
    final playlist = originalPlaylist;

    if (playlist == null || isLoading) {
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
      final newPlaylist = await playlistRepository.removePlaylistCover(
        playlist.id,
      );

      await ImageCacheManager.clearCache(newPlaylist.getOrignalCoverUri());
      await ImageCacheManager.clearCache(
        newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.small),
      );
      await ImageCacheManager.clearCache(
        newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
      );
      await ImageCacheManager.clearCache(
        newPlaylist.getCompressedCoverUri(TrackCompressedCoverQuality.high),
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
      message: t.notifications.playlistCoverHaveBeenRemoved.message(
        name: playlist.name,
      ),
    );
  }

  Future<void> savePlaylist(BuildContext context) async {
    final playlist = originalPlaylist;

    if (playlist == null || isLoading) {
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
      Playlist newPlaylist = await playlistRepository.savePlaylist(
        Playlist(
          id: playlist.id,
          name: nameTextController.text,
          description: descriptionTextController.text,
          tracks: tracks.value,
          coverSignature: "",
        ),
      );

      newPlaylist = await playlistRepository.setPlaylistTracks(
        newPlaylist.id,
        tracks.value,
      );

      eventBus.fire(EditPlaylistEvent(updatedPlaylist: newPlaylist));

      isLoading = false;
      notifyListeners();

      if (!context.mounted) {
        return;
      }

      GoRouter.of(context).pop();

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.playlistHaveBeenSaved.message(
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
