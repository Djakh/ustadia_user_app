import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:ustadia_user_app/features/posts/data/datasources/post_remote_data_source.dart';
import 'package:ustadia_user_app/features/posts/data/repositories/post_repository_impl.dart';

import 'core/network/dio_client.dart';
import 'features/posts/domain/repositories/post_repository.dart';
import 'features/posts/domain/usecases/fetch_posts.dart';
import 'features/posts/presentation/bloc/post_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<Dio>(() => DioClient.create());

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
