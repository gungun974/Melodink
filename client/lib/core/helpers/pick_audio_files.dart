import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<File?> pickAudioFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.audio,
  );

  if (result == null) {
    return null;
  }

  return File(result.files.single.path!);
}

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
