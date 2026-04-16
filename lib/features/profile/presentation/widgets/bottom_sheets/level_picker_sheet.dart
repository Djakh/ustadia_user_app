import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/app_restart.dart';
import 'package:ustadia_user_app/core/widgets/connection/reload_conntection_button.dart';
import 'package:ustadia_user_app/core/widgets/headers/primary_bottom_sheet_header.dart';
import 'package:ustadia_user_app/core/widgets/listviews/primary_list_view.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/profile/data/services/public_levels_store.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/dividers/primary_divider.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class LevelPickerSheet extends StatefulWidget {
  final UserProfileModel userModel;

  const LevelPickerSheet({super.key, required this.userModel});

  @override
  State<LevelPickerSheet> createState() => _LevelPickerSheetState();
}

class _LevelPickerSheetState extends State<LevelPickerSheet> {
  final UserRemoteDataSource userRemoteDataSource = sl<UserRemoteDataSource>();
  final PublicLevelsStore publicLevelsStore = sl<PublicLevelsStore>();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  List<UserLevelModel> levels = [];
  String? selectedLevelId;

  @override
  void initState() {
    super.initState();
    selectedLevelId = widget.userModel.level?.id ?? widget.userModel.levelId;
    loadLevels();
  }

  String get languageCode => widget.userModel.language;

  Future<void> loadLevels() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await publicLevelsStore.refreshIfNeeded();
      if (!mounted) return;
      setState(() => levels = publicLevelsStore.levels.value);
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> onSelectLevel(UserLevelModel level) async {
    if (isSaving || level.id.isEmpty || level.id == selectedLevelId) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(rootNavigatorKey.currentContext ?? context);
    setState(() {
      isSaving = true;
      selectedLevelId = level.id;
    });
    navigator.pop(true);
    try {
      await userRemoteDataSource.updateProfileLevel(levelId: level.id);
      await resetTeacherScopedData();
      AppRestart.restartFromNavigatorKey(rootNavigatorKey);
      appRouter.go(splashRoute);
    } catch (error) {
      messenger?.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget levelTitle(UserLevelModel level) =>
      Text(level.nameForLanguage(languageCode), style: Style.bodyw5(context));

  Widget levelSubtitle(UserLevelModel level) {
    final description = level.descriptionForLanguage(languageCode);
    if (description.isEmpty) return const SizedBox.shrink();
    return Text(description,
        style: Style.small3w5(context, color: TextColorRole.greyColor), maxLines: 2);
  }

  Widget titleAndSubtitle(UserLevelModel level) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        levelTitle(level),
        const SizedBox(height: 4),
        levelSubtitle(level),
        const SizedBox(height: 8),
        const PrimaryDivider()
      ]);

  Widget trailingIcon(bool isSelected) => Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppColors.primary : AppColors.gray300,
        size: 24,
      );

  Widget levelTile(UserLevelModel level) => InkWell(
      onTap: () => onSelectLevel(level),
      borderRadius: Style.border16,
      child: Ink(
          child: Row(children: [
        Expanded(child: titleAndSubtitle(level)),
        trailingIcon(selectedLevelId == level.id),
      ])));

  Widget get listView => PrimaryListView(
      items: levels,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      shrinkWrap: true,
      separatorHeight: 4,
      onRefresh: publicLevelsStore.refresh,
      itemBuilder: (item) => levelTile(item as UserLevelModel));

  Widget get body {
    if (isLoading) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()));
    }
    if (errorMessage != null) {
      return ReloadConntectionButton(onReloadConnection: loadLevels);
    }
    if (levels.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text('No data found'.tr())));
    }
    return Stack(children: [
      listView,
      if (isSaving)
        Positioned.fill(
            child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.08),
                child: const Center(child: CircularProgressIndicator())))
    ]);
  }

  Widget get view => Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryBottomSheetHeader(title: 'Choose level'.tr()),
        const SizedBox(height: 8),
        body
      ]);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(top: false, child: view));
}
