import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<List<File>> pickAudioFiles() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.audio,
  );

  if (result == null) {
    return [];
  }

  return result.paths
      .map(
        (path) => File(path!),
      )
      .toList();
}
