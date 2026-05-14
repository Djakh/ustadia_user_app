import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_attempt_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';

void main() {
  const accessToken = String.fromEnvironment('MOCK_EXAM_ACCESS_TOKEN');

  testWidgets('completes first available mock exam from list', (tester) async {
    if (accessToken.isEmpty) {
      markTestSkipped(
          'Pass --dart-define=MOCK_EXAM_ACCESS_TOKEN=token to run this live mock exam test.');
      return;
    }

    final dataSource = MockExamRemoteDataSource(dio: liveDio(accessToken));
    final exam = await firstAvailableMockExam(dataSource);
    expect(exam, isNotNull, reason: 'No available unfinished mock exam was found.');

    final attempt = await completeMockExam(dataSource, exam!);
    expect(attempt.attemptId, isNotEmpty);

    final result = await dataSource.fetchMockExamResult(
        mockExamId: attempt.mockExamId, attemptId: attempt.attemptId);
    expect(result.attemptId, attempt.attemptId);
  });
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

Future<MockExamAttemptModel> completeMockExam(
    MockExamRemoteDataSource dataSource, MockExamModel exam) async {
  var attempt = await dataSource.startMockExamAttempt(mockExamId: exam.id);
  if (attempt.isFinished) return attempt;
  final completedSectionIds = <String>{};

  for (var step = 0; step < 40; step++) {
    final section = nextAvailableSection(attempt, completedSectionIds);
    if (section == null) break;

    await completeSection(dataSource, exam.id, attempt.attemptId, section);
    await dataSource.finishMockExamSection(
        mockExamId: exam.id, attemptId: attempt.attemptId, sectionId: section.id);
    completedSectionIds.add(section.id);

    attempt = await refreshAttemptAfterSection(dataSource, exam.id, completedSectionIds);
    if (attempt.isFinished) return attempt;
  }

  await dataSource.finishMockExam(mockExamId: exam.id, attemptId: attempt.attemptId);
  return attempt;
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
