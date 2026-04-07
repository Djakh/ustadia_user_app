import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/connection/reload_conntection_button.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_stats_model.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/injection_container.dart';

class QuizResultComponent extends StatefulWidget {
  final int? all;
  final int? correctOnes;
  final String? aiFeedback;
  final String? feedback;
  final SectionModel? sectionModel;

  const QuizResultComponent({
    super.key,
    this.all,
    this.correctOnes,
    this.aiFeedback,
    this.feedback,
    this.sectionModel,
  });

  @override
  State<QuizResultComponent> createState() => _QuizResultComponentState();
}

class _QuizResultComponentState extends State<QuizResultComponent> {
  SectionStatsModel? stats;
  bool isLoading = false;
  String? errorMessage;

  bool get hasRemoteStats => widget.sectionModel != null && widget.sectionModel!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (hasRemoteStats) {
      loadStats();
    }
  }

  Future<void> loadStats() async {
    final sectionModel = widget.sectionModel;
    if (sectionModel == null || sectionModel.id.isEmpty) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final loaded = sectionModel.source == SectionSource.assignment
          ? await sl<AssignmentsRemoteDataSource>().fetchAssignmentSectionStats(
              assignmentId: sectionModel.assignmentId ?? '', sectionId: sectionModel.id)
          : await sl<LearnRemoteDataSource>().fetchSectionStats(sectionId: sectionModel.id);
      if (!mounted) return;
      setState(() => stats = loaded);
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void backToTopic(BuildContext context) => context.pop(true);

  int get total => stats?.totalQuestions ?? widget.all ?? 0;
  int get correct => stats?.correct ?? widget.correctOnes ?? 0;
  int get answered => stats?.answeredQuestions ?? widget.all ?? 0;
  int get incorrect => stats?.incorrect ?? ((answered - correct) < 0 ? 0 : answered - correct);
  int get unanswered =>
      stats?.unansweredQuestions ?? ((total - answered) < 0 ? 0 : total - answered);
  int get pending => stats?.pending ?? 0;
  double get scoreRatio => total > 0 ? correct / total : 0;

  bool get isSuccessState => answered > 0 && incorrect == 0;
  bool get isFailureState => incorrect > 0 && correct == 0;

  Color get accentColor {
    if (isSuccessState) return AppColors.success;
    if (isFailureState) return AppColors.error;
    return AppColors.orange033;
  }

  IconData get resultIcon {
    if (isSuccessState) return Icons.check_circle_rounded;
    if (isFailureState) return Icons.cancel_rounded;
    return Icons.info_rounded;
  }

  String get resultTitle {
    if (total > 0 && correct == total) return 'Perfect score!'.tr();
    if (scoreRatio >= 0.7) return 'Great job!'.tr();
    if (scoreRatio >= 0.4) return 'Good effort!'.tr();
    if (isFailureState) return 'Incorrect answer'.tr();
    return 'Keep practicing!'.tr();
  }

  String get subtitleText {
    if (total <= 0) return 'Task completed!'.tr();
    return '{correct} of {all} correct'
        .tr(namedArgs: {'correct': '$correct', 'all': '$total'});
  }

  Widget feedbackHeader(String title, BuildContext context) => Row(children: [
        SvgPicture.asset(AppImages.feedbackIcon),
        const SizedBox(width: 8),
        Text(title, style: Style.bodyw5(context)),
      ]);

  Widget feedbacksBox(BuildContext context, String title, String text) => Container(
        padding: Style.paddingAll16,
        decoration: BoxDecoration(
          borderRadius: Style.border20,
          color: context.cs.surface,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          feedbackHeader(title, context),
          const SizedBox(height: 12),
          Text(text, style: Style.small2w4(context)),
        ]),
      );

  Widget resultStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: Style.border20,
          color: context.cs.surface,
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: Style.border12,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Style.small2w4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 2),
            Text(value, style: Style.body2w6(context))
          ]))
        ]),
      );

  Widget statsGrid(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(
              child: resultStatCard(context,
                  label: 'Correct'.tr(),
                  value: '$correct',
                  color: AppColors.primary,
                  icon: Icons.check_circle_rounded)),
          const SizedBox(width: 12),
          Expanded(
              child: resultStatCard(context,
                  label: 'Incorrect'.tr(),
                  value: '$incorrect',
                  color: AppColors.error,
                  icon: Icons.cancel_rounded)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: resultStatCard(context,
                  label: 'Answered'.tr(),
                  value: '$answered',
                  color: AppColors.gray500,
                  icon: Icons.assignment_turned_in_rounded)),
          const SizedBox(width: 12),
          Expanded(
              child: resultStatCard(context,
                  label: 'Unanswered'.tr(),
                  value: '$unanswered',
                  color: AppColors.orange033,
                  icon: Icons.hourglass_bottom_rounded)),
        ]),
        if (pending > 0) ...[
          const SizedBox(height: 12),
          resultStatCard(context,
              label: 'Pending'.tr(),
              value: '$pending',
              color: AppColors.gray400,
              icon: Icons.schedule_rounded),
        ]
      ]);

  Widget centerBlock(BuildContext context) => Column(
        children: [
          Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 8))
                  ]),
              child: Icon(resultIcon, color: accentColor, size: 54)),
          const SizedBox(height: 18),
          Text(resultTitle, style: Style.body3w7(context), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            subtitleText,
            style: Style.small2w3(context, color: TextColorRole.greyColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (total > 0) statsGrid(context),
          if (total > 0) const SizedBox(height: 24),
        ],
      );

  List<Widget> feedbackBlocks(BuildContext context) {
    final blocks = <Widget>[];

    if (widget.feedback != null && widget.feedback!.trim().isNotEmpty) {
      blocks.add(feedbacksBox(context, 'Feedback', widget.feedback!));
      blocks.add(const SizedBox(height: 16));
    }

    if (widget.aiFeedback != null && widget.aiFeedback!.trim().isNotEmpty) {
      blocks.add(feedbacksBox(context, 'AI feedback', widget.aiFeedback!));
      blocks.add(const SizedBox(height: 16));
    }

    return blocks;
  }

  Widget bottomButton(BuildContext context) => Button.primary(
        onTap: () => backToTopic(context),
        text: 'Continue'.tr(),
        color: accentColor,
      );

  Widget loadingView() => const Center(child: PrimaryLoadingIndicator());

  Widget errorView() => Center(child: ReloadConntectionButton(onReloadConnection: loadStats));

  Widget content(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 60),
                child: IntrinsicHeight(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Spacer(),
                  centerBlock(context),
                  ...feedbackBlocks(context),
                  const Spacer(),
                  bottomButton(context)
                ]))));
      });

  @override
  Widget build(BuildContext context) {
    if (hasRemoteStats && isLoading && stats == null) return loadingView();
    if (hasRemoteStats && errorMessage != null && stats == null) return errorView();
    return content(context);
  }
}
