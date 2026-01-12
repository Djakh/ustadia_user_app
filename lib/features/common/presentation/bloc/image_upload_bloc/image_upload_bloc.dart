import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/common/data/datasources/upload_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/image_upload_bloc/image_upload_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/image_upload_bloc/image_upload_state.dart';

class ImageUploadBloc extends Bloc<ImageUploadEvent, ImageUploadState> {
  final UploadRemoteDataSource uploadRemoteDataSource;

  ImageUploadBloc({required this.uploadRemoteDataSource}) : super(const ImageUploadState()) {
    on<ImageUploadRequested>(handleImageUploadRequested);
  }

  Future<void> handleImageUploadRequested(
      ImageUploadRequested event, Emitter<ImageUploadState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final uploadedFile = await uploadRemoteDataSource.uploadImage(event.filePath);
      emit(state.copyWith(status: Status.success, uploadedFile: uploadedFile));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
