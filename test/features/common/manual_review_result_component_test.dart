import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_stats_model.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/injection_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    EasyLocalization.logger.enableLevels = [];
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('speaking result shows pending review instead of score while ungraded',
      (tester) async {
    await _registerResultDependencies(_stats(sectionType: 'speaking'));

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: QuizResultComponent(sectionModel: _section(SectionType.speaking)))));
    await tester.pumpAndSettle();

    expect(find.text('Pending review'), findsOneWidget);
    expect(find.text('Your speaking responses have been submitted and are awaiting evaluation.'),
        findsOneWidget);
    expect(find.text('0 of 5 correct'), findsNothing);
    expect(find.text('Needs practice!'), findsNothing);
    expect(find.text('Correct'), findsNothing);
    expect(find.text('Incorrect'), findsNothing);
    expect(find.text('Answered'), findsNothing);
    expect(find.text('Submission received'), findsOneWidget);
    expect(find.text('Your audio response was saved successfully.'), findsOneWidget);
    expect(find.text('Awaiting evaluation'), findsOneWidget);
    expect(find.text('Your score and feedback will appear after review.'), findsOneWidget);
  });

  testWidgets('redo resets the section before invoking the page reload', (tester) async {
    final dataSource = await _registerResultDependencies(_stats(sectionType: 'reading'));
    var reloadCalls = 0;

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuizResultComponent(
                sectionModel: _section(SectionType.reading), onRedo: () => reloadCalls++))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Redo'));
    await tester.pumpAndSettle();

    expect(dataSource.redoneSectionIds, ['section_1']);
    expect(reloadCalls, 1);
  });
}

Future<_FakeLearnRemoteDataSource> _registerResultDependencies(SectionStatsModel stats) async {
  await sl.reset();
  final dataSource = _FakeLearnRemoteDataSource(stats);
  sl.registerLazySingleton<LearnRemoteDataSource>(() => dataSource);
  return dataSource;
}

SectionStatsModel _stats({required String sectionType}) => SectionStatsModel(
      sectionId: 'section_1',
      sectionType: sectionType,
      totalQuestions: 5,
      answeredQuestions: 5,
      unansweredQuestions: 0,
      correct: 0,
      incorrect: 0,
      pending: 5,
    );

SectionModel _section(SectionType type) => SectionModel(
      id: 'section_1',
      unitId: 'unit_1',
      lessonId: 'lesson_1',
      title: 'Speaking',
      content: '',
      orderIndex: 0,
      totalQuestions: 5,
      answeredQuestions: 5,
      assignmentId: null,
      audioFileId: null,
      audioFile: null,
      flashCardSetId: null,
      flashCardSet: null,
      unitIsPublished: true,
      lessonIsPublic: true,
      questions: const [],
      iconAsset: '',
      progressState: SectionProgressState.completed,
      sectionType: type,
      sectionStringType: type.name,
      isLocked: false,
    );

class _FakeLearnRemoteDataSource extends LearnRemoteDataSource {
  final SectionStatsModel stats;
  final List<String> redoneSectionIds = [];

  _FakeLearnRemoteDataSource(this.stats) : super(dio: Dio());

  @override
  Future<SectionStatsModel> fetchSectionStats({required String sectionId}) async => stats;

  @override
  Future<void> redoSection({required String sectionId}) async {
    redoneSectionIds.add(sectionId);
  }
}
