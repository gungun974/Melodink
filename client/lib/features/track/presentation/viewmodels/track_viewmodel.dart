import 'dart:async';

import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/events/track_events.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class TrackViewModel extends ChangeNotifier {
  bool isLoading = false;

  Track? track;

  final EventBus eventBus;
  final TrackRepository trackRepository;

  StreamSubscription? _editTrackStream;

  TrackViewModel({required this.eventBus, required this.trackRepository}) {
    _editTrackStream = eventBus.on<EditTrackEvent>().listen((event) {
      if (event.updatedTrack.id != track?.id) {
        return;
      }

      track = event.updatedTrack;

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _editTrackStream?.cancel();

    super.dispose();
  }

  Future<void> loadTrack(int id) async {
    isLoading = true;
    notifyListeners();

    try {
      track = await trackRepository.getTrackById(id);

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  void deleteTrack(BuildContext context) async {
    final track = this.track;

    if (track == null || isLoading) {
      return;
    }
    if (!await appConfirm(
      context,
      title: t.confirms.title,
      content: t.confirms.deleteTrack,
      textOK: t.confirms.delete,
      isDangerous: true,
    )) {
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final deletedTrack = await trackRepository.deleteTrackById(track.id);

      eventBus.fire(DeleteTrackEvent(deletedTrack: deletedTrack));

      isLoading = false;
      notifyListeners();

      if (!context.mounted) {
        return;
      }

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.trackHaveBeenDeleted.message(
          title: track.title,
        ),
      );

      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }
}
