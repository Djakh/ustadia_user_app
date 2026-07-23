import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';

class PracticeQuestionsOverview extends StatelessWidget {
  final String title;
  final int total;
  final Set<int> completedIndices;
  final ValueChanged<int> onQuestionTap;
  final VoidCallback onContinueIncomplete;
  final VoidCallback onShowResult;

  const PracticeQuestionsOverview({
    super.key,
    required this.title,
    required this.total,
    required this.completedIndices,
    required this.onQuestionTap,
    required this.onContinueIncomplete,
    required this.onShowResult,
  });

  int get completedCount => completedIndices.length;
  bool get allCompleted => total > 0 && completedCount >= total;

  int? get firstIncompleteIndex {
    for (var index = 0; index < total; index++) {
      if (!completedIndices.contains(index)) return index;
    }
    return null;
  }

  Widget statusPill(BuildContext context, bool isCompleted) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (isCompleted ? AppColors.primary : AppColors.orange033).withValues(alpha: 0.12),
          borderRadius: Style.border16,
        ),
        child: Text(
          isCompleted ? 'Completed'.tr() : 'Incomplete'.tr(),
          style: Style.small3w5(context).copyWith(
            color: isCompleted ? AppColors.primary : AppColors.orange033,
          ),
        ),
      );

  Widget questionTile(BuildContext context, int index) {
    final isCompleted = completedIndices.contains(index);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onQuestionTap(index),
        borderRadius: Style.border20,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cs.surface,
            borderRadius: Style.border20,
            border: Border.all(
              color: isCompleted
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.orange033.withValues(alpha: 0.25),
            ),
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.orange033.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.edit_rounded,
                color: isCompleted ? AppColors.primary : AppColors.orange033,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Question {number}'.tr(namedArgs: {'number': '${index + 1}'}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Style.body2w5(context),
              ),
            ),
            const SizedBox(width: 8),
            statusPill(context, isCompleted),
          ]),
        ),
      ),
    );
  }

  Widget summary(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
        child: Row(children: [
          const Icon(Icons.fact_check_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Completed {completed} of {total}'.tr(
                namedArgs: {'completed': '$completedCount', 'total': '$total'},
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Style.body2w5(context),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => PrimaryBackground(
        title: title,
        isScrollable: false,
        child: Column(children: [
          summary(context),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: total,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => questionTile(context, index),
            ),
          ),
          const SizedBox(height: 16),
          if (allCompleted)
            Button.primary(onTap: onShowResult, text: 'Show result'.tr())
          else
            Button.primary(
              onTap: () {
                final index = firstIncompleteIndex;
                if (index == null) return onContinueIncomplete();
                onQuestionTap(index);
              },
              text: 'Continue incomplete'.tr(),
            ),
        ]),
      );
}
