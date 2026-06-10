import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_storage_service.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_model.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flashcard_status_response.dart';
import 'package:ustadia_user_app/features/common/data/repositories/flashcard_repository.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/dashboard/data/services/current_unit_store.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';
import 'package:ustadia_user_app/injection_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    EasyLocalization.logger.enableLevels = [];
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('I know it saves and advances to the next flashcard', (tester) async {
    await _registerFlashcardDependencies();
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => FlashcardSprintPage(flashcardSetModel: _set())),
    ]);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Card 1 of 2'), findsOneWidget);

    await tester.tap(find.text('I know it'));
    await tester.pumpAndSettle();

    expect(find.text('Card 2 of 2'), findsOneWidget);
  });
}

Future<void> _registerFlashcardDependencies() async {
  await sl.reset();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tutorialStorage = TutorialStorageService(prefs: prefs);
  await tutorialStorage.setTutorialEnabled(false);

  sl.registerSingleton<TutorialStorageService>(tutorialStorage);
  sl.registerFactory(() => FlashcardStatusBloc(
      flashcardRepository: _FakeFlashcardRepository(),
      profileStatisticsStore:
          ProfileStatisticsStore(userRemoteDataSource: UserRemoteDataSource(dio: Dio())),
      currentUnitStore:
          CurrentUnitStore(learnRemoteDataSource: LearnRemoteDataSource(dio: Dio()))));
}

LearnFlashcardSetModel _set() => LearnFlashcardSetModel(
      id: 'set_1',
      title: 'Vocabulary',
      description: '',
      difficulty: null,
      totalFlashcards: 2,
      revealedCount: 0,
      notRevealedCount: 0,
      flashcards: List<LearnFlashcardModel>.of(const [
        LearnFlashcardModel(id: 'card_1', front: 'hello', back: 'salom', order: 0, status: ''),
        LearnFlashcardModel(id: 'card_2', front: 'world', back: 'dunyo', order: 1, status: ''),
      ]),
    );

class _FakeFlashcardRepository implements FlashcardRepository {
  @override
  Future<FlashcardStatusResponse> updateFlashcardStatus(
          {required String flashcardId, required String status, required bool isPractice}) async =>
      FlashcardStatusResponse(back: null, status: status, isAnswered: true);
}
