abstract class ImageUploadEvent {
  const ImageUploadEvent();
}

class ImageUploadRequested extends ImageUploadEvent {
  final String filePath;

  const ImageUploadRequested({required this.filePath});
}
