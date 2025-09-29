import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/data/repository/download_playlist_repository.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/events/playlist_events.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/events/track_events.dart';
import 'package:melodink_client/features/track/domain/manager/download_manager.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class PlaylistViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final AudioController audioController;
  final DownloadManager downloadManager;
  final PlaylistRepository playlistRepository;
  final DownloadPlaylistRepository downloadPlaylistRepository;

  StreamSubscription? _editPlaylistStream;
  StreamSubscription? _editTrackStream;
  StreamSubscription? _deleteTrackStream;

  PlaylistViewModel({
    required this.eventBus,
    required this.audioController,
    required this.downloadManager,
    required this.playlistRepository,
    required this.downloadPlaylistRepository,
  }) {
    _editPlaylistStream = eventBus.on<EditPlaylistEvent>().listen((event) {
      if (event.updatedPlaylist.id != playlist?.id) {
        return;
      }

      playlist = event.updatedPlaylist;

      downloaded = playlist!.isDownloaded;

      notifyListeners();
    });

    _editTrackStream = eventBus.on<EditTrackEvent>().listen((event) {
      final playlist = this.playlist;

      if (playlist == null) {
        return;
      }
      final index = playlist.tracks.indexWhere(
        (track) => track.id == event.updatedTrack.id,
      );

      if (index < 0) {
        return;
      }

      this.playlist = playlist.copyWith(
        tracks: [
          ...playlist.tracks.sublist(0, index),
          event.updatedTrack,
          ...playlist.tracks.sublist(index + 1),
        ],
      );

      notifyListeners();
    });

    _deleteTrackStream = eventBus.on<DeleteTrackEvent>().listen((event) {
      final playlist = this.playlist;

      if (playlist == null) {
        return;
      }

      this.playlist = playlist.copyWith(
        tracks: playlist.tracks
            .where((track) => track.id != event.deletedTrack.id)
            .toList(),
      );

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _editPlaylistStream?.cancel();
    _editTrackStream?.cancel();
    _deleteTrackStream?.cancel();

    super.dispose();
  }

  bool isLoading = false;

  bool downloaded = false;

  Playlist? playlist;

  Future<void> loadPlaylist(int id) async {
    isLoading = true;
    notifyListeners();

    try {
      playlist = await playlistRepository.getPlaylistById(id);

      downloaded = playlist!.isDownloaded;

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void downloadPlaylist() async {
    final playlist = this.playlist;

    if (playlist == null || isLoading) {
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await downloadPlaylistRepository.downloadPlaylist(playlist.id);

      eventBus.fire(
        EditPlaylistEvent(
          updatedPlaylist: playlist.copyWith(isDownloaded: true),
        ),
      );

      isLoading = false;
      downloaded = true;

      notifyListeners();

      downloadManager.addTracksToDownloadTodo(playlist.tracks);
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeDownloadedPlaylist() async {
    final playlist = this.playlist;

    if (playlist == null || isLoading) {
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await downloadPlaylistRepository.freePlaylist(playlist.id);

      eventBus.fire(
        EditPlaylistEvent(
          updatedPlaylist: playlist.copyWith(isDownloaded: false),
        ),
      );

      await downloadManager.deleteOrphanTracks();

      isLoading = false;
      downloaded = false;

      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeTracksFromPlaylist(
    BuildContext context,
    Set<int> selectedIndexes,
  ) async {
    final playlist = this.playlist;

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

    isLoading = true;
    notifyListeners();

    try {
      this.playlist = await playlistRepository.setPlaylistTracks(
        playlist.id,
        playlist.tracks.indexed
            .where((entry) => !selectedIndexes.contains(entry.$1))
            .map((entry) => entry.$2)
            .toList(),
      );

      //TODO: await downloadManager.deleteOrphanTracks();

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
      message: t.notifications.playlistTrackHaveBeenRemoved.message(
        n: selectedIndexes.length,
        name: playlist.name,
      ),
    );
  }

  Future<void> deletePlaylist(BuildContext context) async {
    final playlist = this.playlist;

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

    if (!await appConfirm(
      context,
      title: t.confirms.title,
      content: t.confirms.deletePlaylist,
      textOK: t.confirms.delete,
      isDangerous: true,
    )) {
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final deletedPlaylist = await playlistRepository.deletePlaylistById(
        playlist.id,
      );

      eventBus.fire(DeletePlaylistEvent(deletedPlaylist: deletedPlaylist));

      isLoading = false;
      notifyListeners();

      if (!context.mounted) {
        return;
      }

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.playlistHaveBeenDeleted.message(
          name: playlist.name,
        ),
      );

      context.read<AppRouter>().pop();
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
    }
  }

  Future<void> playPlaylist(bool isSameSource, String? source) async {
    final playlist = this.playlist;

    if (playlist == null) {
      return;
    }

    if (!isSameSource) {
      await audioController.loadTracks(playlist.tracks, source: source);
      return;
    }

    if (audioController.playbackState.valueOrNull?.playing ?? false) {
      await audioController.pause();
      return;
    }

    await audioController.play();
  }
}
