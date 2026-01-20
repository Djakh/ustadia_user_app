abstract class FileUploadEvent {
  const FileUploadEvent();
}

class ImageUploadRequested extends FileUploadEvent {
  final String filePath;

  const ImageUploadRequested({required this.filePath});
}
