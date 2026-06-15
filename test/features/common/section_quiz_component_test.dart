import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_storage_service.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_quiz_component.dart';
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

  testWidgets('single choice shows one-time answer reveal on first correct submit', (tester) async {
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: true)});
    await _pumpQuiz(tester, [_choiceQuestion(id: 'q1')]);

    await tester.tap(find.text('True'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('single choice shows one-time answer reveal on first incorrect submit',
      (tester) async {
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(tester, [_choiceQuestion(id: 'q1')]);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('multiple choice reveals correct answers once after first submit', (tester) async {
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(tester, [_multipleChoiceQuestion(id: 'q1')]);

    await tester.tap(find.text('Wrong choice'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsNothing);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });

  testWidgets('fill blank shows correct blank answer and locks input after first submit',
      (tester) async {
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(tester, [_fillBlankQuestion(id: 'q1')]);

    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('time'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_rounded), findsNothing);
  });

  testWidgets('fill blank creates one input even when server omits blank count and placeholder',
      (tester) async {
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(tester, [_question(id: 'q1', type: 'fill-blank')]);

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('fill blank evidence sheet uses positions from blank answers', (tester) async {
    const content = 'Reading passage shows the exact blank answer here.';
    final start = content.indexOf('exact blank answer');
    final end = start + 'exact blank answer'.length;
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(
        tester,
        [
          _question(id: 'q1', type: 'fill-blank', numberOfBlanks: 1, blankAnswers: [
            {
              'answer': 'answer',
              'position': 1,
              'positions': [
                {'start': start, 'end': end}
              ]
            }
          ])
        ],
        sectionContent: content);

    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);
    expect(_richTextContaining('exact blank answer'), findsOneWidget);
  });

  testWidgets('short answer locks input after submit and does not show answer button',
      (tester) async {
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(tester, [_shortAnswerQuestion(id: 'q1')]);

    await tester.enterText(find.byType(TextField), 'My answer');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(find.byIcon(Icons.visibility_rounded), findsNothing);
  });

  testWidgets('text evidence opens answer sheet and keeps answer button available', (tester) async {
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(tester, [_choiceQuestion(id: 'q1', withTextEvidence: true)],
        sectionContent: 'Here is answer text.');

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });

  testWidgets('first submit keeps evidence answer button when correct id comes from result',
      (tester) async {
    await _registerQuizDependencies({
      'q1': _submitResult('q1', isCorrect: false, correctAnswerIds: ['q1_true'])
    });
    await _pumpQuiz(
        tester, [_choiceQuestion(id: 'q1', withTextEvidence: true, correctAnswerMarked: false)],
        sectionContent: 'Here is answer text.');

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });

  testWidgets('reading evidence sheet stays available on first submit without correct metadata',
      (tester) async {
    const content = 'The reading answer is inside this passage.';
    final start = content.indexOf('reading answer');
    final end = start + 'reading answer'.length;
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(
        tester,
        [
          _choiceQuestion(
              id: 'q1', textEvidenceStart: start, textEvidenceEnd: end, correctAnswerMarked: false)
        ],
        sectionContent: content);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);
    expect(_richTextContaining(content), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });

  testWidgets('listening evidence sheet stays available on first submit without correct metadata',
      (tester) async {
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(
        tester, [_choiceQuestion(id: 'q1', withAudioEvidence: true, correctAnswerMarked: false)],
        sectionContent: 'Listening transcript is shown after answer submit.');

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);
    expect(find.text('Audio answer time'), findsOneWidget);
    expect(find.text('0:02 - 0:09'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });

  testWidgets('listening evidence sheet marks transcript text when audio timing is present',
      (tester) async {
    const transcript = 'Speaker A: Hello. Speaker B: The answer is here.';
    final answerStart = transcript.indexOf('The answer');
    final answerEnd = answerStart + 'The answer'.length;

    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(
        tester,
        [
          _choiceQuestion(
              id: 'q1',
              textEvidenceStart: answerStart,
              textEvidenceEnd: answerEnd,
              withAudioEvidence: true)
        ],
        sectionContent: transcript);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Audio answer time'), findsOneWidget);
    expect(_richTextContaining('The answer'), findsOneWidget);
  });

  testWidgets('listening transcript text is shown only in answer evidence sheet', (tester) async {
    const transcript = 'Speaker A: Hello. Speaker B: This is the answer.';
    final answerStart = transcript.indexOf('Speaker B');
    const answerEnd = transcript.length;

    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(tester,
        [_choiceQuestion(id: 'q1', textEvidenceStart: answerStart, textEvidenceEnd: answerEnd)],
        sectionContent: transcript);

    expect(_richTextContaining('Speaker B: This is the answer.'), findsNothing);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);
    expect(_richTextContaining('Speaker B: This is the answer.'), findsOneWidget);
    expect(find.text('Audio answer time'), findsNothing);
  });

  testWidgets('audio evidence opens answer sheet and keeps answer button available',
      (tester) async {
    const transcript = 'Full listening dialog without text positions.';
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)});
    await _pumpQuiz(tester, [_choiceQuestion(id: 'q1', withAudioEvidence: true)],
        sectionContent: transcript);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Audio answer time'), findsOneWidget);
    expect(find.text('0:02 - 0:09'), findsOneWidget);
    expect(find.text('Transcript 123'), findsOneWidget);
    expect(_richTextContaining(transcript), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });

  testWidgets('first submit refreshes missing evidence before using one-time reveal',
      (tester) async {
    const content = 'Here is answer text.';
    await _registerQuizDependencies({
      'q1': _submitResult('q1', isCorrect: false, correctAnswerIds: ['q1_true'])
    }, freshQuestions: [
      _choiceQuestion(id: 'q1', withTextEvidence: true)
    ]);
    await _pumpQuiz(tester, [_choiceQuestion(id: 'q1')], sectionContent: content);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);
    expect(_richTextContaining(content), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });

  testWidgets('first submit uses refreshed section content for evidence marking', (tester) async {
    const content = 'Listening transcript contains the answer line.';
    final start = content.indexOf('answer line');
    final end = start + 'answer line'.length;
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)},
        freshContent: content,
        freshQuestions: [
          _choiceQuestion(id: 'q1', textEvidenceStart: start, textEvidenceEnd: end)
        ]);
    await _pumpQuiz(tester, [_choiceQuestion(id: 'q1')]);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);
    expect(_richTextContaining('answer line'), findsOneWidget);
  });

  testWidgets('first submit shows answer button even when review data needs refresh',
      (tester) async {
    const content = 'Here is answer text.';
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)},
        freshQuestions: [_choiceQuestion(id: 'q1', withTextEvidence: true)]);
    await _pumpQuiz(tester, [_choiceQuestion(id: 'q1')], sectionContent: content);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);
    expect(_richTextContaining(content), findsOneWidget);
  });

  testWidgets('show answer opens evidence sheet only after refresh returns evidence',
      (tester) async {
    const content = 'Here is answer text.';
    await _registerQuizDependencies({'q1': _submitResult('q1', isCorrect: false)},
        freshQuestions: [_choiceQuestion(id: 'q1', withTextEvidence: true)],
        fetchDelay: const Duration(milliseconds: 120));
    await _pumpQuiz(tester, [_choiceQuestion(id: 'q1')], sectionContent: content);

    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pump();

    expect(find.text('Answer evidence'), findsNothing);
    expect(find.text('Loading answer...'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Answer evidence'), findsOneWidget);
    expect(_richTextContaining(content), findsOneWidget);
  });
}

Future<void> _registerQuizDependencies(Map<String, Map<String, dynamic>> results,
    {List<SectionQuestionModel> freshQuestions = const [],
    String freshContent = '',
    Duration fetchDelay = Duration.zero}) async {
  await sl.reset();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tutorialStorage = TutorialStorageService(prefs: prefs);
  await tutorialStorage.setTutorialEnabled(false);
  final learnRemoteDataSource = _FakeLearnRemoteDataSource(results,
      freshQuestions: freshQuestions, freshContent: freshContent, fetchDelay: fetchDelay);

  sl.registerSingleton<TutorialStorageService>(tutorialStorage);
  sl.registerFactory(() => QuestionAnswerBloc(
      learnRemoteDataSource: learnRemoteDataSource,
      assignmentsRemoteDataSource: _FakeAssignmentsRemoteDataSource(),
      mockExamRemoteDataSource: MockExamRemoteDataSource(dio: Dio()),
      profileStatisticsStore:
          ProfileStatisticsStore(userRemoteDataSource: UserRemoteDataSource(dio: Dio())),
      currentUnitStore: CurrentUnitStore(learnRemoteDataSource: learnRemoteDataSource)));
}

Future<void> _pumpQuiz(WidgetTester tester, List<SectionQuestionModel> questions,
    {String sectionContent = ''}) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SizedBox.expand(
              child: SectionQuizComponent(
                  questions: questions, sectionContent: sectionContent, onFinish: (_) {})))));
  await tester.pumpAndSettle();
}

