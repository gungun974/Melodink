import 'package:get_it/get_it.dart';

import 'package:http/http.dart' as http;
import 'package:melodink_client/core/routes/cubit.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';

final sl = GetIt.instance;

Future<void> setup() async {
//! Router
  sl.registerSingleton<RouterCubit>(RouterCubit());

  //! Player

  sl.registerSingleton<AudioController>(await initAudioService());

  //! External
  sl.registerLazySingleton(() => http.Client());
}
