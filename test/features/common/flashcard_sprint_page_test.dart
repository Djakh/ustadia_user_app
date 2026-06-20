import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_storage_service.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_model.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flashcard_status_response.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/repositories/flashcard_repository.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/dashboard/data/services/current_unit_store.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
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

  test('section summary parses new lowercase progress fields', () {
    final section = SectionModel.fromJson({
      'id': 'section_1',
      'type': 'vocabulary',
      'totalquestions': 4,
      'answeredquestions': 2,
      'iscompleted': true,
      'islocked': false
    });

    expect(section.totalQuestions, 4);
    expect(section.answeredQuestions, 2);
    expect(section.progressState, SectionProgressState.completed);
    expect(section.isLocked, isFalse);
  });

  testWidgets('section vocabulary loads flashcards from section detail', (tester) async {
    await _registerFlashcardDependencies(sectionResponse: _sectionDetailResponse());
    await _pumpSectionFlashcards(tester);

    expect(find.text('Card 1 of 2'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('section vocabulary closes when detailed flashcards are missing', (tester) async {
    await _registerFlashcardDependencies(sectionResponse: _sectionDetailResponse(hasSet: false));
    await _pumpSectionFlashcards(tester);

    expect(find.text('Section list'), findsOneWidget);
    expect(find.text('Flashcards are not available for this section.'), findsOneWidget);
  });
}

Future<void> _registerFlashcardDependencies({Map<String, dynamic>? sectionResponse}) async {
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
  if (sectionResponse != null) {
    final dio = _responseDio(sectionResponse);
    sl.registerFactory(() => SectionDetailBloc(
        learnRemoteDataSource: LearnRemoteDataSource(dio: dio),
        assignmentsRemoteDataSource: AssignmentsRemoteDataSource(dio: dio),
        mockExamRemoteDataSource: MockExamRemoteDataSource(dio: dio)));
  }
}

Future<void> _pumpSectionFlashcards(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final section = SectionModel.fromJson({
    'id': 'section_1',
    'unit_id': 'unit_1',
    'lesson_id': 'lesson_1',
    'type': 'vocabulary',
    'title': 'Vocabulary',
    'flashcard_set_id': 'set_1'
  });
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
                body: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Section list'),
              ElevatedButton(
                  onPressed: () => context.push('/flashcards'), child: const Text('Open'))
            ])))),
    GoRoute(
        path: '/flashcards',
        builder: (_, __) => FlashcardSprintPage(
            flashcardSetModel: const LearnFlashcardSetModel.empty(), sectionModel: section))
  ]);

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Dio _responseDio(Map<String, dynamic> response) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    handler.resolve(Response<Map<String, dynamic>>(requestOptions: options, data: response));
  }));
  return dio;
}

Map<String, dynamic> _sectionDetailResponse({bool hasSet = true}) => {
      'id': 'section_1',
      'unit_id': 'unit_1',
      'lesson_id': 'lesson_1',
      'type': 'vocabulary',
      'title': 'Vocabulary',
      'flashcard_set_id': 'set_1',
      if (hasSet)
        'flashcard_set': {
          'id': 'set_1',
          'title': 'Vocabulary',
          'description': '',
          'flashcards': [
            {'id': 'card_1', 'front': 'hello', 'back': 'salom', 'order': 0, 'status': ''},
            {'id': 'card_2', 'front': 'world', 'back': 'dunyo', 'order': 1, 'status': ''}
          ]
        }
    };

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
