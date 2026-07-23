class UploadedFileModel {
  final String id;
  final String filename;
  final String path;
  final String mimetype;
  final String url;

  const UploadedFileModel(
      {required this.id,
      required this.filename,
      required this.path,
      required this.mimetype,
      required this.url});

  factory UploadedFileModel.fromJson(Map<String, dynamic> json) => UploadedFileModel(
      id: json['id']?.toString() ?? '',
      filename: json['filename']?.toString() ?? json['originalName']?.toString() ?? '',
      path: json['path']?.toString() ?? json['file_path']?.toString() ?? '',
      mimetype: json['mimetype']?.toString() ?? json['mimeType']?.toString() ?? '',
      url: json['url']?.toString() ??
          json['file_url']?.toString() ??
          json['fileUrl']?.toString() ??
          '');
}
