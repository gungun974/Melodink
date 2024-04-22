import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/core/network/grpc_client.dart'
    if (dart.library.html) 'package:melodink_client/core/network/grpc_web_client.dart';
import 'package:melodink_client/features/player/data/repositories/played_track_repository_impl.dart';
import 'package:melodink_client/features/player/domain/repositories/played_track_repository.dart';
import 'package:melodink_client/features/player/domain/usecases/register_played_track.dart';
import 'package:melodink_client/features/player/presentation/cubit/player_cubit.dart';
import 'package:melodink_client/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:melodink_client/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:melodink_client/features/playlist/presentation/cubit/playlist_manager_cubit.dart';
import 'package:melodink_client/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';
import 'package:melodink_client/features/tracks/domain/usecases/get_all_tracks.dart';
import 'package:melodink_client/features/tracks/presentation/cubit/tracks_cubit.dart';

final sl = GetIt.instance;

Future<void> setup() async {
  //! Track

  // Cubit
  sl.registerFactory(
    () => TracksCubit(
      getAllTracks: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllTracks(sl()));

  // Repository
  sl.registerLazySingleton<TrackRepository>(
    () => TrackRepositoryImpl(grpcClient: sl()),
  );

  //! Player

  // Cubit
  sl.registerFactory(
    () => PlayerCubit(
      registerPlayedTrack: sl(),
      audioHandler: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => RegisterPlayedTrack(sl()));

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

  // Repository
  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(grpcClient: sl()),
  );

  //! External
  sl.registerLazySingleton<ClientChannelBase>(
    createGrpcClient,
  );

  sl.registerSingleton<AudioHandler>(await initAudioService());
}
