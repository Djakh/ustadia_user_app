import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/dashboard/data/models/current_unit_model.dart';
import 'package:ustadia_user_app/features/dashboard/data/services/current_unit_store.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_sections_params.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class TodayPlanCard extends StatefulWidget {
  const TodayPlanCard({super.key});

  @override
  State<TodayPlanCard> createState() => TodayPlanCardState();
}

class TodayPlanCardState extends State<TodayPlanCard> {
  static const double _cardHeight = 252;
  static const double _buttonHeight = 44;

  late final CurrentUnitStore currentUnitStore;

  @override
  void initState() {
    super.initState();
    currentUnitStore = sl<CurrentUnitStore>();
    currentUnitStore.refreshIfNeeded();
  }

  Widget _planItem(String value, String label, BuildContext context) => Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: Style.headline3w7(context).copyWith(color: AppColors.white))),
        const SizedBox(height: 4),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Style.small3w7(context, color: TextColorRole.whiteColor))
      ]));

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.white.withValues(alpha: 0.4));

  Row todaysPlanInfo(BuildContext context, CurrentUnitModel unit) => Row(children: [
        _planItem('${unit.totalSections}', 'Total sections'.tr(), context),
        _divider(),
        _planItem('${unit.completedSections}', 'Completed'.tr(), context),
        _divider(),
        _planItem('${unit.completionPercentage.round()}%', 'Progress'.tr(), context)
      ]);

  LearnUnitProgressState _progressState(CurrentUnitModel unit) => unit.completionPercentage >= 100
      ? LearnUnitProgressState.completed
      : LearnUnitProgressState.inProgress;

  LearnUnitModel _toLearnUnitModel(CurrentUnitModel unit) => LearnUnitModel(
        id: unit.id,
        unitNumber: unit.orderIndex,
        title: unit.name,
        description: '',
        totalSections: unit.totalSections,
        imageUrl: null,
        progressPercent: unit.completionPercentage,
        progressState: _progressState(unit),
        isPublished: true,
        isLocked: false,
      );

  Future<void> openTodayPlan(BuildContext context, CurrentUnitModel unit) async {
    await context.push(learnSectionsRoute,
        extra: LearnSectionsParams(unit: _toLearnUnitModel(unit), lessonId: unit.lesson.id));
    if (!mounted) return;
    currentUnitStore.refreshIfNeeded();
  }

  Widget startPlanButton(BuildContext context, CurrentUnitModel unit) => Button.primary(
        onTap: () => openTodayPlan(context, unit),
        color: AppColors.white,
        height: _buttonHeight.toInt(),
        textColor: AppColors.black,
        text: 'Start today`s plan'.tr(),
      );

  Widget unitHeader(BuildContext context, CurrentUnitModel unit) =>
      LayoutBuilder(builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 78;
        final hasLesson = unit.lesson.name.isNotEmpty;
        final title = unit.name.isNotEmpty
            ? unit.name
            : 'Unit {number}'.tr(namedArgs: {'number': '${unit.orderIndex}'});

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Today`s plan'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Style.small3w4(context, color: TextColorRole.whiteColor)),
          SizedBox(height: isCompact ? 4 : 8),
          Flexible(
              flex: hasLesson ? 2 : 1,
              child: Text(title,
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Style.body2w7(context, color: TextColorRole.whiteColor))),
          if (hasLesson) ...[
            SizedBox(height: isCompact ? 0 : 2),
            Flexible(
                child: Text(unit.lesson.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Style.bodyw4(context, color: TextColorRole.whiteColor))),
          ],
        ]);
      });

  Widget view(BuildContext context, CurrentUnitModel unit) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: unitHeader(context, unit)),
        const SizedBox(height: 14),
        todaysPlanInfo(context, unit),
        const SizedBox(height: 14),
        startPlanButton(context, unit)
      ]);

  Widget cardShell(BuildContext context, Widget child) => Container(
        width: double.infinity,
        height: _cardHeight,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.yellowE10.withValues(alpha: 0.5), AppColors.green6B],
                stops: const [0.0, 0.9]),
            borderRadius: Style.border24),
        child: child,
      );

  Widget loading(BuildContext context) => const Center(
      child: PrimaryLoadingIndicator(
          height: 28, width: 28, valueColor: AlwaysStoppedAnimation<Color>(AppColors.white)));

  Widget messageView(BuildContext context, String message) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today`s plan'.tr(),
              style: Style.small3w4(context, color: TextColorRole.whiteColor)),
          const SizedBox(height: 12),
          Expanded(
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(message,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Style.bodyw5(context, color: TextColorRole.whiteColor)))),
        ],
      );

  @override
  Widget build(BuildContext context) => cardShell(
      context,
      ValueListenableBuilder<bool>(
          valueListenable: currentUnitStore.loading,
          builder: (context, isLoading, _) => ValueListenableBuilder<CurrentUnitModel?>(
              valueListenable: currentUnitStore.unit,
              builder: (context, unit, __) {
                if (isLoading && unit == null) return loading(context);
                if (unit == null || unit.id.isEmpty) {
                  return messageView(context, 'No current unit found'.tr());
                }
                return view(context, unit);
              })));
}
