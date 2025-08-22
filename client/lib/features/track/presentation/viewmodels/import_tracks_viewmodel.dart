import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/src/drop_target.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/pick_audio_files.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/events/import_events.dart';
import 'package:melodink_client/features/track/domain/events/track_events.dart';
import 'package:melodink_client/features/track/presentation/modals/edit_track_modal.dart';
import 'package:melodink_client/features/track/presentation/modals/scan_configuration_modal.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:uuid/uuid.dart';

class TrackUploadProgress extends Equatable {
  final String requestId;
  final File file;
  final Stream<double> progress;
  final bool error;

  const TrackUploadProgress({
    required this.requestId,
    required this.file,
    required this.progress,
    required this.error,
  });

  TrackUploadProgress copyWith({
    String? requestId,
    File? file,
    Stream<double>? progress,
    bool? error,
  }) {
    return TrackUploadProgress(
      requestId: requestId ?? this.requestId,
      file: file ?? this.file,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props => [requestId, file, progress, error];
}

class ImportTracksState extends Equatable {
  final List<TrackUploadProgress> uploads;
  final List<Track> uploadedTracks;

  final bool isLoading;

  const ImportTracksState({
    required this.uploads,
    required this.uploadedTracks,
    required this.isLoading,
  });

  ImportTracksState copyWith({
    List<TrackUploadProgress>? uploads,
    List<Track>? uploadedTracks,
    bool? isLoading,
  }) {
    return ImportTracksState(
      uploads: uploads ?? this.uploads,
      uploadedTracks: uploadedTracks ?? this.uploadedTracks,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [uploads, uploadedTracks, isLoading];
}

class ImportTracksViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final TrackRepository trackRepository;

  StreamSubscription? _editTrackStream;

  ImportTracksViewModel({
    required this.eventBus,
    required this.trackRepository,
  }) {
    _editTrackStream = eventBus.on<EditTrackEvent>().listen((event) {
      updateTrack(event.updatedTrack);
    });

    trackRepository.getAllPendingImportTracks().then((tracks) {
      state = state.copyWith(uploadedTracks: tracks, isLoading: false);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _editTrackStream?.cancel();

    super.dispose();
  }

  ImportTracksState state = ImportTracksState(
    uploads: [],
    uploadedTracks: [],
    isLoading: true,
  );

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    notifyListeners();

    final tracks = await trackRepository.getAllPendingImportTracks();

    state = state.copyWith(uploadedTracks: tracks, isLoading: false);
    notifyListeners();
  }

  void updateTrack(Track newTrack) {
    state = state.copyWith(
      uploadedTracks: state.uploadedTracks.map((track) {
        return track.id == newTrack.id ? newTrack : track;
      }).toList(),
    );
    notifyListeners();
  }

  Future<void> uploadAudios() async {
    final files = await pickAudioFiles();

    for (final file in files) {
      uploadAudio(file);
    }
  }

  Future<void> uploadAudiosFromDropZone(DropDoneDetails detail) async {
    for (final file in detail.files) {
      uploadAudio(File(file.path));
    }
  }

  Future<void> uploadAudio(File file) async {
    final streamController = StreamController<double>();

    const uuid = Uuid();

    final trackUploadProgress = TrackUploadProgress(
      requestId: uuid.v4(),
      file: file,
      progress: streamController.stream.asBroadcastStream(),
      error: false,
    );

    state = state.copyWith(uploads: [...state.uploads, trackUploadProgress]);
    notifyListeners();

    try {
      final newTrack = await trackRepository.uploadAudio(
        file,
        progress: streamController,
      );

      state = state.copyWith(
        uploads: state.uploads
            .where(
              (upload) => upload.requestId != trackUploadProgress.requestId,
            )
            .toList(),
        uploadedTracks: [...state.uploadedTracks, newTrack],
      );
      notifyListeners();
    } catch (_) {
      state = state.copyWith(
        uploads: state.uploads.map((upload) {
          return upload.requestId == trackUploadProgress.requestId
              ? upload.copyWith(error: true)
              : upload;
        }).toList(),
      );
      notifyListeners();
    } finally {
      streamController.close();
    }
  }

  Future<void> removeErrorUpload(
    TrackUploadProgress trackUploadProgress,
  ) async {
    state = state.copyWith(
      uploads: state.uploads
          .where(
            (upload) =>
                !(upload.requestId == trackUploadProgress.requestId &&
                    upload.error),
          )
          .toList(),
    );
    notifyListeners();
  }

  Future<void> removeTrack(Track targetTrack) async {
    state = state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final deletedTrack = await trackRepository.deleteTrackById(
        targetTrack.id,
      );

      state = state.copyWith(
        uploadedTracks: state.uploadedTracks
            .where((track) => track.id != deletedTrack.id)
            .toList(),
        isLoading: false,
      );
      notifyListeners();
    } catch (_) {
      state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> importTracks(BuildContext context) async {
    final numberOfTracks = state.uploadedTracks.length;

    state = state.copyWith(isLoading: true);
    notifyListeners();

    try {
      await trackRepository.importPendingTracks();

      await refresh();

      eventBus.fire(ImportTracksEvent());

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.trackHaveBeenImported.message(
          n: numberOfTracks,
        ),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
      notifyListeners();

      if (!context.mounted) {
        return;
      }

      AppNotificationManager.of(context).notify(
        context,
        title: t.notifications.somethingWentWrong.title,
        message: t.notifications.somethingWentWrong.message,
        type: AppNotificationType.danger,
      );
    }
  }

  void handleAdvancedScans(BuildContext context) async {
    final configuration = await ScanConfigurationModal.showModal(
      context,
      hideAdvancedScanQuestion: true,
    );

    if (configuration == null) {
      return;
    }

    final streamController = StreamController<double>();

    final stream = streamController.stream.asBroadcastStream();

    final loadingWidget = OverlayEntry(
      builder: (context) => StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          return AppPageLoader(value: snapshot.data);
        },
      ),
    );

    if (context.mounted) {
      Overlay.of(context, rootOverlay: true).insert(loadingWidget);
    }

    try {
      await _performAnAdvancedScans(
        configuration.onlyReplaceEmptyFields,
        streamController,
      );

      streamController.close();

      loadingWidget.remove();

      if (!context.mounted) {
        return;
      }

      AppNotificationManager.of(context).notify(
        context,
        message: t.notifications.trackHaveBeenScanned.message(
          n: state.uploadedTracks.length,
        ),
      );
    } catch (_) {
      streamController.close();
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

  Future _performAnAdvancedScans(
    bool onlyReplaceEmptyFields,
    StreamController<double> streamController,
  ) async {
    final tracks = state.uploadedTracks;

    streamController.add(0.01 / tracks.length);

    for (var i = 0; i < tracks.length; i++) {
      final track = await trackRepository.getTrackByIdOnline(tracks[i].id);

      final scannedTrack = await trackRepository.advancedAudioScan(track.id);

      if (!onlyReplaceEmptyFields) {
        await trackRepository.saveTrack(scannedTrack);
      } else {
        final newGenres = track.metadata.genres.toList();

        while (newGenres.length < scannedTrack.metadata.genres.length) {
          newGenres.add("");
        }

        for (final entry in scannedTrack.metadata.genres.indexed) {
          if (newGenres[entry.$1].trim().isEmpty) {
            newGenres[entry.$1] = entry.$2;
          }
        }

        await trackRepository.saveTrack(
          track.copyWith(
            title: track.title.trim().isEmpty ? scannedTrack.title : null,
            trackNumber: track.trackNumber == 0
                ? scannedTrack.trackNumber
                : null,
            discNumber: track.discNumber == 0 ? scannedTrack.discNumber : null,
            metadata: track.metadata.copyWith(
              totalTracks: track.metadata.totalTracks == 0
                  ? scannedTrack.metadata.totalTracks
                  : null,
              totalDiscs: track.metadata.totalTracks == 0
                  ? scannedTrack.metadata.totalDiscs
                  : null,
              date: track.metadata.date.trim().isEmpty
                  ? scannedTrack.metadata.date
                  : null,
              year: track.metadata.year != 0
                  ? scannedTrack.metadata.year
                  : null,
              genres: newGenres,
              lyrics: track.metadata.lyrics.trim().isEmpty
                  ? scannedTrack.metadata.lyrics
                  : null,
              comment: track.metadata.comment.trim().isEmpty
                  ? scannedTrack.metadata.comment
                  : null,
              acoustId: track.metadata.acoustId.trim().isEmpty
                  ? scannedTrack.metadata.acoustId
                  : null,
              musicBrainzReleaseId:
                  track.metadata.musicBrainzReleaseId.trim().isEmpty
                  ? scannedTrack.metadata.musicBrainzReleaseId
                  : null,
              musicBrainzTrackId:
                  track.metadata.musicBrainzTrackId.trim().isEmpty
                  ? scannedTrack.metadata.musicBrainzTrackId
                  : null,
              musicBrainzRecordingId:
                  track.metadata.musicBrainzRecordingId.trim().isEmpty
                  ? scannedTrack.metadata.musicBrainzRecordingId
                  : null,
              composer: track.metadata.composer.trim().isEmpty
                  ? scannedTrack.metadata.composer
                  : null,
            ),
          ),
        );
      }

      streamController.add((i + 1) / tracks.length);
    }

    refresh();
  }

  void showImportTrack(BuildContext context, Track track) async {
    state = state.copyWith(isLoading: true);
    notifyListeners();

    late Track detailedTrack;

    try {
      detailedTrack = await trackRepository.getTrackByIdOnline(track.id);
    } catch (_) {
      state = state.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    state = state.copyWith(isLoading: false);
    notifyListeners();

    if (!context.mounted) {
      return;
    }

    EditTrackModal.showModal(context, detailedTrack, displayDateAdded: false);
  }
}
