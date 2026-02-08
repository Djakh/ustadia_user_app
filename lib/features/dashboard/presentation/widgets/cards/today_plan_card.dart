import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/dashboard/data/models/current_unit_model.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/bloc/current_unit_bloc/current_unit_bloc.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/bloc/current_unit_bloc/current_unit_event.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/bloc/current_unit_bloc/current_unit_state.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_sections_params.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class TodayPlanCard extends StatelessWidget {
  const TodayPlanCard({super.key});

  Widget _planItem(String value, String label, BuildContext context) => Column(children: [
        Text(value, style: Style.headline3w7(context).copyWith(color: AppColors.white)),
        const SizedBox(height: 4),
        Text(label, style: Style.bodyw7(context, color: TextColorRole.whiteColor))
      ]);

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.white.withValues(alpha: 0.4));

  Row todaysPlanInfo(BuildContext context, CurrentUnitModel unit) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _planItem('${unit.totalSections}', 'Total sections', context),
        _divider(),
        _planItem('${unit.completedSections}', 'Completed', context),
        _divider(),
        _planItem('${unit.completionPercentage.round()}%', 'Progress', context)
      ]);

  LearnUnitProgressState _progressState(CurrentUnitModel unit) =>
      unit.completionPercentage >= 100
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

  Widget startPlanButton(BuildContext context, CurrentUnitModel unit) => Button.primary(
        onTap: () => context.push(learnSectionsRoute,
            extra: LearnSectionsParams(unit: _toLearnUnitModel(unit), lessonId: unit.lesson.id)),
        color: AppColors.white,
        textColor: AppColors.black,
        text: "Start today's plan",
      );

  Widget unitHeader(BuildContext context, CurrentUnitModel unit) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's plan", style: Style.small3w4(context, color: TextColorRole.whiteColor)),
          const SizedBox(height: 8),
          Text(
            unit.name.isNotEmpty ? unit.name : 'Unit ${unit.orderIndex}',
            style: Style.body2w7(context, color: TextColorRole.whiteColor),
          ),
          if (unit.lesson.name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(unit.lesson.name, style: Style.bodyw4(context, color: TextColorRole.whiteColor)),
          ],
        ],
      );

  Widget view(BuildContext context, CurrentUnitModel unit) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        unitHeader(context, unit),
        const SizedBox(height: 22),
        todaysPlanInfo(context, unit),
        const SizedBox(height: 22),
        startPlanButton(context, unit)
      ]);

  Widget cardShell(BuildContext context, Widget child) => Container(
        width: double.infinity,
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

  Widget loading(BuildContext context) => const PrimaryLoadingIndicator(
        height: 28,
        width: 28,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
      );

  Widget errorView(BuildContext context, String message) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's plan", style: Style.small3w4(context, color: TextColorRole.whiteColor)),
          const SizedBox(height: 12),
          Text(message, style: Style.bodyw5(context, color: TextColorRole.whiteColor)),
        ],
      );

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => sl<CurrentUnitBloc>()..add(const CurrentUnitRequested()),
        child: Builder(
          builder: (context) => cardShell(
              context,
              BlocStatusView<CurrentUnitBloc, CurrentUnitState, CurrentUnitModel?>(
                statusOf: (s) => s.status,
                errorOf: (s) => s.errorMessage,
                data: (s) => s.unit,
                isEmpty: (unit) => unit == null || unit.id.isEmpty,
                loading: loading(context),
                empty: errorView(context, 'No current unit found'),
                errorBuilder: (message) => errorView(context, message),
                builder: (context, unit) => view(context, unit!),
              )),
        ),
      );
}
