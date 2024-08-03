import 'package:get_it/get_it.dart';

import 'package:http/http.dart' as http;

final sl = GetIt.instance;

Future<void> setup() async {
  //! External
  sl.registerLazySingleton(() => http.Client());
}
