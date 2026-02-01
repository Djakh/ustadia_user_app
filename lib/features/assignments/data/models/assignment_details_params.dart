import 'package:ustadia_user_app/features/assignments/data/models/assignment_detail_type.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_type_theme.dart';

class AssignmentDetailsParams {
  final String title;
  final String subtitle;
  final AssignmentDetailType type;
  final AssignmentTypeTheme theme;

  const AssignmentDetailsParams({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.theme
  });
}
