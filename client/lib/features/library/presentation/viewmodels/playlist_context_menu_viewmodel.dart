import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/events/playlist_events.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class PlaylistContextMenuViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final AudioController audioController;
  final PlaylistRepository playlistRepository;

  PlaylistContextMenuViewModel({
    required this.eventBus,
    required this.audioController,
    required this.playlistRepository,
  });

  Playlist? playlist;

  void loadPlaylist(Playlist playlist) {
    this.playlist = playlist;
    notifyListeners();
  }

  Future<List<Track>> _fetchPlaylistTracks(BuildContext context) async {
    if (playlist == null) {
      return [];
    }
    try {
      return (await playlistRepository.getPlaylistById(playlist!.id)).tracks;
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

  void addToQueue(BuildContext context) async {
    final tracks = await _fetchPlaylistTracks(context);

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
    final tracks = await _fetchPlaylistTracks(context);

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

  void editPlaylist(BuildContext context) {
    if (playlist == null) {
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

    context.read<AppRouter>().push("/playlist/${playlist!.id}/edit");
  }

  void duplicatePlaylist(BuildContext context) async {
    final playlist = this.playlist;

    if (playlist == null) {
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
      content: t.confirms.duplicatePlaylist,
      textOK: t.confirms.confirm,
    )) {
      return;
    }

    final loadingWidget = OverlayEntry(builder: (context) => AppPageLoader());

    if (context.mounted) {
      Overlay.of(context, rootOverlay: true).insert(loadingWidget);
    }

    try {
      final newPlaylist = await playlistRepository.duplicatePlaylist(
        playlist.id,
      );

      eventBus.fire(CreatePlaylistEvent(createdPlaylist: newPlaylist));

      loadingWidget.remove();

      if (!context.mounted) {
        return;
      }

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.playlistHaveBeenDuplicated.message(
          name: playlist.name,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppNotificationManager.of(context).notify(
          context,
          title: t.notifications.somethingWentWrong.title,
          message: t.notifications.somethingWentWrong.message,
          type: AppNotificationType.danger,
        );
      }

      loadingWidget.remove();
    }
  }
}
