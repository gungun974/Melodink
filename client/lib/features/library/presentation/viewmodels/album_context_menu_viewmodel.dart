import 'package:flutter/material.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/presentation/modals/create_playlist_modal.dart';
import 'package:melodink_client/features/library/presentation/modals/edit_album_modal.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/playlists_context_menu_viewmodel.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class AlbumContextMenuViewModel extends ChangeNotifier {
  final AudioController audioController;
  final AlbumRepository albumRepository;

  final PlaylistsContextMenuViewModel playlistsContextMenuViewModel;

  AlbumContextMenuViewModel({
    required this.audioController,
    required this.albumRepository,
    required this.playlistsContextMenuViewModel,
  });

  Album? album;

  void loadAlbum(Album album) {
    this.album = album;
    notifyListeners();
  }

  Future<List<Track>> _fetchAlbumTracks(BuildContext context) async {
    if (album == null) {
      return [];
    }
    try {
      return (await albumRepository.getAlbumById(album!.id)).tracks;
    } catch (_) {
      if (!context.mounted) {
        return [];
      }

      AppNotificationManager.of(context).notify(
        context,
        title: t.notifications.somethingWentWrong.title,
        message: t.notifications.somethingWentWrong.message,
        type: AppNotificationType.danger,
      );
      rethrow;
    }
  }

  void newPlaylist(BuildContext context) async {
    final tracks = await _fetchAlbumTracks(context);

    if (!context.mounted) {
      return;
    }

    CreatePlaylistModal.showModal(
      context,
      tracks: tracks,
      pushRouteToNewPlaylist: true,
    );
  }

  void addToPlaylist(BuildContext context, Playlist playlist) async {
    if (!NetworkInfo().isServerRecheable()) {
      AppNotificationManager.of(context).notify(
        context,
        title: t.notifications.offline.title,
        message: t.notifications.offline.message,
        type: AppNotificationType.danger,
      );
      return;
    }

    final tracks = await _fetchAlbumTracks(context);

    try {
      await playlistsContextMenuViewModel.addTracks(playlist, tracks);
    } catch (_) {
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
      message: t.notifications.playlistTrackHaveBeenAdded.message(
        n: tracks.length,
        name: playlist.name,
      ),
    );
  }

  void addToQueue(BuildContext context) async {
    final tracks = await _fetchAlbumTracks(context);

    audioController.addTracksToQueue(tracks);

    if (!context.mounted) {
      return;
    }

    AppNotificationManager.of(context).notify(
      context,
      message: t.notifications.haveBeenAddedToQueue.message(n: tracks.length),
    );
  }

  void addToQueueRandomly(BuildContext context) async {
    final tracks = await _fetchAlbumTracks(context);

    tracks.shuffle();

    audioController.addTracksToQueue(tracks);

    if (!context.mounted) {
      return;
    }

    AppNotificationManager.of(context).notify(
      context,
      message: t.notifications.haveBeenAddedToQueue.message(n: tracks.length),
    );
  }

  void editAlbum(BuildContext context) {
    if (album == null) {
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

    EditAlbumModal.showModal(context, album!);
  }
}
