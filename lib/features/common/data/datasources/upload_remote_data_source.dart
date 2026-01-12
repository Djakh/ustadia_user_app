import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/common/data/models/uploaded_file_model.dart';

class UploadRemoteDataSource {
  final Dio dio;

  UploadRemoteDataSource({required this.dio});

  Future<UploadedFileModel> uploadImage(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName)
    });
    final response = await dio.post('/uploads', data: formData);
    final data = response.data as Map<String, dynamic>;
    return UploadedFileModel.fromJson(data);
  }
}
