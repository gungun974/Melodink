import 'package:get_it/get_it.dart';
import 'package:grpc/grpc.dart';
import 'package:melodink_client/config.dart';
import 'package:melodink_client/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:melodink_client/features/tracks/domain/repositories/track_repository.dart';
import 'package:melodink_client/features/tracks/domain/usecases/get_all_tracks.dart';
import 'package:melodink_client/features/tracks/presentation/cubit/tracks_cubit.dart';

final sl = GetIt.instance;

void setup() {
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

  //! External
  sl.registerLazySingleton(
    () => ClientChannel(
      appHost,
      port: appPort,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    ),
  );
}
