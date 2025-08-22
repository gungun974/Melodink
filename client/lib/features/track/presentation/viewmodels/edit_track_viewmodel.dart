import 'package:flutter/material.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/pick_audio_files.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/events/track_events.dart';
import 'package:melodink_client/features/library/presentation/modals/select_albums_modal.dart';
import 'package:melodink_client/features/library/presentation/modals/select_artists_modal.dart';
import 'package:melodink_client/features/track/presentation/modals/scan_configuration_modal.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class EditTrackViewModel extends ChangeNotifier {
  final EventBus eventBus;
  final TrackRepository trackRepository;

  EditTrackViewModel({required this.eventBus, required this.trackRepository});

  final formKey = GlobalKey<FormState>();

  bool autoValidate = false;

  bool isLoading = false;

  bool hasError = false;

  Track? originalTrack;

  // Form

  final titleTextController = TextEditingController();

  List<Album> albums = [];
  List<Artist> artists = [];

  final trackNumberTextController = TextEditingController();
  final totalTracksTextController = TextEditingController();
  final discNumberTextController = TextEditingController();
  final totalDiscsTextController = TextEditingController();
  final dateTextController = TextEditingController();
  final yearTextController = TextEditingController();

  List<String> genres = [];

  final acoustIdTextController = TextEditingController();
  final musicBrainzReleaseIdTextController = TextEditingController();
  final musicBrainzTrackIdTextController = TextEditingController();
  final musicBrainzRecordingIdTextController = TextEditingController();
  final composerTextController = TextEditingController();
  final commentTextController = TextEditingController();
  final lyricsTextController = TextEditingController();

  DateTime dateAdded = DateTime(0);

  @override
  void dispose() {
    titleTextController.dispose();

    trackNumberTextController.dispose();
    totalTracksTextController.dispose();
    discNumberTextController.dispose();
    totalDiscsTextController.dispose();
    dateTextController.dispose();
    yearTextController.dispose();

    acoustIdTextController.dispose();
    musicBrainzReleaseIdTextController.dispose();
    musicBrainzTrackIdTextController.dispose();
    musicBrainzRecordingIdTextController.dispose();
    composerTextController.dispose();
    commentTextController.dispose();
    lyricsTextController.dispose();

    super.dispose();
  }

  void loadTrack(Track track) {
    originalTrack = track;

    titleTextController.text = track.title;

    albums = track.albums;
    artists = track.artists;

    trackNumberTextController.text = track.trackNumber.toString();
    totalTracksTextController.text = track.metadata.totalTracks.toString();
    discNumberTextController.text = track.discNumber.toString();
    totalDiscsTextController.text = track.metadata.totalDiscs.toString();
    dateTextController.text = track.metadata.date;
    yearTextController.text = track.metadata.year.toString();

    genres = track.metadata.genres;

    acoustIdTextController.text = track.metadata.acoustId;
    musicBrainzReleaseIdTextController.text =
        track.metadata.musicBrainzReleaseId;
    musicBrainzTrackIdTextController.text = track.metadata.musicBrainzTrackId;
    musicBrainzRecordingIdTextController.text =
        track.metadata.musicBrainzRecordingId;
    composerTextController.text = track.metadata.composer;
    commentTextController.text = track.metadata.comment;
    lyricsTextController.text = track.metadata.lyrics;

    dateAdded = track.dateAdded;

    notifyListeners();
  }

  Future<void> selectAlbums(BuildContext context) async {
    final originalTrack = this.originalTrack;

    if (originalTrack == null) {
      return;
    }

    final newAlbums = await SelectAlbumsModal.showModal(
      context,
      albums.map((album) => album.id).toList(),
    );

    if (newAlbums != null) {
      if (newAlbums.isEmpty) {
        albums.clear();
        notifyListeners();
      } else {
        albums = newAlbums;
        notifyListeners();
      }
    }
  }

  Future<void> selectArtists(BuildContext context) async {
    final originalTrack = this.originalTrack;

    if (originalTrack == null) {
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

  Future<void> scanAudioFile(BuildContext context) async {
    final originalTrack = this.originalTrack;

    if (originalTrack == null) {
      return;
    }

    final configuration = await ScanConfigurationModal.showModal(context);

    if (configuration == null) {
      return;
    }

    isLoading = true;

    notifyListeners();

    try {
      late final Track scannedTrack;

      if (configuration.advancedScan) {
        scannedTrack = await trackRepository.advancedAudioScan(
          originalTrack.id,
        );
      } else {
        scannedTrack = await trackRepository.scanAudio(originalTrack.id);
      }

      if (!configuration.onlyReplaceEmptyFields ||
          titleTextController.text.trim().isEmpty) {
        titleTextController.text = scannedTrack.title;
      }

      if (!configuration.onlyReplaceEmptyFields) {
        genres = scannedTrack.metadata.genres;
      } else {
        final newGenres = genres.toList();

        while (newGenres.length < scannedTrack.metadata.genres.length) {
          newGenres.add("");
        }

        for (final entry in scannedTrack.metadata.genres.indexed) {
          if (newGenres[entry.$1].trim().isEmpty) {
            newGenres[entry.$1] = entry.$2;
          }
        }

        genres = newGenres;
      }

      if (!configuration.onlyReplaceEmptyFields ||
          trackNumberTextController.text.trim().isEmpty) {
        trackNumberTextController.text = scannedTrack.trackNumber.toString();
      }

      if (!configuration.onlyReplaceEmptyFields ||
          totalTracksTextController.text.trim().isEmpty) {
        totalTracksTextController.text = scannedTrack.metadata.totalTracks
            .toString();
      }

      if (!configuration.onlyReplaceEmptyFields ||
          discNumberTextController.text.trim().isEmpty) {
        discNumberTextController.text = scannedTrack.discNumber.toString();
      }

      if (!configuration.onlyReplaceEmptyFields ||
          totalDiscsTextController.text.trim().isEmpty) {
        totalDiscsTextController.text = scannedTrack.metadata.totalDiscs
            .toString();
      }

      if (!configuration.onlyReplaceEmptyFields ||
          dateTextController.text.trim().isEmpty) {
        dateTextController.text = scannedTrack.metadata.date;
      }
      if (!configuration.onlyReplaceEmptyFields ||
          yearTextController.text.trim().isEmpty) {
        yearTextController.text = scannedTrack.metadata.year.toString();
      }

      if (!configuration.onlyReplaceEmptyFields ||
          acoustIdTextController.text.trim().isEmpty) {
        acoustIdTextController.text = scannedTrack.metadata.acoustId;
      }

      if (!configuration.onlyReplaceEmptyFields ||
          acoustIdTextController.text.trim().isEmpty) {
        acoustIdTextController.text =
            scannedTrack.metadata.musicBrainzReleaseId;
      }
      if (!configuration.onlyReplaceEmptyFields ||
          musicBrainzTrackIdTextController.text.trim().isEmpty) {
        musicBrainzTrackIdTextController.text =
            scannedTrack.metadata.musicBrainzTrackId;
      }

      if (!configuration.onlyReplaceEmptyFields ||
          musicBrainzRecordingIdTextController.text.trim().isEmpty) {
        musicBrainzRecordingIdTextController.text =
            scannedTrack.metadata.musicBrainzRecordingId;
      }
      if (!configuration.onlyReplaceEmptyFields ||
          composerTextController.text.trim().isEmpty) {
        composerTextController.text = scannedTrack.metadata.composer;
      }
      if (!configuration.onlyReplaceEmptyFields ||
          commentTextController.text.trim().isEmpty) {
        commentTextController.text = scannedTrack.metadata.comment;
      }
      if (!configuration.onlyReplaceEmptyFields ||
          lyricsTextController.text.trim().isEmpty) {
        lyricsTextController.text = scannedTrack.metadata.lyrics;
      }

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
      message: t.notifications.trackScanEnd.message(title: originalTrack.title),
    );
  }

  Future<void> changeAudio(BuildContext context) async {
    final originalTrack = this.originalTrack;

    if (originalTrack == null) {
      return;
    }

    final file = await pickAudioFile();

    if (file == null) {
      return;
    }

    isLoading = true;

    notifyListeners();
    try {
      final track = await trackRepository.changeTrackAudio(
        originalTrack.id,
        file,
      );

      eventBus.fire(EditTrackEvent(updatedTrack: track));

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
      message: t.notifications.trackAudioHaveBeenChanged.message(
        title: originalTrack.title,
      ),
    );

    notifyListeners();
  }

  Future<void> changeCover(BuildContext context) async {
    final originalTrack = this.originalTrack;

    if (originalTrack == null) {
      return;
    }

    final file = await pickImageFile();

    if (file == null) {
      return;
    }

    isLoading = true;
    notifyListeners();

    PaintingBinding.instance.imageCache.clearLiveImages();
    WidgetsBinding.instance.reassembleApplication();
    try {
      final track = await trackRepository.changeTrackCover(
        originalTrack.id,
        file,
      );

      await ImageCacheManager.clearCache(track.getOrignalCoverUri());
      await ImageCacheManager.clearCache(
        track.getCompressedCoverUri(TrackCompressedCoverQuality.small),
      );
      await ImageCacheManager.clearCache(
        track.getCompressedCoverUri(TrackCompressedCoverQuality.medium),
      );
      await ImageCacheManager.clearCache(
        track.getCompressedCoverUri(TrackCompressedCoverQuality.high),
      );

      PaintingBinding.instance.imageCache.clearLiveImages();
      WidgetsBinding.instance.reassembleApplication();

      eventBus.fire(EditTrackEvent(updatedTrack: track));

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
      message: t.notifications.trackCoverHaveBeenChanged.message(
        title: originalTrack.title,
      ),
    );
  }

  Future<void> save(BuildContext context) async {
    final originalTrack = this.originalTrack;

    if (originalTrack == null) {
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
      await trackRepository.setTrackAlbums(originalTrack.id, albums);
      await trackRepository.setTrackArtists(originalTrack.id, artists);

      final track = await trackRepository.saveTrack(
        originalTrack.copyWith(
          title: titleTextController.text,
          trackNumber: int.parse(trackNumberTextController.text),
          discNumber: int.parse(discNumberTextController.text),
          metadata: originalTrack.metadata.copyWith(
            totalTracks: int.parse(totalTracksTextController.text),
            totalDiscs: int.parse(totalDiscsTextController.text),
            date: dateTextController.text,
            year: int.parse(yearTextController.text),
            genres: genres,
            acoustId: acoustIdTextController.text,
            musicBrainzReleaseId: acoustIdTextController.text,
            musicBrainzTrackId: musicBrainzTrackIdTextController.text,
            musicBrainzRecordingId: musicBrainzRecordingIdTextController.text,
            composer: composerTextController.text,
            comment: commentTextController.text,
            lyrics: lyricsTextController.text,
          ),
          dateAdded: dateAdded,
        ),
      );

      eventBus.fire(EditTrackEvent(updatedTrack: track));

      isLoading = false;

      notifyListeners();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      isLoading = false;
      hasError = true;
      notifyListeners();
    }
  }

  void addGenre() {
    genres.add("");
    notifyListeners();
  }

  void removeGenre(int index) {
    genres.removeAt(index);
    notifyListeners();
  }

  void updateGenre(int index, String value) {
    genres[index] = value;
    notifyListeners();
  }
}
