import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

void main() {
  test('article ignores completed status because it does not track progress', () {
    final section = SectionModel.fromJson({
      'id': 'article-1',
      'type': 'article',
      'isCompleted': true,
      'status': 'completed',
      'totalQuestions': 2,
      'answeredQuestions': 2,
      'questions': [
        {'id': 'ignored-question'}
      ],
    });

    expect(section.progressState, SectionProgressState.notApplicable);
    expect(section.tracksProgress, isFalse);
    expect(section.isCompleted, isFalse);
    expect(section.status, isEmpty);
    expect(section.totalQuestions, 0);
    expect(section.answeredQuestions, isNull);
    expect(section.questions, isEmpty);
  });

  test('non-article section still maps completed status', () {
    final section = SectionModel.fromJson({
      'id': 'reading-1',
      'type': 'reading',
      'isCompleted': true,
    });

    expect(section.progressState, SectionProgressState.completed);
    expect(section.tracksProgress, isTrue);
    expect(section.isCompleted, isTrue);
  });
}
