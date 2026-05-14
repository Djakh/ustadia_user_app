import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/app.dart';
import 'package:ustadia_user_app/core/widgets/app_restart.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_attempt_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const accessToken = String.fromEnvironment('MOCK_EXAM_ACCESS_TOKEN');

  testWidgets('visibly completes first available mock exam from UI', (tester) async {
    if (accessToken.isEmpty) {
      markTestSkipped(
          'Pass --dart-define=MOCK_EXAM_ACCESS_TOKEN=token to run this visible UI test.');
      return;
    }

    final dataSource = MockExamRemoteDataSource(dio: liveDio(accessToken));
    final exam = await firstAvailableMockExam(dataSource);
    expect(exam, isNotNull, reason: 'No available unfinished mock exam was found.');

    await launchApp(tester, accessToken);
    appRouter.go(mockExamRoute);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final examCardFinder = find.byKey(ValueKey('mock_exam_card_${exam!.id}'));
    await pumpUntilFound(tester, examCardFinder);
    await tester.ensureVisible(examCardFinder);
    await tester.tap(examCardFinder);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var attempt = await dataSource.startMockExamAttempt(mockExamId: exam.id);
    if (attempt.isFinished) return;
    final completedSectionIds = <String>{};

    for (var step = 0; step < 40; step++) {
      final section = nextAvailableSection(attempt, completedSectionIds);
      if (section == null) break;

      await openSectionInUi(tester, attempt, section);
      await completeSection(dataSource, exam.id, attempt.attemptId, section);
      await dataSource.finishMockExamSection(
          mockExamId: exam.id, attemptId: attempt.attemptId, sectionId: section.id);
      completedSectionIds.add(section.id);

      appRouter.pop(true);
      await tester.pump(const Duration(milliseconds: 500));

      attempt = await refreshAttemptAfterSection(dataSource, exam.id, completedSectionIds);
      if (attempt.isFinished) return;
    }

    final finishButton = find.byKey(const ValueKey('mock_exam_finish_button'));
    await pumpUntilFound(tester, finishButton);
    await tester.ensureVisible(finishButton);
    await tester.tap(finishButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await pumpUntilFound(tester, find.byKey(const ValueKey('mock_exam_result_page')));
  });
}

Future<void> launchApp(WidgetTester tester, String accessToken) async {
  await EasyLocalization.ensureInitialized();
  SharedPreferences.setMockInitialValues(
      {AuthLocalDataSource.accessTokenKey: accessToken, AuthLocalDataSource.introSeenKey: true});
  if (!sl.isRegistered<SharedPreferences>()) {
    await initDependencies();
  }
  await sl<AuthLocalDataSource>().setAccessToken(accessToken);

  await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru'), Locale('uz')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useOnlyLangCode: true,
      saveLocale: true,
      child: const AppRestart(child: UstadiaUserApp())));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Dio liveDio(String accessToken) => Dio(BaseOptions(
    headers: {'Authorization': 'Bearer $accessToken'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30)));

Future<MockExamModel?> firstAvailableMockExam(MockExamRemoteDataSource dataSource) async {
  var page = 1;
  while (true) {
    final result = await dataSource.fetchMockExams(page: page, limit: 10);
    for (final exam in result.items) {
      if (!exam.isFinished) return exam;
    }
    if (!result.meta.hasNext) return null;
    page++;
  }
}

