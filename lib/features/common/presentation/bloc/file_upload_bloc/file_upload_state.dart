import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/models/uploaded_file_model.dart';

class FileUploadState {
  final Status status;
  final UploadedFileModel? uploadedFile;
  final String? errorMessage;

  const FileUploadState({this.status = Status.initial, this.uploadedFile, this.errorMessage});

  bool get isLoading => status == Status.loading;

  FileUploadState copyWith(
          {Status? status, UploadedFileModel? uploadedFile, String? errorMessage}) =>
      FileUploadState(
          status: status ?? this.status,
          uploadedFile: uploadedFile ?? this.uploadedFile,
          errorMessage: errorMessage);
}
