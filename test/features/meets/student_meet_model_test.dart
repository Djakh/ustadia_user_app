import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/meets/data/models/student_meet_model.dart';
import 'package:ustadia_user_app/features/meets/presentation/bloc/student_meets_bloc/student_meets_state.dart';

StudentMeetModel meet(String id, String scheduledAt) => StudentMeetModel.fromJson({
      'id': id,
      'teacher_id': 'teacher-1',
      'title': 'Meeting $id',
      'description': 'meeting',
      'link': 'https://meet.google.com/abc-defg-hij',
      'scheduled_at': scheduledAt,
      'type': 'class',
      'teacher': {'id': 'teacher-1', 'firstName': 'Ali', 'lastName': 'Karimov'},
      'class': {'id': 'class-1', 'name': 'A1'}
    });

void main() {
  group('StudentMeetModel', () {
    test('parses nested teacher and class data', () {
      final item = meet('1', '2026-04-03T14:32:00.000Z');

      expect(item.teacherName, 'Ali Karimov');
      expect(item.className, 'A1');
      expect(item.link, 'https://meet.google.com/abc-defg-hij');
      expect(item.type, 'class');
    });

    test('splits actual and history meets by scheduled time', () {
      final now = DateTime.parse('2026-04-03T14:32:00.000Z');
      final state = StudentMeetsState(meets: [
        meet('future-2', '2026-04-03T16:00:00.000Z'),
        meet('history', '2026-04-03T14:31:59.000Z'),
        meet('future-1', '2026-04-03T15:00:00.000Z'),
      ]);

      expect(state.actualMeets(now).map((item) => item.id), ['future-1', 'future-2']);
      expect(state.historyMeets(now).map((item) => item.id), ['history']);
    });
  });
}