Map<String, dynamic> _submitResult(String questionId,
        {required bool isCorrect, List<String> correctAnswerIds = const []}) =>
    {
      'question_id': questionId,
      'is_correct': isCorrect,
      if (correctAnswerIds.isNotEmpty) 'correct_answer_ids': correctAnswerIds,
    };

SectionQuestionModel _choiceQuestion(
    {required String id,
    bool withTextEvidence = false,
    int? textEvidenceStart,
    int? textEvidenceEnd,
    bool withAudioEvidence = false,
    bool correctAnswerMarked = true}) {
  return _question(id: id, type: 'true-false', answers: [
    _answer(
        id: '${id}_true',
        questionId: id,
        text: 'True',
        isCorrect: correctAnswerMarked,
        startPosition: textEvidenceStart ?? (withTextEvidence ? 8 : null),
        endPosition: textEvidenceEnd ?? (withTextEvidence ? 14 : null),
        audioStartTime: withAudioEvidence ? 1.7 : null,
        audioEndTime: withAudioEvidence ? 9.4 : null,
        transcript: withAudioEvidence ? 'Transcript 123' : null),
    _answer(id: '${id}_false', questionId: id, text: 'False', isCorrect: false, orderIndex: 1),
  ]);
}

SectionQuestionModel _multipleChoiceQuestion({required String id}) {
  return _question(id: id, type: 'multiple-choice', maxSelections: 2, answers: [
    _answer(id: '${id}_a', questionId: id, text: 'Correct one', isCorrect: true),
    _answer(id: '${id}_b', questionId: id, text: 'Correct two', isCorrect: true, orderIndex: 1),
    _answer(id: '${id}_c', questionId: id, text: 'Wrong choice', isCorrect: false, orderIndex: 2),
  ]);
}

