import 'dart:typed_data';

abstract class FileUploadEvent {
  const FileUploadEvent();
}

class ImageUploadRequested extends FileUploadEvent {
  final String? filePath;
  final String? fileName;
  final Uint8List? bytes;

  const ImageUploadRequested({this.filePath, this.fileName, this.bytes});
}
