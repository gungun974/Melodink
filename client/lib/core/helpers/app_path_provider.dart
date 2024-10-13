import 'dart:io';

import 'package:melodink_client/core/api/api.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<Directory> getMelodinkInstanceSupportDirectory() async {
  final applicationSupportDirectory =
      (await getApplicationSupportDirectory()).path;

  final instanceUniqueId = await AppApi().getServerUUID();

  if (instanceUniqueId == null) {
    throw Exception("No Server UUID is register");
  }

  return Directory(
    join(applicationSupportDirectory, instanceUniqueId),
  );
}

Future<Directory> getMelodinkInstanceCacheDirectory() async {
  final applicationCacheDirectory = (await getApplicationCacheDirectory()).path;

  final instanceUniqueId = await AppApi().getServerUUID();

  if (instanceUniqueId == null) {
    throw Exception("No Server UUID is register");
  }

  return Directory(
    join(applicationCacheDirectory, "melodink-cache", instanceUniqueId),
  );
}
