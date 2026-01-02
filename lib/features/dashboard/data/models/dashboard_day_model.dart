class DashboardDayModel {
  final DateTime date;
  final double progress; // 0..1
  final bool isCurrentDay;

  const DashboardDayModel({required this.date, required this.progress, this.isCurrentDay = false});

  String get label => date.day.toString();
  String get weekdayShort => _weekday(date.weekday);

  static String _weekday(int wd) {
    switch (wd) {
      case DateTime.monday:
        return 'MON';
      case DateTime.tuesday:
        return 'TUE';
      case DateTime.wednesday:
        return 'WED';
      case DateTime.thursday:
        return 'THU';
      case DateTime.friday:
        return 'FRI';
      case DateTime.saturday:
        return 'SAT';
      case DateTime.sunday:
        return 'SUN';
      default:
        return '';
    }
  }
}
