import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_register_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_bloc.dart';
import 'package:ustadia_user_app/features/common/data/datasources/upload_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/image_upload_bloc/image_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/intro_survey/data/datasources/intro_survey_remote_data_source.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/bloc/intro_survey_bloc.dart';
import 'package:ustadia_user_app/features/posts/data/datasources/post_remote_data_source.dart';
import 'package:ustadia_user_app/features/posts/data/repositories/post_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'features/posts/domain/repositories/post_repository.dart';
import 'features/posts/domain/usecases/fetch_posts.dart';
import 'features/posts/presentation/bloc/post_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSource(prefs: sl()));
  sl.registerLazySingleton<Dio>(
      () => DioClient.create(accessTokenGetter: () => sl<AuthLocalDataSource>().getAccessToken()));

  // Features - Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(
      dio: DioClient.create(
          baseUrl: 'https://backend.ustadia.findecor.io',
          accessTokenGetter: () => sl<AuthLocalDataSource>().getAccessToken())));
  sl.registerFactory(
      () => AuthLoginBloc(authRemoteDataSource: sl(), authLocalDataSource: sl()));
  sl.registerFactory(() => AuthPasswordBloc(authRemoteDataSource: sl()));
  sl.registerFactory(() => AuthRegisterBloc(authRemoteDataSource: sl()));
  sl.registerFactory(
      () => AuthVerifyBloc(authRemoteDataSource: sl(), authLocalDataSource: sl()));

  // Features - Common (User)
  sl.registerLazySingleton<UserRemoteDataSource>(() =>
      UserRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerLazySingleton<UserBloc>(() => UserBloc(userRemoteDataSource: sl()));
  sl.registerLazySingleton<UploadRemoteDataSource>(
      () => UploadRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerFactory(() => ImageUploadBloc(uploadRemoteDataSource: sl()));

  // Features - Intro Survey
  sl.registerLazySingleton<IntroSurveyRemoteDataSource>(() =>
      IntroSurveyRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerFactory(() => IntroSurveyBloc(introSurveyRemoteDataSource: sl()));

  // Features - Posts
  sl.registerLazySingleton<PostRemoteDataSource>(
    () => PostRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => FetchPosts(sl()));
  sl.registerFactory(() => PostBloc(fetchPosts: sl()));
}
