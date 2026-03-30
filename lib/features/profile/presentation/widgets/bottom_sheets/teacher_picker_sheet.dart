import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/connection/reload_conntection_button.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/headers/primary_bottom_sheet_header.dart';
import 'package:ustadia_user_app/core/widgets/listviews/primary_list_view.dart';
import 'package:ustadia_user_app/features/common/data/models/teacher_model.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_state.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/dividers/primary_divider.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/core/widgets/app_restart.dart';
import 'package:ustadia_user_app/router.dart';

class TeacherPickerSheet extends StatefulWidget {
  final UserProfileModel userModel;
  const TeacherPickerSheet({super.key, required this.userModel});

  @override
  State<TeacherPickerSheet> createState() => _TeacherPickerSheetState();
}

class _TeacherPickerSheetState extends State<TeacherPickerSheet> {
  final TeacherModel systemTeacher = const TeacherModel(
      id: "",
      teacherId: null,
      firstName: "System",
      lastName: "lessons",
      teacherClass: TeacherClassModel(name: "Default"));
  TeacherModel? selectedTeacherModel;
  bool isLoading = false;
  List<TeacherModel> teachersList = [];

  /// --- Life cycle ---

  @override
  void initState() {
    selectedTeacherModel = getSelectedTeacher;
    teachersList = [systemTeacher, ...context.read<TeacherBloc>().state.teachers];
    super.initState();
  }

  /// --- Getters ---

  TeacherModel get getSelectedTeacher => widget.userModel.currentTeacher ?? systemTeacher;

  List<TeacherModel> teachersWithSystem(List<TeacherModel> teachers) {
    final hasSystemTeacher = teachers.any((teacher) => teacher.id == systemTeacher.id);
    if (hasSystemTeacher) return teachers;
    return [systemTeacher, ...teachers];
  }

  /// --- Listeners ---

  void teacherListener(context, TeacherState state) {
    if (state.status.isSuccess) {
      teachersList = teachersWithSystem(state.teachers);
    }
    if (state.swapStatus.isError && state.swapErrorMessage != null) {
      context.showSnackBar(SnackBar(content: Text(state.swapErrorMessage!)));
    }
    if (state.swapStatus.isSuccess) {
      Navigator.of(context).pop(true);
      final rootContext = rootNavigatorKey.currentContext;
      if (rootContext != null) AppRestart.restart(rootContext);
      appRouter.go(splashRoute);
    }
  }

  /// --- Methods ---

  void onSelectTeacherTile(TeacherModel teacher) {
    isLoading = true;
    setState(() {});
    selectedTeacherModel = teacher;

    context.read<TeacherBloc>().add(TeacherSwapRequested(teacherId: teacher.id));
  }

  /// --- Widgets ---

  Widget teacherTitle(TeacherModel teacher) {
    final fullName = teacher.fullName;
    final title = fullName.isNotEmpty ? fullName : teacher.email;
    return Text(title ?? "", style: Style.bodyw5(context));
  }

  Widget teacherSubtitle(TeacherModel teacher) {
    final className = teacher.teacherClass?.name ?? '';
    if (className.isEmpty) return const SizedBox.shrink();
    return Text(className, style: Style.small3w5(context, color: TextColorRole.greyColor));
  }

  Widget titleAndSubtitle(TeacherModel teacher) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        teacherTitle(teacher),
        const SizedBox(height: 4),
        teacherSubtitle(teacher),
        const SizedBox(height: 8),
        const PrimaryDivider()
      ]);

  Widget trailingIcon(bool isSelected) => Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppColors.primary : AppColors.gray300,
        size: 24,
      );

  Widget teacherTileBiew(TeacherModel teacher) => Row(children: [
        Expanded(child: titleAndSubtitle(teacher)),
        trailingIcon(selectedTeacherModel?.id == teacher.id),
      ]);

  Widget teacherTile(TeacherModel teacher) => InkWell(
      onTap: () => onSelectTeacherTile(teacher),
      borderRadius: Style.border16,
      child: Ink(child: teacherTileBiew(teacher)));

  PrimaryListView get teacherList => PrimaryListView(
      items: teachersList,
      padding: Style.paddingPrimary,
      shrinkWrap: true,
      separatorHeight: 4,
      onRefresh: () async {
        sl<TeacherBloc>().add(const TeachersRequested());
      },
      itemBuilder: (item) => teacherTile(item));

  Widget get contentChecker => BlocStatusView<TeacherBloc, TeacherState, List<TeacherModel>>(
        bloc: context.read<TeacherBloc>(),
        listener: teacherListener,
        statusOf: (s) => s.status,
        isCustomLoading: isLoading,
        errorOf: (s) => s.errorMessage,
        errorBuilder: (String error) => ReloadConntectionButton(
            onReloadConnection: () async =>
                context.read<TeacherBloc>().add(const TeachersRequested())),
        data: (s) => teachersWithSystem(s.teachers),
        isEmpty: (teachers) => teachers.isEmpty,
        empty: Center(child: Text('No teachers found'.tr())),
        builder: (context, teachers) {
          teachersList = teachers;
          return teacherList;
        },
      );

  Widget get view => Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryBottomSheetHeader(title: 'Choose teacher'.tr()),
        const SizedBox(height: 8),
        contentChecker
      ]);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: view);
}
