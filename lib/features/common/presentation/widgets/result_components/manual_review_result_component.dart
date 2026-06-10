import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_stats_model.dart';

class ManualReviewResultComponent extends StatelessWidget {
  final SectionModel sectionModel;
  final SectionStatsModel? stats;
  final String? aiFeedback;
  final String? feedback;

  const ManualReviewResultComponent(
      {super.key, required this.sectionModel, this.stats, this.aiFeedback, this.feedback});

  int get pending => stats?.pending ?? answered;
  int get answered => stats?.answeredQuestions ?? sectionModel.answeredQuestions ?? 1;
  bool get hasPendingReview => pending > 0;
  bool get isSpeaking => sectionModel.sectionType == SectionType.speaking;

  void backToTopic(BuildContext context) => context.pop(true);

  String get title => hasPendingReview ? 'Pending review' : 'Review completed';

  String get description {
    if (hasPendingReview) {
      return isSpeaking
          ? 'Your speaking responses have been submitted and are awaiting evaluation.'
          : 'Your writing response has been submitted and is awaiting evaluation.';
    }
    return 'Your submitted work has been reviewed.';
  }

  Widget statusIcon(BuildContext context) => Container(
      width: 112,
      height: 112,
      decoration: const BoxDecoration(
          color: AppColors.orangeEB,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 8))]),
      child: Icon(hasPendingReview ? Icons.schedule_rounded : Icons.rate_review_rounded,
          color: hasPendingReview ? AppColors.orange033 : AppColors.primary, size: 54));

  Widget infoRow(BuildContext context,
          {required String title, required String subtitle, required IconData icon}) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.orangeEB, borderRadius: Style.border12),
            child: Icon(icon, color: AppColors.orange033, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.tr(), style: Style.bodyw6(context)),
          const SizedBox(height: 4),
          Text(subtitle.tr(), style: Style.small2w4(context, color: TextColorRole.greyColor))
        ]))
      ]);

  Widget reviewInfoBox(BuildContext context) => Container(
      padding: Style.paddingAll16,
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: Style.border20,
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Column(children: [
        infoRow(context,
            title: 'Submission received',
            subtitle: isSpeaking
                ? 'Your audio response was saved successfully.'
                : 'Your writing response was saved successfully.',
            icon: Icons.cloud_done_rounded),
        const SizedBox(height: 16),
        infoRow(context,
            title: hasPendingReview ? 'Awaiting evaluation' : 'Evaluation completed',
            subtitle: hasPendingReview
                ? 'Your score and feedback will appear after review.'
                : 'Your score and feedback are ready to view.',
            icon: hasPendingReview ? Icons.schedule_rounded : Icons.rate_review_rounded),
      ]));

  Widget feedbackBox(BuildContext context, String title, String text) => Container(
      width: double.infinity,
      padding: Style.paddingAll16,
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.feedback_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title.tr(), style: Style.bodyw5(context)),
        ]),
        const SizedBox(height: 12),
        Text(text, style: Style.small2w4(context)),
      ]));

  List<Widget> feedbackBlocks(BuildContext context) {
    final blocks = <Widget>[];
    if (feedback != null && feedback!.trim().isNotEmpty) {
      blocks.add(feedbackBox(context, 'Feedback', feedback!));
      blocks.add(const SizedBox(height: 16));
    }
    if (aiFeedback != null && aiFeedback!.trim().isNotEmpty) {
      blocks.add(feedbackBox(context, 'AI feedback', aiFeedback!));
      blocks.add(const SizedBox(height: 16));
    }
    return blocks;
  }

  Widget content(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 60),
                child: IntrinsicHeight(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Spacer(),
                  statusIcon(context),
                  const SizedBox(height: 18),
                  Text(title.tr(), style: Style.body3w7(context), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(description.tr(),
                      style: Style.small2w3(context, color: TextColorRole.greyColor),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  reviewInfoBox(context),
                  const SizedBox(height: 24),
                  ...feedbackBlocks(context),
                  const Spacer(),
                  Button.primary(
                      onTap: () => backToTopic(context),
                      text: 'Continue'.tr(),
                      color: hasPendingReview ? AppColors.orange033 : AppColors.primary)
                ]))));
      });

  @override
  Widget build(BuildContext context) => content(context);
}
