import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_storage_service.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/data/models/monkey_type_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/monkey_type/monkey_type_session_page.dart';
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

  testWidgets('large text starts from the beginning when loaded and changed', (tester) async {
    final texts = [
      _text(id: 'text_1', orderIndex: 0),
      _text(id: 'text_2', orderIndex: 1),
    ];
    await _registerMonkeyTypeDependencies(texts);

    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => MonkeyTypeSessionPage(practice: _practice())),
    ]);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final targetScrollView =
        tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(targetScrollView.controller?.offset, 0);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(targetScrollView.controller!.offset, greaterThan(0));

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(targetScrollView.controller?.offset, 0);
  });

  testWidgets('submit button becomes repeat after submitting', (tester) async {
    await _registerMonkeyTypeDependencies([_text(id: 'text_1', orderIndex: 0)]);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => MonkeyTypeSessionPage(practice: _practice())),
    ]);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Previous'), findsNothing);
    expect(find.text('Next'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Large text');
    await tester.pump();
    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Repeat'), findsOneWidget);
    expect(find.text('Next text'), findsNothing);

    await tester.tap(find.text('Repeat'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, '');
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('practice link opens copy and browser actions', (tester) async {
    await _registerMonkeyTypeDependencies([_text(id: 'text_1', orderIndex: 0)]);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => MonkeyTypeSessionPage(practice: _practice())),
    ]);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practice link'));
    await tester.pumpAndSettle();

    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Open in browser'), findsOneWidget);
  });
}

Future<void> _registerMonkeyTypeDependencies(List<MonkeyTypeTextModel> texts) async {
  await sl.reset();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tutorialStorage = TutorialStorageService(prefs: prefs);
  await tutorialStorage.setTutorialEnabled(false);
  final practiceRemoteDataSource = _FakePracticeRemoteDataSource(texts);

  sl.registerSingleton<TutorialStorageService>(tutorialStorage);
  sl.registerFactory(() => MonkeyTypeSessionBloc(
      practiceRemoteDataSource: practiceRemoteDataSource,
      profileStatisticsStore: _FakeProfileStatisticsStore()));
}

MonkeyTypePracticeModel _practice() => const MonkeyTypePracticeModel(
      id: 'practice_1',
      title: 'Monkey Type',
      description: 'Typing practice',
      isPublic: true,
      teacherId: '',
      createdAt: null,
      updatedAt: null,
    );

MonkeyTypeTextModel _text({required String id, required int orderIndex}) => MonkeyTypeTextModel(
      id: id,
      practiceId: 'practice_1',
      text: List.filled(60, 'Large text for typing practice.').join(' '),
      orderIndex: orderIndex,
      createdAt: null,
    );

class _FakePracticeRemoteDataSource extends PracticeRemoteDataSource {
  final List<MonkeyTypeTextModel> texts;

  _FakePracticeRemoteDataSource(this.texts) : super(dio: Dio());

  @override
  Future<MonkeyTypePracticeModel> fetchMonkeyTypePractice(String practiceId) async =>
      MonkeyTypePracticeModel(
        id: practiceId,
        title: 'Monkey Type detail',
        description: 'Typing practice detail',
        isPublic: true,
        teacherId: '',
        createdAt: null,
        updatedAt: null,
        monkeyTypeUrl: 'https://students.ustadia.com/monkey-type/$practiceId',
        texts: texts,
      );

  @override
  Future<List<MonkeyTypeTextModel>> fetchMonkeyTypeTexts(String practiceId) async => texts;

  @override
  Future<MonkeyTypeAnswerModel> submitMonkeyTypeAnswer({
    required String practiceId,
    required String text,
    required double wpm,
    required double accuracy,
    required int correctChars,
    required int totalChars,
    required int timeTakenSeconds,
  }) async =>
      MonkeyTypeAnswerModel(
        id: 'answer_1',
        practiceId: practiceId,
        studentId: 'student_1',
        text: text,
        wpm: wpm,
        accuracy: accuracy,
        correctChars: correctChars,
        totalChars: totalChars,
        timeTakenSeconds: timeTakenSeconds,
        createdAt: null,
      );
}

class _FakeProfileStatisticsStore extends ProfileStatisticsStore {
  _FakeProfileStatisticsStore() : super(userRemoteDataSource: UserRemoteDataSource(dio: Dio()));

  @override
  Future<void> refresh() async {}
}
