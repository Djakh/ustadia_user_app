import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/common/data/models/uploaded_file_model.dart';

class UploadRemoteDataSource {
  final Dio dio;

  UploadRemoteDataSource({required this.dio});

  Future<UploadedFileModel> uploadImage(String? filePath,
      {String? fileName, Uint8List? bytes}) async {
    final resolvedFileName = fileName ?? filePath?.split('/').last ?? 'upload';
    final multipartFile = filePath != null && filePath.isNotEmpty
        ? await MultipartFile.fromFile(filePath, filename: resolvedFileName)
        : MultipartFile.fromBytes(bytes ?? Uint8List(0), filename: resolvedFileName);
    final formData = FormData.fromMap({
      'file': multipartFile,
    });
    final response = await dio.post('/uploads', data: formData);
    final data = response.data as Map<String, dynamic>;
    return UploadedFileModel.fromJson(data);
  }
}
