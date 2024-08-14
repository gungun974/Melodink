import 'package:get_it/get_it.dart';

import 'package:http/http.dart' as http;
import 'package:melodink_client/core/audio/audio_controller.dart';
import 'package:melodink_client/features/track/presentation/cubit/tracks_cubit.dart';

final sl = GetIt.instance;

Future<void> setup() async {
  //! Track

  // Cubit
  sl.registerFactory(
    () => TracksCubit(),
  );

  //! External
  sl.registerLazySingleton(() => http.Client());

  sl.registerSingleton<AudioController>(await initAudioService());
}