Future<void> openSectionInUi(
    WidgetTester tester, MockExamAttemptModel attempt, SectionModel section) async {
  final component = componentForSection(attempt, section);
  if (component != null) {
    final componentFinder = find.byKey(ValueKey('mock_exam_component_${component.id}'));
    await pumpUntilFound(tester, componentFinder);
    await tester.ensureVisible(componentFinder);
    await tester.tap(componentFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  final sectionFinder = find.byKey(ValueKey('mock_exam_section_${section.id}'));
  await pumpUntilFound(tester, sectionFinder);
  await tester.ensureVisible(sectionFinder);
  await tester.tap(sectionFinder);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

MockExamComponentModel? componentForSection(MockExamAttemptModel attempt, SectionModel section) {
  for (final component in attempt.components) {
    final sections = sectionsForComponent(component);
    if (sections.any((item) => item.id == section.id)) return component;
  }
  return null;
}

SectionModel? nextAvailableSection(MockExamAttemptModel attempt, Set<String> completedSectionIds) {
  for (final component in attempt.components) {
    if (component.isLocked || component.isCompleted) continue;
    final sections = sectionsForComponent(component);
    for (final section in sections) {
      if (completedSectionIds.contains(section.id)) continue;
      if (section.isLocked ||
          !section.isAvailable ||
          section.progressState == SectionProgressState.completed) {
        continue;
      }
      return section;
    }
  }
  return null;
}

Future<MockExamAttemptModel> refreshAttemptAfterSection(
    MockExamRemoteDataSource dataSource, String mockExamId, Set<String> completedSectionIds) async {
  late MockExamAttemptModel attempt;
  for (var i = 0; i < 8; i++) {
    attempt = await dataSource.startMockExamAttempt(mockExamId: mockExamId);
    if (attempt.isFinished || nextAvailableSection(attempt, completedSectionIds) != null) {
      return attempt;
    }
    await Future.delayed(const Duration(milliseconds: 350));
  }
  return attempt;
}

List<SectionModel> sectionsForComponent(MockExamComponentModel component) {
  if (component.subSections.isNotEmpty) return component.subSections;
  if (component.directSection.id.isEmpty) return const [];
  return [component.directSection];
}

Future<void> completeSection(MockExamRemoteDataSource dataSource, String mockExamId,
    String attemptId, SectionModel section) async {
  final detail = await dataSource.fetchMockExamSectionDetail(
      mockExamId: mockExamId, attemptId: attemptId, sectionId: section.id);

  final answers = <Map<String, dynamic>>[];
  for (final question in detail.questions) {
    if (question.isAnswered == true) continue;
    final answer = answerPayload(question, detail.sectionType);
    if (answer == null) continue;
    answers.add(answer);
  }
  if (answers.isEmpty) return;
  try {
    await dataSource.dio.post(
        '${dataSource.baseUrl}/$mockExamId/attempts/$attemptId/sections/${detail.id}/submit',
        data: {'answers': answers});
  } on DioException {
    await submitAnswersOneByOne(dataSource, mockExamId, attemptId, detail.id, answers);
  }
}

Future<void> submitAnswersOneByOne(MockExamRemoteDataSource dataSource, String mockExamId,
    String attemptId, String sectionId, List<Map<String, dynamic>> answers) async {
  for (final answer in answers) {
    try {
      await dataSource.submitMockExamAnswer(
          mockExamId: mockExamId, attemptId: attemptId, sectionId: sectionId, answer: answer);
    } on DioException catch (error) {
      if (error.response?.statusCode != 409) rethrow;
    }
  }
}

Map<String, dynamic>? answerPayload(SectionQuestionModel question, SectionType sectionType) {
  final answers = question.answers ?? const [];
  final availableAnswers = answers.where((answer) => answer.id.isNotEmpty);
  final firstAnswer = availableAnswers.isEmpty ? null : availableAnswers.first;
  if (firstAnswer != null) {
    return {'question_id': question.id, 'selected_answer_id': firstAnswer.id};
  }

  final blankCount = question.blankAnswers.isNotEmpty
      ? question.blankAnswers.length
      : question.numberOfBlanks > 0
          ? question.numberOfBlanks
          : 0;
  if (blankCount > 0) {
    return {'question_id': question.id, 'blank_answers': List.filled(blankCount, 'test')};
  }

  final questionType = question.questionType.toLowerCase();
  if (sectionType == SectionType.speaking || questionType.contains('speaking')) {
    return {'question_id': question.id, 'audio_file_id': 'test-audio-file-id'};
  }
  if (sectionType == SectionType.writing || questionType.contains('writing')) {
    return {
      'question_id': question.id,
      'answer_text': 'This is an automated mock exam test answer used to verify the student flow.'
    };
  }
  return {'question_id': question.id, 'answer_text': 'test'};
}

Future<void> pumpUntilFound(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}
