import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_timer_badge.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';

void main() {
  test('mock exam deadline uses only remaining seconds', () {
    final notStartedExam = MockExamModel.fromJson({
      'id': 'mock-1',
      'title': 'Mock',
      'description': 'Mock description',
      'time_limit_minutes': 60,
      'assignment': {'attempt': null, 'finished': false}
    });

    expect(notStartedExam.deadlineAt, isNull);
    expect(notStartedExam.hasDeadline, isFalse);

    final startedWithoutRemainingTime = MockExamModel.fromJson({
      'id': 'mock-2',
      'title': 'Mock',
      'description': 'Mock description',
      'time_limit_minutes': 60,
      'assignment': {
        'finished': false,
        'attempt': {'id': 'attempt-1', 'is_started': true, 'is_finished': false}
      }
    });

    expect(startedWithoutRemainingTime.deadlineAt, isNull);
    expect(startedWithoutRemainingTime.hasDeadline, isFalse);

    final startedWithRemainingTime = MockExamModel.fromJson({
      'id': 'mock-3',
      'title': 'Mock',
      'description': 'Mock description',
      'time_limit_minutes': 60,
      'time_remaining_seconds': 90,
      'assignment': {
        'finished': false,
        'attempt': {'id': 'attempt-2', 'is_started': true, 'is_finished': false}
      }
    });

    expect(startedWithRemainingTime.hasDeadline, isTrue);
    expect(startedWithRemainingTime.remainingDuration.inSeconds, inInclusiveRange(88, 90));
  });

  testWidgets('section timer calls expired immediately when remaining time is zero',
      (tester) async {
    var expiredCount = 0;

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SectionTimerBadge(timeRemainingSeconds: 0, onExpired: () => expiredCount++))));

    await tester.pump();

    expect(expiredCount, 1);
  });

  testWidgets('section timer calls expired once when countdown reaches zero', (tester) async {
    var expiredCount = 0;

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SectionTimerBadge(timeRemainingSeconds: 1, onExpired: () => expiredCount++))));

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();

    expect(expiredCount, 1);
  });

  testWidgets('section timer is hidden when remaining time is null', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SectionTimerBadge(timeRemainingSeconds: null))));

    expect(find.byType(SectionTimerBadge), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
  });
}
