import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/dashboard/data/models/dashboard_day_model.dart';

class DashboardCalendar extends StatefulWidget {
  const DashboardCalendar({super.key});

  @override
  State<DashboardCalendar> createState() => _DashboardCalendarState();
}

class _DashboardCalendarState extends State<DashboardCalendar> {
  late final List<DashboardDayModel> days;
  late final List<List<DashboardDayModel>> weeks;
  late final PageController _pageController;
  int currentWeekIndex = 0;
  late final DateTime _currentDay;
  DateTime get month => DateTime(2025, 11);

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    _currentDay = DateTime(2025, 11, 6); // simulated "today"
    days = _staticDays(_currentDay);
    weeks = _splitIntoWeeks(days);
    currentWeekIndex = _initialWeekIndex();
    _pageController = PageController(initialPage: currentWeekIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// --- Data helpers ---

  List<DashboardDayModel> _staticDays(DateTime today) {
    // simulate server data
    return List.generate(30, (i) {
      final date = DateTime(2025, 11, i + 1);
      final isCurrent = date.day == today.day;
      final isFuture = date.isAfter(today);
      final progress = isFuture ? 0.0 : (i % 5) / 5; // some variation only for past/current
      return DashboardDayModel(date: date, progress: progress, isCurrentDay: isCurrent);
    });
  }

  List<List<DashboardDayModel>> _splitIntoWeeks(List<DashboardDayModel> days) {
    final weeks = <List<DashboardDayModel>>[];
    var currentWeek = <DashboardDayModel>[];
    int currentWeekday = days.first.date.weekday;

    for (final day in days) {
      if (currentWeek.isEmpty) {
        currentWeekday = day.date.weekday;
      }
      if (currentWeek.length == 7 ||
          (currentWeek.isNotEmpty && day.date.weekday <= currentWeekday)) {
        weeks.add(currentWeek);
        currentWeek = <DashboardDayModel>[];
      }
      currentWeek.add(day);
      currentWeekday = day.date.weekday;
    }
    if (currentWeek.isNotEmpty) weeks.add(currentWeek);
    return weeks;
  }

  int _initialWeekIndex() {
    for (var i = 0; i < weeks.length; i++) {
      if (weeks[i].any((d) => d.isCurrentDay)) return i;
    }
    return 0;
  }

  /// --- Getters ---

  bool isAfter(DashboardDayModel day) => day.date.isAfter(_currentDay);

  /// --- Methods ---

  void _prevWeek() {
    if (currentWeekIndex == 0) return;
    setState(() => currentWeekIndex--);
    _pageController.previousPage(
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _nextWeek() {
    if (currentWeekIndex == weeks.length - 1) return;
    setState(() => currentWeekIndex++);
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  /// --- Widgets ---

  Widget get monthHeader => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(onPressed: _prevWeek, icon: const Icon(Icons.arrow_back, size: 24)),
        Text('November, 2025', style: Style.body2w6(context)),
        IconButton(onPressed: _nextWeek, icon: const Icon(Icons.arrow_forward, size: 24))
      ]);

  Widget dayCircle(DashboardDayModel day) => Stack(alignment: Alignment.center, children: [
        SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
                value: day.progress.clamp(0.0, 1.0),
                strokeWidth: 2.5,
                backgroundColor: AppColors.gray8C.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(context.cs.primary))),
        Text(day.label,
            style: Style.bodyw5(context)
                .copyWith(color: isAfter(day) ? AppColors.grayC43 : AppColors.black))
      ]);

  Text weekDayText(DashboardDayModel day) => Text(day.weekdayShort,
      style: Style.small2w5(context,
          color: day.isCurrentDay ? TextColorRole.onSurface : TextColorRole.greyColor));

  Widget dayItem(DashboardDayModel day, bool isCurrentDay) => AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(8),
      decoration: isCurrentDay
          ? BoxDecoration(color: AppColors.gray100, borderRadius: Style.border12)
          : null,
      child: Column(
        children: [weekDayText(day), const SizedBox(height: 4), dayCircle(day)],
      ));

  Widget weekView(List<DashboardDayModel> weekDays) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children:
            List.generate(weekDays.length, (i) => dayItem(weekDays[i], weekDays[i].isCurrentDay)),
      );

  Widget get calendarStrip => SizedBox(
      height: 78,
      child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) => setState(() => currentWeekIndex = i),
          itemCount: weeks.length,
          itemBuilder: (_, index) => weekView(weeks[index])));

  @override
  Widget build(BuildContext context) =>
      Column(children: [monthHeader, const SizedBox(height: 12), calendarStrip]);
}
