import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/assignments/data/services/assignment_sections_store.dart';
import 'package:ustadia_user_app/features/assignments/presentation/bloc/assignments_bloc/assignments_bloc.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_register_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_bloc.dart';
import 'package:ustadia_user_app/features/common/data/datasources/upload_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/repositories/flashcard_repository.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/bloc/current_unit_bloc/current_unit_bloc.dart';
import 'package:ustadia_user_app/features/intro_survey/data/datasources/intro_survey_remote_data_source.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/bloc/intro_survey_bloc.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/data/repositories/audio_repository.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_bloc/learn_lessons_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_bloc/learn_units_bloc.dart';
import 'package:ustadia_user_app/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:ustadia_user_app/features/notifications/presentation/bloc/notifications_bloc/notifications_bloc.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_flashcard_sets_bloc/practice_flashcard_sets_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_sets_bloc/practice_listen_tap_sets_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_sets_bloc/practice_sentence_builder_sets_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_word_match_sets_bloc/practice_word_match_sets_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_word_match_status_bloc/practice_word_match_status_bloc.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';

import 'core/network/dio_client.dart';

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
  sl.registerFactory(() => AuthLoginBloc(
      authRemoteDataSource: sl(), authLocalDataSource: sl(), userRemoteDataSource: sl()));
  sl.registerFactory(() => AuthPasswordBloc(authRemoteDataSource: sl()));
  sl.registerFactory(() => AuthRegisterBloc(authRemoteDataSource: sl()));
  sl.registerFactory(() => AuthVerifyBloc(
      authRemoteDataSource: sl(), authLocalDataSource: sl(), userRemoteDataSource: sl()));

  // Features - Common (User)
  sl.registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerLazySingleton<ProfileStatisticsStore>(
      () => ProfileStatisticsStore(userRemoteDataSource: sl()));
  sl.registerLazySingleton<UserBloc>(() => UserBloc(userRemoteDataSource: sl()));
  sl.registerLazySingleton<UploadRemoteDataSource>(
      () => UploadRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerFactory(() => FileUploadBloc(uploadRemoteDataSource: sl()));
  sl.registerLazySingleton<FlashcardRepository>(
      () => FlashcardRepositoryImpl(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerFactory(() => FlashcardStatusBloc(flashcardRepository: sl()));
  sl.registerFactory(() => TeacherBloc(userRemoteDataSource: sl(), authLocalDataSource: sl()));

  // Features - Intro Survey
  sl.registerLazySingleton<IntroSurveyRemoteDataSource>(
      () => IntroSurveyRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerFactory(() => IntroSurveyBloc(introSurveyRemoteDataSource: sl()));

  // Features - Learn
  sl.registerLazySingleton<LearnRemoteDataSource>(
      () => LearnRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerLazySingleton(() => LearnLessonsBloc(learnRemoteDataSource: sl()));
  sl.registerLazySingleton(() => LearnUnitsBloc(learnRemoteDataSource: sl()));
  sl.registerLazySingleton(() => LearnSectionsBloc(learnRemoteDataSource: sl()));
  sl.registerFactory(
      () => SectionDetailBloc(learnRemoteDataSource: sl(), assignmentsRemoteDataSource: sl()));
  sl.registerFactory(() => QuestionAnswerBloc(
      learnRemoteDataSource: sl(),
      assignmentsRemoteDataSource: sl(),
      profileStatisticsStore: sl()));
  sl.registerLazySingleton<AudioRepository>(
      () => AudioRepositoryImpl(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerFactory(() => AudioBloc(audioRepository: sl()));

  // Features - Dashboard
  sl.registerFactory(() => CurrentUnitBloc(learnRemoteDataSource: sl()));

  // Features - Practice
  sl.registerLazySingleton<PracticeRemoteDataSource>(
      () => PracticeRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerLazySingleton(() => PracticeFlashcardSetsBloc(practiceRemoteDataSource: sl()));
  sl.registerLazySingleton(() => PracticeListenTapSetsBloc(practiceRemoteDataSource: sl()));
  sl.registerFactory(() => PracticeListenTapStatusBloc(practiceRemoteDataSource: sl()));
  sl.registerLazySingleton(() => PracticeSentenceBuilderSetsBloc(practiceRemoteDataSource: sl()));
  sl.registerFactory(() => PracticeSentenceBuilderStatusBloc(practiceRemoteDataSource: sl()));
  sl.registerLazySingleton(() => PracticeWordMatchSetsBloc(practiceRemoteDataSource: sl()));
  sl.registerFactory(() => PracticeWordMatchStatusBloc(practiceRemoteDataSource: sl()));

  // Features - Notifications
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerFactory(() => NotificationsBloc(notificationsRemoteDataSource: sl()));

  // Features - Assignments
  sl.registerLazySingleton<AssignmentsRemoteDataSource>(
      () => AssignmentsRemoteDataSource(dio: sl<AuthRemoteDataSource>().dio));
  sl.registerLazySingleton(() => AssignmentSectionsStore(remoteDataSource: sl()));
  sl.registerLazySingleton(() => AssignmentsBloc(assignmentsRemoteDataSource: sl()));
}