SectionQuestionModel _fillBlankQuestion({required String id}) {
  return _question(id: id, type: 'fill-blank', numberOfBlanks: 1, blankAnswers: [
    {'answer': 'time', 'position': 1}
  ]);
}

SectionQuestionModel _shortAnswerQuestion({required String id}) =>
    _question(id: id, type: 'short-answer');

SectionQuestionModel _question(
        {required String id,
        required String type,
        String? title,
        List<Map<String, dynamic>>? answers,
        List<Map<String, dynamic>>? blankAnswers,
        int numberOfBlanks = 0,
        int maxSelections = 1}) =>
    SectionQuestionModel.fromJson({
      'id': id,
      'section_id': 'section',
      'type': type,
      'title': title ?? 'Question $id',
      'description': null,
      'difficulty_id': 'difficulty',
      'order_index': 0,
      'xp': 1,
      'is_answered': false,
      'number_of_blanks': numberOfBlanks,
      'blank_answers': blankAnswers,
      'user_blank_answers': null,
      'answers': answers,
      'max_selections': maxSelections,
    }, unitId: 'unit', lessonId: 'lesson');

Map<String, dynamic> _answer(
        {required String id,
        required String questionId,
        required String text,
        required bool isCorrect,
        int orderIndex = 0,
        int? startPosition,
        int? endPosition,
        List<Map<String, int>> positions = const [],
        double? audioStartTime,
        double? audioEndTime,
        String? transcript}) =>
    {
      'id': id,
      'question_id': questionId,
      'answer_text': text,
      'is_correct': isCorrect,
      'order_index': orderIndex,
      'user_selected': false,
      'start_position': startPosition,
      'end_position': endPosition,
      'positions': positions,
      'audio_start_time': audioStartTime,
      'audio_end_time': audioEndTime,
      'transcript': transcript,
    };

