import 'package:flutter/widgets.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/viewmodels/dynamic_background_viewmodel.dart';
import 'package:melodink_client/features/auth/data/repository/auth_repository.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/server_setup_viewmodel.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/data/repository/download_album_repository.dart';
import 'package:melodink_client/features/library/data/repository/download_playlist_repository.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/albums_viewmodel.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/artists_viewmodel.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/playlits_viewmodel.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/sync/data/repository/sync_repository.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/manager/download_manager.dart';
import 'package:melodink_client/features/track/presentation/viewmodels/tracks_viewmodel.dart';
import 'package:melodink_client/features/tracker/data/repository/played_track_repository.dart';
import 'package:melodink_client/features/tracker/domain/manager/player_tracker_manager.dart';
import 'package:provider/provider.dart';

class MainProviderScope extends StatelessWidget {
  const MainProviderScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //! Core
        Provider(create: (context) => EventBus()),
        ChangeNotifierProvider(create: (context) => NetworkInfo()),
        ChangeNotifierProvider(create: (context) => AppRouter()),

        //! Repositories
        Provider(create: (context) => AuthRepository()),
        Provider(create: (context) => PlayedTrackRepository()),
        Provider(
          create: (context) => SyncRepository(networkInfo: context.read()),
        ),
        Provider(
          create: (context) => AlbumRepository(
            playedTrackRepository: context.read(),
            syncRepository: context.read(),
            networkInfo: context.read(),
          ),
        ),
        Provider(
          create: (context) => ArtistRepository(
            syncRepository: context.read(),
            networkInfo: context.read(),
          ),
        ),
        Provider(
          create: (context) => PlaylistRepository(
            playedTrackRepository: context.read(),
            syncRepository: context.read(),
            networkInfo: context.read(),
          ),
        ),
        Provider(
          create: (context) => TrackRepository(
            playedTrackRepository: context.read(),
            syncRepository: context.read(),
            networkInfo: context.read(),
          ),
        ),
        Provider(create: (context) => DownloadTrackRepository()),
        Provider(
          create: (context) =>
              DownloadAlbumRepository(albumRepository: context.read()),
        ),
        Provider(
          create: (context) => DownloadPlaylistRepository(
            playlistRepository: context.read(),
            downloadAlbumRepository: context.read(),
          ),
        ),

        //! Managers / Services
        Provider(
          create: (context) =>
              PlayerTrackerManager(playedTrackRepository: context.read()),
        ),
        Provider(
          create: (context) => AudioController.setupAudioController(
            eventBus: context.read(),
            downloadTrackRepository: context.read(),
            playerTrackerManager: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DownloadManager(
            eventBus: context.read(),
            audioController: context.read(),
            albumRepository: context.read(),
            downloadTrackRepository: context.read(),
            downloadPlaylistRepository: context.read(),
            downloadAlbumRepository: context.read(),
          ),
        ),

        //! ViewModels
        ChangeNotifierProvider(
          create: (context) =>
              SettingsViewModel(audioController: context.read())
                ..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (context) => DynamicBackgroundViewModel(
            audioController: context.read(),
            downloadTrackRepository: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ServerSetupViewModel(authRepository: context.read()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            audioController: context.read(),
            authRepository: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TracksViewModel(
            eventBus: context.read(),
            audioController: context.read(),
            trackRepository: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PlaylistsViewModel(
            eventBus: context.read(),
            playlistRepository: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AlbumsViewModel(
            eventBus: context.read(),
            albumRepository: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ArtistsViewModel(
            eventBus: context.read(),
            artistRepository: context.read(),
          ),
        ),
      ],
      child: child,
    );
  }
}
