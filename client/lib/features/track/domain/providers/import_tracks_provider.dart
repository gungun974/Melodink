import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/minimal_track.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/providers/edit_track_provider.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'import_tracks_provider.g.dart';

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
  List<Object> get props => [
        requestId,
        file,
        progress,
        error,
      ];
}

class ImportTracksState extends Equatable {
  final List<TrackUploadProgress> uploads;
  final List<MinimalTrack> uploadedTracks;

  final bool isLoading;

  const ImportTracksState({
    required this.uploads,
    required this.uploadedTracks,
    required this.isLoading,
  });

  ImportTracksState copyWith({
    List<TrackUploadProgress>? uploads,
    List<MinimalTrack>? uploadedTracks,
    bool? isLoading,
  }) {
    return ImportTracksState(
      uploads: uploads ?? this.uploads,
      uploadedTracks: uploadedTracks ?? this.uploadedTracks,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [
        uploads,
        uploadedTracks,
        isLoading,
      ];
}

@riverpod
class ImportTracks extends _$ImportTracks {
  late TrackRepository _trackRepository;

  @override
  ImportTracksState build() {
    _trackRepository = ref.watch(trackRepositoryProvider);

    ref.listen(trackEditStreamProvider, (_, rawNewTrack) async {
      final newTrack = rawNewTrack.valueOrNull;

      if (newTrack == null) {
        return;
      }

      await updateTrack(newTrack);
    });

    _trackRepository.getAllPendingImportTracks().then((tracks) {
      state = state.copyWith(
        uploadedTracks: tracks,
        isLoading: false,
      );
    });

    return const ImportTracksState(
      uploads: [],
      uploadedTracks: [],
      isLoading: true,
    );
  }

  refresh() async {
    state = state.copyWith(
      isLoading: true,
    );

    final tracks = await _trackRepository.getAllPendingImportTracks();

    state = state.copyWith(
      uploadedTracks: tracks,
      isLoading: false,
    );
  }

  updateTrack(Track newTrack) {
    state = state.copyWith(
      uploadedTracks: state.uploadedTracks.map(
        (track) {
          return track.id == newTrack.id ? newTrack.toMinimalTrack() : track;
        },
      ).toList(),
    );
  }

  uploadAudios(List<File> files) async {
    for (final file in files) {
      uploadAudio(file);
    }
  }

  uploadAudio(File file) async {
    final streamController = StreamController<double>();

    const uuid = Uuid();

    final trackUploadProgress = TrackUploadProgress(
      requestId: uuid.v4(),
      file: file,
      progress: streamController.stream.asBroadcastStream(),
      error: false,
    );

    state = state.copyWith(uploads: [
      ...state.uploads,
      trackUploadProgress,
    ]);

    try {
      final newTrack = await _trackRepository.uploadAudio(
        file,
        progress: streamController,
      );

      state = state.copyWith(
        uploads: state.uploads
            .where(
              (upload) => upload.requestId != trackUploadProgress.requestId,
            )
            .toList(),
        uploadedTracks: [
          ...state.uploadedTracks,
          newTrack.toMinimalTrack(),
        ],
      );
    } catch (_) {
      state = state.copyWith(
        uploads: state.uploads.map(
          (upload) {
            return upload.requestId == trackUploadProgress.requestId
                ? upload.copyWith(error: true)
                : upload;
          },
        ).toList(),
      );
    } finally {
      streamController.close();
    }
  }

  removeErrorUpload(TrackUploadProgress trackUploadProgress) async {
    state = state.copyWith(
      uploads: state.uploads
          .where(
            (upload) => !(upload.requestId == trackUploadProgress.requestId &&
                upload.error),
          )
          .toList(),
    );
  }

  removeTrack(MinimalTrack targetTrack) async {
    state = state.copyWith(
      isLoading: true,
    );

    try {
      final deletedTrack =
          await _trackRepository.deleteTrackById(targetTrack.id);

      state = state.copyWith(
        uploadedTracks: state.uploadedTracks
            .where(
              (track) => track.id != deletedTrack.id,
            )
            .toList(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
      );
    }
  }

  Future<bool> imports() async {
    state = state.copyWith(
      isLoading: true,
    );

    try {
      await _trackRepository.importPendingTracks();

      await refresh();

      ref.invalidate(allTracksProvider);

      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
      );

      return false;
    }
  }
}
