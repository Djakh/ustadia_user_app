import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_attempt_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_list_bloc/mock_exam_list_bloc.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_list_bloc/mock_exam_list_event.dart';
import 'package:ustadia_user_app/injection_container.dart';

class MockExamResultPage extends StatefulWidget {
  final String mockExamId;
  final String attemptId;
  final MockExamModel? exam;
  final String? titleOverride;

  const MockExamResultPage(
      {super.key,
      required this.mockExamId,
      required this.attemptId,
      this.exam,
      this.titleOverride});

  @override
  State<MockExamResultPage> createState() => MockExamResultPageState();
}

class MockExamResultPageState extends State<MockExamResultPage> {
  late Future<MockExamResultModel> resultFuture;

  @override
  void initState() {
    super.initState();
    resultFuture = fetchResult();
    resultFuture.then((_) => refreshMockExamList());
  }

  void refreshMockExamList() {
    if (!sl.isRegistered<MockExamListBloc>()) return;
    sl<MockExamListBloc>().add(const MockExamListRequested());
  }

  Future<MockExamResultModel> fetchResult() => sl<MockExamRemoteDataSource>()
      .fetchMockExamResult(mockExamId: widget.mockExamId, attemptId: widget.attemptId);

  Future<void> refreshResult() async {
    setState(() => resultFuture = fetchResult());
    await resultFuture;
  }

  String get title {
    if (widget.titleOverride?.isNotEmpty == true) return widget.titleOverride!;
    final examTitle = widget.exam?.title ?? '';
    if (examTitle.isNotEmpty) return examTitle;
    return 'Result'.tr();
  }

  String scoreLabel(num? score) => score?.toString() ?? 'Pending'.tr();

  String dateLabel(DateTime? date) => date?.toLocal().toString().split('.').first ?? '-';

  String spendingTimeLabel(MockExamResultModel result) {
    final startedAt = result.startedAt;
    final finishedAt = result.finishedAt;
    if (startedAt == null || finishedAt == null) return '-';
    final duration = finishedAt.difference(startedAt);
    if (duration.inMinutes < 1) {
      return '{count} sec'.tr(namedArgs: {'count': '${duration.inSeconds}'});
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '{count} min'.tr(namedArgs: {'count': '$minutes'});
    return '{hours} h {minutes} min'.tr(namedArgs: {'hours': '$hours', 'minutes': '$minutes'});
  }

  Widget overallScoreCard(BuildContext context, MockExamResultModel result) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: AppColors.greenE7,
          borderRadius: Style.border24,
          border: Border.all(color: AppColors.greenC6),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.white, size: 24)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Overall'.tr(), style: Style.bodyw6(context).copyWith(color: AppColors.green36)),
            const SizedBox(height: 2),
            Text('Total score'.tr(),
                style: Style.small2w4(context).copyWith(color: AppColors.green3B))
          ]))
        ]),
        const SizedBox(height: 22),
        Text(scoreLabel(result.overallBand),
            style: Style.headline5w7(context).copyWith(color: AppColors.green36)),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.timer_outlined, size: 18, color: AppColors.green3B),
          const SizedBox(width: 6),
          Text('Spending time'.tr(),
              style: Style.small2w4(context).copyWith(color: AppColors.green3B)),
          const Spacer(),
          Text(spendingTimeLabel(result),
              style: Style.small2w5(context).copyWith(color: AppColors.green36))
        ])
      ]));

  Widget scoreBox(BuildContext context, String title, num? score, Color background, Color accent) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: background,
              borderRadius: Style.border20,
              border: Border.all(color: accent.withValues(alpha: 0.18)),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
              ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Style.small2w5(context).copyWith(color: accent)),
            const Spacer(),
            Text(scoreLabel(score), style: Style.body3w7(context).copyWith(color: accent)),
            const SizedBox(height: 8),
            Text('Band score'.tr(), style: Style.small2w4(context).copyWith(color: accent))
          ]));

  Widget skillScoresGrid(BuildContext context, MockExamResultModel result) => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.28,
          children: [
            scoreBox(context, 'Listening'.tr(), result.listeningBand, AppColors.blueFF,
                AppColors.blueD3),
            scoreBox(context, 'Reading'.tr(), result.readingBand, AppColors.orangeEB,
                AppColors.orange12),
            scoreBox(context, 'Writing'.tr(), result.writingBand, AppColors.purpleFF,
                AppColors.purpleD6),
            scoreBox(
                context, 'Speaking'.tr(), result.speakingBand, AppColors.greenE7, AppColors.green36)
          ]);

  Widget infoCard(BuildContext context, MockExamResultModel result) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: Style.border20,
          border: Border.all(color: AppColors.gray100)),
      child: Column(children: [
        infoRow(context, 'Grading status'.tr(),
            result.gradingStatus.isEmpty ? 'Pending'.tr() : result.gradingStatus.tr()),
        const SizedBox(height: 10),
        infoRow(context, 'Started at'.tr(), dateLabel(result.startedAt)),
        const SizedBox(height: 10),
        infoRow(context, 'Finished at'.tr(), dateLabel(result.finishedAt))
      ]));

  Widget infoRow(BuildContext context, String title, String value) => Row(children: [
        Expanded(
            child: Text(title, style: Style.small2w4(context, color: TextColorRole.greyColor))),
        Text(value, style: Style.small2w5(context))
      ]);

  Widget resultContent(BuildContext context, MockExamResultModel result) => RefreshIndicator(
      onRefresh: refreshResult,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
        const SizedBox(height: 16),
        overallScoreCard(context, result),
        const SizedBox(height: 16),
        infoCard(context, result),
        const SizedBox(height: 20),
        Text('Skill scores'.tr(), style: Style.bodyw6(context)),
        const SizedBox(height: 12),
        skillScoresGrid(context, result),
        if (result.feedback.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(result.feedback, style: Style.bodyw4(context))
        ],
        const SizedBox(height: 80)
      ]));

  Widget errorContent(BuildContext context, Object? error) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error?.toString() ?? 'Request failed. Please try again.'.tr(),
              textAlign: TextAlign.center)));

  @override
  Widget build(BuildContext context) => Scaffold(
      key: const ValueKey('mock_exam_result_page'),
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: title,
          isScrollable: false,
          child: FutureBuilder<MockExamResultModel>(
              future: resultFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: PrimaryLoadingIndicator());
                }
                if (snapshot.hasError) return errorContent(context, snapshot.error);
                final result = snapshot.data;
                if (result == null) return errorContent(context, null);
                return resultContent(context, result);
              })));
}
