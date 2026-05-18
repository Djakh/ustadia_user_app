import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/practice/data/models/monkey_type_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_practices_bloc/monkey_type_practices_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_practices_bloc/monkey_type_practices_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_practices_bloc/monkey_type_practices_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class MonkeyTypePracticesPage extends StatefulWidget {
  const MonkeyTypePracticesPage({super.key});

  @override
  State<MonkeyTypePracticesPage> createState() => _MonkeyTypePracticesPageState();
}

class _MonkeyTypePracticesPageState extends State<MonkeyTypePracticesPage> {
  final MonkeyTypePracticesBloc practicesBloc = sl<MonkeyTypePracticesBloc>();

  @override
  void initState() {
    super.initState();
    practicesBloc.add(const MonkeyTypePracticesRequested());
  }

  @override
  void dispose() {
    practicesBloc.close();
    super.dispose();
  }

  void openPractice(MonkeyTypePracticeModel practice) {
    context.push(monkeyTypeSessionRoute, extra: practice);
  }

  Future<void> reloadPractices() async {
    practicesBloc.add(const MonkeyTypePracticesRequested());
  }

  Widget practiceCard(BuildContext context, MonkeyTypePracticeModel practice) => PrimaryBox(
      onTap: () => openPractice(practice),
      child: Row(children: [
        ClipRRect(
            borderRadius: Style.border12,
            child: Image.asset(AppImages.monkeyType, height: 56, width: 56, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(practice.title, style: Style.body2w5(context)),
          const SizedBox(height: 4),
          Text(practice.description, style: Style.small3w4(context, color: TextColorRole.greyColor))
        ]))
      ]));

  Widget practicesList(BuildContext context, List<MonkeyTypePracticeModel> practices) =>
      ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: practices.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => practiceCard(context, practices[index]));

  Widget get contentChecker => BlocStatusView<MonkeyTypePracticesBloc, MonkeyTypePracticesState,
          List<MonkeyTypePracticeModel>>(
      bloc: practicesBloc,
      statusOf: (s) => s.status,
      errorOf: (s) => s.errorMessage,
      data: (s) => s.practices,
      isEmpty: (practices) => practices.isEmpty,
      keepDataOnLoading: true,
      loading: const ShimmerList(
          itemCount: 5,
          itemHeight: 92,
          padding: EdgeInsets.symmetric(vertical: 12),
          borderRadius: BorderRadius.all(Radius.circular(20))),
      empty: Center(child: Text('No monkey type practices found'.tr())),
      builder: (context, practices) => practicesList(context, practices));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: 'Monkey Type'.tr(),
          child: RefreshIndicator(
              onRefresh: reloadPractices,
              child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                const SizedBox(height: 16),
                contentChecker,
                const SizedBox(height: 80),
              ]))));
}
