import 'dart:io';

import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/auth/data/repository/auth_repository.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<Directory> getMelodinkInstanceSupportDirectory() async {
  final applicationSupportDirectory =
      (await getApplicationSupportDirectory()).path;

  final instanceUniqueId = await AppApi().getServerUUID();

  if (instanceUniqueId == null) {
    throw Exception("No Server UUID is register");
  }

  final user = await AuthRepository.getCachedUser();

  if (user == null) {
    throw Exception("No user is register");
  }

  return Directory(
    join(applicationSupportDirectory, instanceUniqueId, "${user.id}"),
  );
}

Future<Directory> getMelodinkInstanceCacheDirectory() async {
  final applicationCacheDirectory = (await getApplicationCacheDirectory()).path;

  final instanceUniqueId = await AppApi().getServerUUID();

  if (instanceUniqueId == null) {
    throw Exception("No Server UUID is register");
  }

  final user = await AuthRepository.getCachedUser();

  if (user == null) {
    throw Exception("No user is register");
  }

  return Directory(
    join(applicationCacheDirectory, "melodink-cache", instanceUniqueId,
        "${user.id}"),
  );
}
