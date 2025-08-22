import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<File?> pickAudioFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: [
      "mp3",
      "mp4",
      "m4a",
      "ogg",
      "oga",
      "aac",
      "wav",
      "flac",
    ],
  );

  if (result == null) {
    return null;
  }

  return File(result.files.single.path!);
}

Future<File?> pickImageFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: [
      "jpeg",
      "jpg",
      "png",
      "webp",
      "gif",
      "avif",
      "tiff",
      "tif",
      "svg",
    ],
  );

  if (result == null) {
    return null;
  }

  return File(result.files.single.path!);
}

Future<List<File>> pickAudioFiles() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: [
      "mp3",
      "mp4",
      "m4a",
      "ogg",
      "oga",
      "aac",
      "wav",
      "flac",
    ],
  );

  if (result == null) {
    return [];
  }

  return result.paths.map((path) => File(path!)).toList();
}
