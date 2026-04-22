import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/common/data/datasources/upload_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_state.dart';

class FileUploadBloc extends Bloc<FileUploadEvent, FileUploadState> {
  final UploadRemoteDataSource uploadRemoteDataSource;

  FileUploadBloc({required this.uploadRemoteDataSource}) : super(const FileUploadState()) {
    on<ImageUploadRequested>(handleImageUploadRequested);
  }

  Future<void> handleImageUploadRequested(
      ImageUploadRequested event, Emitter<FileUploadState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      if ((event.filePath == null || event.filePath!.isEmpty) &&
          (event.bytes == null || event.bytes!.isEmpty)) {
        emit(state.copyWith(status: Status.error, errorMessage: 'Selected file is not available.'));
        return;
      }
      final uploadedFile = await uploadRemoteDataSource.uploadImage(
        event.filePath,
        fileName: event.fileName,
        bytes: event.bytes,
      );
      emit(state.copyWith(status: Status.success, uploadedFile: uploadedFile));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
