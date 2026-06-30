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
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
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

  testWidgets('section vocabulary loads question quiz when flashcard set is null', (tester) async {
    await _registerFlashcardDependencies(sectionResponse: _sectionQuestionResponse());
    await _pumpSectionFlashcards(tester);

    expect(find.text('The ___ rises in the east.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Flashcards are not available for this section.'), findsNothing);
  });

  testWidgets('completed section vocabulary opens its result instead of flashcards',
      (tester) async {
    await _registerFlashcardDependencies(sectionResponse: _sectionDetailResponse());
    await _pumpSectionFlashcards(tester, isCompleted: true);

    expect(find.byType(QuizResultComponent), findsOneWidget);
    expect(find.text('Card 1 of 2'), findsNothing);
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
  final dio = sectionResponse == null ? Dio() : _responseDio(sectionResponse);
  final learnRemoteDataSource = LearnRemoteDataSource(dio: dio);
  final assignmentsRemoteDataSource = AssignmentsRemoteDataSource(dio: dio);
  final mockExamRemoteDataSource = MockExamRemoteDataSource(dio: dio);
  final profileStatisticsStore =
      ProfileStatisticsStore(userRemoteDataSource: UserRemoteDataSource(dio: Dio()));
  final currentUnitStore = CurrentUnitStore(learnRemoteDataSource: learnRemoteDataSource);

  sl.registerSingleton<TutorialStorageService>(tutorialStorage);
  sl.registerSingleton<LearnRemoteDataSource>(learnRemoteDataSource);
  sl.registerFactory(() => FlashcardStatusBloc(
      flashcardRepository: _FakeFlashcardRepository(),
      profileStatisticsStore: profileStatisticsStore,
      currentUnitStore: currentUnitStore));
  sl.registerFactory(() => QuestionAnswerBloc(
      learnRemoteDataSource: learnRemoteDataSource,
      assignmentsRemoteDataSource: assignmentsRemoteDataSource,
      mockExamRemoteDataSource: mockExamRemoteDataSource,
      profileStatisticsStore: profileStatisticsStore,
      currentUnitStore: currentUnitStore));
  if (sectionResponse != null) {
    sl.registerFactory(() => SectionDetailBloc(
        learnRemoteDataSource: learnRemoteDataSource,
        assignmentsRemoteDataSource: assignmentsRemoteDataSource,
        mockExamRemoteDataSource: mockExamRemoteDataSource));
  }
}

Future<void> _pumpSectionFlashcards(WidgetTester tester, {bool isCompleted = false}) async {
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
    'flashcard_set_id': 'set_1',
    'iscompleted': isCompleted,
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

Map<String, dynamic> _sectionQuestionResponse() => {
      'id': 'section_1',
      'unit_id': 'unit_1',
      'lesson_id': 'lesson_1',
      'type': 'vocabulary',
      'title': 'Vocabulary Fill Blanks',
      'content': 'Practice vocabulary with fill-in-the-blank exercises',
      'flashcard_set_id': null,
      'flashcard_set': null,
      'questions': [
        {
          'id': 'question_1',
          'section_id': 'section_1',
          'type': 'fill-blank',
          'title': 'The ___ rises in the east.',
          'order_index': 1,
          'is_answered': false,
          'number_of_blanks': 1,
          'blank_answers': [
            {'answer': null, 'position': 1}
          ],
          'answers': null,
          'max_selections': 0,
        }
      ],
      'totalQuestions': 1,
      'isCompleted': false,
      'isLocked': false,
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
