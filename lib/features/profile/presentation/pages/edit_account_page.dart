import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/services/firebase_messaging_service.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_state.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/profile_editable_avatar.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/settings_action_dialog.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => EditAccountPageState();
}

class EditAccountPageState extends State<EditAccountPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  late final UserBloc userBloc;
  late final FileUploadBloc imageUploadBloc;

  String? uploadedImageId;

  bool hasInitializedProfile = false;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    userBloc = context.read<UserBloc>();
    imageUploadBloc = context.read<FileUploadBloc>();
    if (userBloc.state.profile == null && userBloc.state.status != Status.loading) {
      userBloc.add(const UserProfileRequested());
    } else {
      applyProfile(userBloc.state.profile);
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    imageUploadBloc.close();
    super.dispose();
  }

  /// --- Listeners ---

  void imageListener(_, FileUploadState state) {
    if (state.status.isSuccess) {
      uploadedImageId = state.uploadedFile?.id;
      submitImageUpdate();
    }
    if (state.status.isError && state.errorMessage != null) {
      showSnackbar(state.errorMessage!);
    }
  }

  void userListener(context, UserState state) {
    if (state.status.isSuccess) {
      if (state.profile == null)
        logout();
      else
        applyProfile(state.profile);
    }

    if (state.status == Status.error && state.errorMessage != null) {
      showSnackbar(state.errorMessage!);
    }
  }

  /// --- Methods ---
  void showSnackbar(String text) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: Style.bodyw5(context, color: TextColorRole.whiteColor))));

  void applyProfile(UserProfileModel? profile) {
    if (profile == null) return;
    firstNameController.text = profile.firstName;
    lastNameController.text = profile.lastName;

    hasInitializedProfile = true;
  }

  void submit() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      showSnackbar('Please fill in all fields.');
      return;
    }

    userBloc.add(UserProfileUpdated(
        firstName: firstName, lastName: lastName, profilePictureId: uploadedImageId));
  }

  void submitImageUpdate() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) return;

    userBloc.add(UserProfileUpdated(
        firstName: firstName, lastName: lastName, profilePictureId: uploadedImageId));
  }

  void logout() async {
    final token = await FirebaseMessagingService.getToken();
    final deviceType = FirebaseMessagingService.deviceType();
    if (token != null && token.isNotEmpty) {
      try {
        await sl<UserRemoteDataSource>().unregisterDevice(
          token: token,
          deviceType: deviceType,
        );
      } catch (_) {}
    }
    await sl<AuthLocalDataSource>().clearAccessToken();
    if (!mounted) return;
    context.go(loginRoute);
  }

  void confirmDelete() {
    userBloc.add(const UserProfileDelete());
    Navigator.of(context).pop();
  }

  void showLogoutDialog() => showDialog(
      context: context,
      builder: (dialogContext) => SettingsActionDialog(
          iconAsset: AppImages.settingsRemove,
          title: 'Delete account?'.tr(),
          subtitle: 'This will permanently remove your data from Ustadia.'.tr(),
          actionText: 'Delete',
          onConfirm: confirmDelete));

  /// --- Widgets ---

  Button saveButton(bool isLoading) =>
      Button.primary(onTap: submit, text: 'Save'.tr(), isLoading: isLoading);

  Button removeButton(bool isLoading) => Button.border(
      onTap: showLogoutDialog,
      isLoading: isLoading,
      text: 'Delete account'.tr(),
      borderColor: context.cs.error,
      textColor: context.cs.error);

  Widget view(bool isLoading) => Column(children: [
        const SizedBox(height: 12),
        const ProfileEditableAvatar(radius: 60),
        const SizedBox(height: 24),
        InputField.primary(
            controller: firstNameController, label: 'First name'.tr(), hint: 'Enter first name'),
        const SizedBox(height: 12),
        InputField.primary(
            controller: lastNameController, label: 'Last name'.tr(), hint: 'Enter last name'),
        const SizedBox(height: 32),
        saveButton(isLoading),
        const Spacer(),
        removeButton(isLoading),
        const SizedBox(height: 16)
      ]);

  @override
  Widget build(BuildContext context) => MultiBlocListener(
          listeners: [
            BlocListener<UserBloc, UserState>(bloc: userBloc, listener: userListener),
            BlocListener<FileUploadBloc, FileUploadState>(
                bloc: imageUploadBloc, listener: imageListener)
          ],
          child: Scaffold(
            body: PrimaryBackground(
                title: 'Edit account'.tr(),
                child: BlocBuilder<UserBloc, UserState>(
                    bloc: userBloc, builder: (context, state) => view(state.status.isLoading))),
          ));
}