class _FakeLearnRemoteDataSource extends LearnRemoteDataSource {
  final Map<String, Map<String, dynamic>> results;
  final List<SectionQuestionModel> freshQuestions;
  final String freshContent;
  final Duration fetchDelay;

  _FakeLearnRemoteDataSource(this.results,
      {this.freshQuestions = const [], this.freshContent = '', this.fetchDelay = Duration.zero})
      : super(dio: Dio());

  @override
  Future<Map<String, dynamic>> submitLessonAnswers(
      {required String lessonId,
      required String unitId,
      required List<Map<String, dynamic>> answers}) async {
    final questionId = answers.first['questionId']?.toString() ?? '';
    return results[questionId] ?? _submitResult(questionId, isCorrect: false);
  }

  @override
  Future<SectionModel> fetchSectionDetail({required String sectionId}) async {
    if (fetchDelay > Duration.zero) await Future<void>.delayed(fetchDelay);
    return SectionModel.fromJson({
      'id': sectionId,
      'title': 'Section',
      'type': 'reading',
      'content': freshContent,
      'order_index': 0,
      'questions': freshQuestions.map((question) => _questionToJson(question)).toList(),
    });
  }
}

Map<String, dynamic> _questionToJson(SectionQuestionModel question) => {
      'id': question.id,
      'section_id': question.sectionId,
      'type': question.questionType,
      'title': question.title,
      'description': question.description,
      'difficulty': question.difficulty,
      'order_index': question.orderIndex,
      'xp': question.xp,
      'is_answered': question.isAnswered,
      'number_of_blanks': question.numberOfBlanks,
      'blank_answers': question.blankAnswers
          .map((item) => {
                'position': item.position,
                'answer': item.answer,
                'transcript': item.transcript,
                'audio_start_time': item.audioStartTime,
                'audio_end_time': item.audioEndTime,
                'positions': item.positions
                    .map((position) => {'start': position.start, 'end': position.end})
                    .toList(),
              })
          .toList(),
      'user_blank_answers': question.userBlankAnswers
          .map((item) => {'position': item.position, 'answer': item.answer})
          .toList(),
      'answers': question.answers
          ?.map((answer) => {
                'id': answer.id,
                'question_id': answer.questionId,
                'answer_text': answer.answerText,
                'is_correct': answer.isCorrect,
                'order_index': answer.orderIndex,
                'user_selected': answer.userSelected,
                'transcript': answer.transcript,
                'start_position': answer.startPosition,
                'end_position': answer.endPosition,
                'positions': answer.positions
                    .map((position) => {'start': position.start, 'end': position.end})
                    .toList(),
                'audio_start_time': answer.audioStartTime,
                'audio_end_time': answer.audioEndTime,
              })
          .toList(),
      'max_selections': question.maxSelections,
    };

class _FakeAssignmentsRemoteDataSource extends AssignmentsRemoteDataSource {
  _FakeAssignmentsRemoteDataSource() : super(dio: Dio());
}

Finder _richTextContaining(String text) => find
    .byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains(text));
