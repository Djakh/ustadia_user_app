import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/models/uploaded_file_model.dart';

class ImageUploadState {
  final Status status;
  final UploadedFileModel? uploadedFile;
  final String? errorMessage;

  const ImageUploadState({this.status = Status.initial, this.uploadedFile, this.errorMessage});

  bool get isLoading => status == Status.loading;

  ImageUploadState copyWith(
          {Status? status, UploadedFileModel? uploadedFile, String? errorMessage}) =>
      ImageUploadState(
          status: status ?? this.status,
          uploadedFile: uploadedFile ?? this.uploadedFile,
          errorMessage: errorMessage);
}
