import 'package:ustadia_user_app/features/common/data/models/uploaded_file_model.dart';

/// A teacher-authored clickable area over a section image.
class SectionLinkPositionModel {
  final String id;
  final double x;
  final double y;
  final double? width;
  final double? height;
  final String? link;
  final String? fileId;
  final UploadedFileModel? file;

  const SectionLinkPositionModel({
    required this.id,
    required this.x,
    required this.y,
    this.width,
    this.height,
    this.link,
    this.fileId,
    this.file,
  });

  String get targetUrl => (link?.trim().isNotEmpty == true ? link!.trim() : file?.url.trim() ?? '');

  factory SectionLinkPositionModel.fromJson(Map<String, dynamic> json) {
    final fileValue = json['file'] ?? json['upload'];
    return SectionLinkPositionModel(
      id: json['id']?.toString() ?? '',
      x: _double(json['x']),
      y: _double(json['y']),
      width: _doubleOrNull(json['width']),
      height: _doubleOrNull(json['height']),
      link: json['link']?.toString(),
      fileId: json['file_id']?.toString() ?? json['fileId']?.toString(),
      file: fileValue is Map
          ? UploadedFileModel.fromJson(Map<String, dynamic>.from(fileValue))
          : null,
    );
  }
}

double _double(dynamic value) => _doubleOrNull(value) ?? 0;

double? _doubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
