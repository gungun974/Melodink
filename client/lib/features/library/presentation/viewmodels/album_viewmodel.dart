import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/library/data/repository/download_album_repository.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/events/album_events.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/events/track_events.dart';
import 'package:melodink_client/features/track/domain/manager/download_manager.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class AlbumViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final AudioController audioController;
  final DownloadManager downloadManager;
  final AlbumRepository albumRepository;
  final DownloadAlbumRepository downloadAlbumRepository;

  StreamSubscription? _editAlbumStream;
  StreamSubscription? _editTrackStream;
  StreamSubscription? _deleteTrackStream;

  AlbumViewModel({
    required this.eventBus,
    required this.audioController,
    required this.downloadManager,
    required this.albumRepository,
    required this.downloadAlbumRepository,
  }) {
    _editAlbumStream = eventBus.on<EditAlbumEvent>().listen((event) {
      if (event.updatedAlbum.id != album?.id) {
        return;
      }

      album = event.updatedAlbum;

      downloaded = album!.isDownloaded && album!.downloadTracks;

      notifyListeners();
    });

    _editTrackStream = eventBus.on<EditTrackEvent>().listen((event) {
      final album = this.album;

      if (album == null) {
        return;
      }
      final index = album.tracks.indexWhere(
        (track) => track.id == event.updatedTrack.id,
      );

      if (index < 0) {
        return;
      }

      this.album = album.copyWith(
        tracks: [
          ...album.tracks.sublist(0, index),
          event.updatedTrack,
          ...album.tracks.sublist(index + 1),
        ],
      );

      notifyListeners();
    });

    _deleteTrackStream = eventBus.on<DeleteTrackEvent>().listen((event) {
      final album = this.album;

      if (album == null) {
        return;
      }

      this.album = album.copyWith(
        tracks: album.tracks
            .where((track) => track.id != event.deletedTrack.id)
            .toList(),
      );

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _editAlbumStream?.cancel();
    _editTrackStream?.cancel();
    _deleteTrackStream?.cancel();

    super.dispose();
  }

  bool isLoading = false;

  bool downloaded = false;

  Album? album;

  Future<void> loadAlbum(int id) async {
    isLoading = true;
    notifyListeners();

    try {
      album = await albumRepository.getAlbumById(id);

      _sortTracks();

      downloaded = album!.isDownloaded && album!.downloadTracks;

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void _sortTracks() {
    final album = this.album;

    if (album == null) {
      return;
    }

    album.tracks.sort((a, b) {
      int discCompare = a.discNumber.compareTo(b.discNumber);
      if (discCompare != 0) {
        return discCompare;
      }

      int trackCompare = a.trackNumber.compareTo(b.trackNumber);
      if (trackCompare != 0) {
        return trackCompare;
      }

      return a.title.compareTo(b.title);
    });
  }

  void downloadAlbum() async {
    final album = this.album;

    if (album == null || isLoading) {
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await downloadAlbumRepository.downloadAlbum(album.id);

      eventBus.fire(
        EditAlbumEvent(
          updatedAlbum: album.copyWith(
            isDownloaded: true,
            downloadTracks: true,
          ),
        ),
      );

      isLoading = false;
      downloaded = true;

      notifyListeners();

      downloadManager.addTracksToDownloadTodo(album.tracks);
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeDownloadedAlbum() async {
    final album = this.album;

    if (album == null || isLoading) {
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final isPartialAlbum = await downloadAlbumRepository.freeAlbum(album.id);

      eventBus.fire(
        EditAlbumEvent(
          updatedAlbum: album.copyWith(
            isDownloaded: false,
            downloadTracks: !isPartialAlbum,
          ),
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

  Future<void> deleteAlbum(BuildContext context) async {
    final album = this.album;

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

    if (!await appConfirm(
      context,
      title: t.confirms.title,
      content: t.confirms.deleteAlbum,
      textOK: t.confirms.delete,
      isDangerous: true,
    )) {
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final deletedAlbum = await albumRepository.deleteAlbumById(album.id);

      eventBus.fire(DeleteAlbumEvent(deletedAlbum: deletedAlbum));

      isLoading = false;
      notifyListeners();

      if (!context.mounted) {
        return;
      }

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.albumHaveBeenDeleted.message(name: album.name),
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

  Future<void> playAlbum(bool isSameSource, String? source) async {
    final album = this.album;

    if (album == null) {
      return;
    }

    if (!isSameSource) {
      await audioController.loadTracks(album.tracks, source: source);
      return;
    }

    if (audioController.playbackState.valueOrNull?.playing ?? false) {
      await audioController.pause();
      return;
    }

    await audioController.play();
  }
}
