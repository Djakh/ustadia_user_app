import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_attempt_model.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class MockExamHistoryPage extends StatefulWidget {
  const MockExamHistoryPage({super.key});

  @override
  State<MockExamHistoryPage> createState() => MockExamHistoryPageState();
}

class MockExamHistoryPageState extends State<MockExamHistoryPage> {
  late Future<List<MockExamHistoryModel>> historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = fetchHistory();
  }

  Future<List<MockExamHistoryModel>> fetchHistory() =>
      sl<MockExamRemoteDataSource>().fetchAllMockExamHistory();

  Future<void> refreshHistory() async {
    setState(() => historyFuture = fetchHistory());
    await historyFuture;
  }

  void openResult(MockExamHistoryModel item) {
    if (item.mockExamId.isEmpty || item.attemptId.isEmpty) return;
    context.push(mockExamResultRoute(item.mockExamId, item.attemptId), extra: item);
  }

  String scoreLabel(num? score) => score?.toString() ?? 'Pending'.tr();

  String dateLabel(DateTime? date) => date?.toLocal().toString().split('.').first ?? '-';

  Widget scoreBadge(BuildContext context, MockExamHistoryModel item) => Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(color: AppColors.greenE7, borderRadius: Style.border16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(scoreLabel(item.overallBand),
            style: Style.bodyw7(context).copyWith(color: AppColors.green36)),
        Text('Band'.tr(), style: Style.small2w4(context).copyWith(color: AppColors.green3B))
      ]));

  Widget skillScores(BuildContext context, MockExamHistoryModel item) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        skillChip(context, 'L', item.listeningBand, AppColors.blueD3),
        skillChip(context, 'R', item.readingBand, AppColors.orange12),
        skillChip(context, 'W', item.writingBand, AppColors.purpleD6),
        skillChip(context, 'S', item.speakingBand, AppColors.green36)
      ]);

  Widget skillChip(BuildContext context, String title, num? score, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: Style.border8),
      child: Text('$title ${scoreLabel(score)}',
          style: Style.small2w5(context).copyWith(color: color)));

  Widget historyTile(BuildContext context, MockExamHistoryModel item) => InkWell(
      onTap: () => openResult(item),
      borderRadius: Style.border20,
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: Style.border20,
              border: Border.all(color: AppColors.gray100),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
              ]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            scoreBadge(context, item),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.mockExamTitle.isEmpty ? 'Mock exam'.tr() : item.mockExamTitle,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: Style.bodyw6(context)),
              const SizedBox(height: 5),
              Text(dateRange(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Style.small2w4(context, color: TextColorRole.greyColor)),
              const SizedBox(height: 10),
              skillScores(context, item)
            ])),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.gray400)
          ])));

  String dateRange(MockExamHistoryModel item) =>
      '${dateLabel(item.startedAt)} - ${dateLabel(item.finishedAt)}';

  Widget historyList(List<MockExamHistoryModel> history) {
    if (history.isEmpty) return Center(child: Text('No history yet'.tr()));
    return RefreshIndicator(
        onRefresh: refreshHistory,
        child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Style.paddingPrimary,
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => historyTile(context, history[index])));
  }

  Widget errorContent(Object? error) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error?.toString() ?? 'Request failed. Please try again.'.tr(),
              textAlign: TextAlign.center)));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: 'History'.tr(),
          isScrollable: false,
          child: FutureBuilder<List<MockExamHistoryModel>>(
              future: historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: PrimaryLoadingIndicator());
                }
                if (snapshot.hasError) return errorContent(snapshot.error);
                return historyList(snapshot.data ?? const []);
              })));
}
