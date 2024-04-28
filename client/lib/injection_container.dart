import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';

import 'package:http/http.dart' as http;

import 'package:melodink_client/features/player/data/repositories/played_track_repository_impl.dart';
import 'package:melodink_client/features/player/domain/repositories/played_track_repository.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_shuffler.dart';
import 'package:melodink_client/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:melodink_client/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:melodink_client/features/playlist/presentation/cubit/album_page_cubit.dart';
import 'package:melodink_client/features/playlist/presentation/cubit/playlist_manager_cubit.dart';
import 'package:melodink_client/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';
import 'package:melodink_client/features/tracks/presentation/cubit/tracks_cubit.dart';

final sl = GetIt.instance;

Future<void> setup() async {
  //! Track

  // Cubit
  sl.registerFactory(
    () => TracksCubit(
      trackRepository: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<TrackRepository>(
    () => TrackRepositoryImpl(client: sl()),
  );

  //! Player

  // Cubit
  sl.registerLazySingleton(
    () => PlayerCubit(
      playedTrackRepository: sl(),
      audioHandler: sl(),
      shuffler: sl(),
    ),
  );

  sl.registerLazySingleton<TrackShuffler>(
    () => NormalTrackShuffler(),
  );

  // Repository
  sl.registerLazySingleton<PlayedTrackRepository>(
    () => PlayedTrackRepositoryImpl(),
  );

  //! Playlist

  // Cubit
  sl.registerFactory(
    () => PlaylistManagerCubit(
      playerRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => AlbumPageCubit(
      playlistRepository: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(client: sl()),
  );

  //! External
  sl.registerLazySingleton(() => http.Client());

  sl.registerSingleton<AudioHandler>(await initAudioService());
}
