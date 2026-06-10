// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/connection/reload_conntection_button.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_state.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_state.dart';
import 'package:ustadia_user_app/features/auth/presentation/widgets/dialogs/auth_contact_type.dart';
import 'package:ustadia_user_app/features/auth/presentation/widgets/dialogs/forgot_password_dialog.dart';
import 'package:ustadia_user_app/features/auth/presentation/widgets/dialogs/reset_password_dialog.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final forgotPhoneController = TextEditingController();
  final forgotEmailController = TextEditingController();
  final resetPhoneController = TextEditingController();
  final resetEmailController = TextEditingController();
  final resetOtpController = TextEditingController();
  final resetPasswordController = TextEditingController();
  final phoneFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  bool rememberMe = false;
  bool showError = false;
  bool showEmailError = false;
  bool showPasswordError = false;
  bool isEmailLogin = false;
  bool passwordVisible = false;
  int authModeLogoTapCount = 0;
  final AuthLoginBloc authLoginBloc = sl<AuthLoginBloc>();
  final AuthPasswordBloc authPasswordBloc = sl<AuthPasswordBloc>();
  final AuthLocalDataSource authLocalDataSource = sl<AuthLocalDataSource>();
  late final UserBloc userBloc;
  bool isForgotDialogOpen = false;
  bool isResetDialogOpen = false;
  String resetEmail = '';
  String resetPhone = '';
  String pendingForgotEmail = '';
  String pendingForgotPhone = '';
  bool isAwaitingUser = false;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    userBloc = context.read<UserBloc>();
    loadRememberedCredentials();
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    forgotPhoneController.dispose();
    forgotEmailController.dispose();
    resetPhoneController.dispose();
    resetEmailController.dispose();
    resetOtpController.dispose();
    resetPasswordController.dispose();
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    authLoginBloc.close();
    authPasswordBloc.close();
    super.dispose();
  }

  /// --- Listeners ---

  void authPasswordListener(BuildContext context, AuthPasswordState state) {
    if (state.status == Status.success) {
      if (state.action == AuthPasswordAction.forgotPasswordEmail) {
        if (isForgotDialogOpen && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (pendingForgotEmail.isNotEmpty) {
          resetEmail = pendingForgotEmail;
          pendingForgotEmail = '';
        }
        if (isForgotDialogOpen && resetEmail.isNotEmpty) {
          showResetPasswordDialog(AuthContactType.email, resetEmail);
        }
      }
      if (state.action == AuthPasswordAction.resetPasswordEmail) {
        if (isResetDialogOpen && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      }
      if (state.action == AuthPasswordAction.forgotPasswordPhone) {
        if (isForgotDialogOpen && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (pendingForgotPhone.isNotEmpty) {
          resetPhone = pendingForgotPhone;
          pendingForgotPhone = '';
        }
        if (isForgotDialogOpen && resetPhone.isNotEmpty) {
          showResetPasswordDialog(AuthContactType.phone, resetPhone);
        }
      }
      if (state.action == AuthPasswordAction.resetPasswordPhone) {
        if (isResetDialogOpen && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      }
      return;
    }
    if (state.status == Status.error && state.errorMessage != null) {
      pendingForgotEmail = '';
      pendingForgotPhone = '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  void userListener(BuildContext context, UserState state) {
    if (mounted) setState(() {});
    if (!isAwaitingUser) return;
    if (state.status == Status.success) {
      isAwaitingUser = false;
      final profile = state.profile;
      if (profile != null && profile.introCompleted) {
        goToHome();
        return;
      }
      goToIntroSurvey();
    }
    if (state.status == Status.error && state.errorMessage != null) {
      isAwaitingUser = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  void authLoginListener(BuildContext context, AuthLoginState state) {
    if (mounted) setState(() {});
    if (state.status == Status.success) {
      hideKeyboard();
      saveRememberedCredentials();
      isAwaitingUser = true;
      userBloc.add(
          UserProfileRequested(preferredLanguage: Localizations.localeOf(context).languageCode));
      return;
    }
    if (state.status == Status.error && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  /// --- Methods ---

  bool get isPhoneValid => phoneController.text.replaceAll(RegExp(r'\D'), '').length >= 9;
  bool get isEmailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailController.text.trim());
  bool get isPasswordValid => passwordController.text.trim().isNotEmpty;
  String get fullPhoneNumber => '+998${phoneController.text.replaceAll(RegExp(r'\D'), '')}';

  void goToOtp() {
    hideKeyboard();
    context.push(otpRoute,
        extra: isEmailLogin ? emailController.text.trim() : '+998 ${phoneController.text}');
  }

  void goToHome() {
    hideKeyboard();
    context.go(dashboardRoute);
  }

  void goToIntroSurvey() {
    hideKeyboard();
    context.go(introSurveyRoute);
  }

  void goToSignup() {
    hideKeyboard();
    context.go(signUpRoute);
  }

  void toggleRemember(bool value) {
    setState(() => rememberMe = value);
    if (!value) authLocalDataSource.clearRememberedCredentials();
  }

  void onLogin() {
    hideKeyboard();
    if (isEmailLogin) {
      final emailValid = isEmailValid;
      final passwordValid = isPasswordValid;
      setState(() {
        showEmailError = !emailValid;
        showPasswordError = !passwordValid;
      });
      if (emailValid && passwordValid) loginWithEmail();
      return;
    }
    final phoneValid = isPhoneValid;
    final passwordValid = isPasswordValid;
    setState(() {
      showError = !phoneValid;
      showPasswordError = !passwordValid;
    });
    if (phoneValid && passwordValid) loginWithPhone();
  }

  void loginWithEmail() {
    if (authLoginBloc.state.status == Status.loading) return;
    authLoginBloc.add(AuthLoginWithEmailRequested(
        email: emailController.text.trim(), password: passwordController.text.trim()));
  }

  void loginWithPhone() {
    if (authLoginBloc.state.status == Status.loading) return;
    authLoginBloc.add(AuthLoginWithPhoneRequested(
        phoneNumber: fullPhoneNumber, password: passwordController.text.trim()));
  }

  void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  void toggleLoginMethod() {
    hideKeyboard();
    setState(() {
      isEmailLogin = !isEmailLogin;
      authModeLogoTapCount = 0;
      showError = false;
      showEmailError = false;
      showPasswordError = false;
    });
  }

  void onLogoTap() {
    authModeLogoTapCount++;
    if (authModeLogoTapCount < 6) return;
    toggleLoginMethod();
  }

  void loadRememberedCredentials() {
    final shouldRemember = authLocalDataSource.isRememberMeEnabled();
    if (!shouldRemember) return;
    final lastPhone = authLocalDataSource.getLastPhone();
    final lastEmail = authLocalDataSource.getLastEmail();
    final lastPassword = authLocalDataSource.getLastPassword();
    setState(() {
      rememberMe = true;
      isEmailLogin = false;
      phoneController.text = lastPhone;
      emailController.text = lastEmail;
      passwordController.text = lastPassword;
    });
  }

  Future<void> saveRememberedCredentials() async {
    if (!rememberMe) {
      await authLocalDataSource.clearRememberedCredentials();
      return;
    }
    await authLocalDataSource.setRememberMeEnabled(true);
    await authLocalDataSource.setLastLoginMethod(isEmailLogin ? 'email' : 'phone');
    await authLocalDataSource.setLastEmail(isEmailLogin ? emailController.text.trim() : '');
    await authLocalDataSource.setLastPhone(phoneController.text.trim());
    await authLocalDataSource.setLastPassword(passwordController.text.trim());
  }

  /// --- Showed Widgets ---

  Future<void> showForgotPasswordDialog(AuthContactType type) async {
    hideKeyboard();
    final controller =
        type == AuthContactType.email ? forgotEmailController : forgotPhoneController;
    controller.text =
        type == AuthContactType.email ? emailController.text.trim() : phoneController.text.trim();
    isForgotDialogOpen = true;
    await showDialog(
        context: context,
        builder: (dialogContext) => ForgotPasswordDialog(
            contactType: type,
            controller: controller,
            authPasswordBloc: authPasswordBloc,
            loadingAction: type == AuthContactType.email
                ? AuthPasswordAction.forgotPasswordEmail
                : AuthPasswordAction.forgotPasswordPhone,
            onSubmit: (value) {
              if (type == AuthContactType.email) {
                pendingForgotEmail = value;
                resetEmail = '';
                authPasswordBloc.add(AuthForgotPasswordRequested(email: value));
                return;
              }
              pendingForgotPhone = value;
              resetPhone = '';
              authPasswordBloc.add(AuthForgotPasswordPhoneRequested(phoneNumber: value));
            }));
    isForgotDialogOpen = false;
  }

  Future<void> showResetPasswordDialog(AuthContactType type, String contact) async {
    hideKeyboard();
    final contactController =
        type == AuthContactType.email ? resetEmailController : resetPhoneController;
    contactController.text = contact;
    resetOtpController.clear();
    resetPasswordController.clear();
    isResetDialogOpen = true;
    await showDialog(
        context: context,
        builder: (dialogContext) => ResetPasswordDialog(
            contactType: type,
            contactController: contactController,
            otpController: resetOtpController,
            passwordController: resetPasswordController,
            authPasswordBloc: authPasswordBloc,
            loadingAction: type == AuthContactType.email
                ? AuthPasswordAction.resetPasswordEmail
                : AuthPasswordAction.resetPasswordPhone,
            onSubmit: (contactValue, otp, newPassword) {
              if (type == AuthContactType.email) {
                authPasswordBloc.add(AuthResetPasswordRequested(
                    email: contactValue, otp: otp, newPassword: newPassword));
                return;
              }
              authPasswordBloc.add(AuthResetPasswordPhoneRequested(
                  phoneNumber: contactValue, otp: otp, newPassword: newPassword));
            }));
    isResetDialogOpen = false;
  }

  /// --- Widgets ---

  Widget get logo => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onLogoTap,
      child: SvgPicture.asset(AppImages.logo, height: 70, width: 70));

  Widget get rememberCheckBox => Checkbox(
      value: rememberMe,
      onChanged: (value) => toggleRemember(value ?? false),
      activeColor: context.cs.primary,
      shape: const CircleBorder(),
      side: const BorderSide(width: 0.6, color: AppColors.gray400));

  Widget get rememberRow => Row(children: [
        rememberCheckBox,
        Text('Remember me'.tr(), style: Style.small2w4(context, color: TextColorRole.greyColor))
      ]);

  Widget get rememberForgotRow => Row(children: [
        rememberCheckBox,
        Text('Remember me'.tr(), style: Style.small2w4(context, color: TextColorRole.greyColor)),
        const Spacer(),
        TextButton(
            onPressed: () => showForgotPasswordDialog(
                isEmailLogin ? AuthContactType.email : AuthContactType.phone),
            child: Text('Forgot Password?'.tr(), style: Style.small2w5(context)))
      ]);

  Widget get emailTextField => InputField.email(
      controller: emailController,
      focusNode: emailFocusNode,
      label: 'Email'.tr(),
      hint: 'example@mail.com',
      textInputAction: TextInputAction.next,
      errorText: showEmailError ? 'Email is invalid.'.tr() : null,
      onChanged: (value) => setState(() => showEmailError = false),
      onSubmitted: (_) => passwordFocusNode.requestFocus());

  Widget get phoneTextField => InputField.phone(
      controller: phoneController,
      focusNode: phoneFocusNode,
      label: 'Phone number'.tr(),
      textInputAction: TextInputAction.next,
      errorText: showError ? 'Phone number is invalid.'.tr() : null,
      onChanged: (value) => setState(() => showError = false),
      onSubmitted: (_) => passwordFocusNode.requestFocus());

  Widget get passwordField => InputField.password(
      controller: passwordController,
      focusNode: passwordFocusNode,
      label: 'Password'.tr(),
      hint: 'Enter your password'.tr(),
      textInputAction: TextInputAction.done,
      obscure: !passwordVisible,
      showVisibilityToggle: true,
      onToggleVisibility: () => setState(() => passwordVisible = !passwordVisible),
      errorText: showPasswordError ? 'Password is required.'.tr() : null,
      onChanged: (value) => setState(() => showPasswordError = false),
      onSubmitted: (_) => onLogin());

  Widget get divider => Row(children: [
        Expanded(child: Divider(color: context.cs.onTertiary.withValues(alpha: 0.4))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('or'.tr(), style: Style.small3w4(context, color: TextColorRole.greyColor))),
        Expanded(child: Divider(color: context.cs.onTertiary.withValues(alpha: 0.4)))
      ]);

  Widget get signup => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Don\'t have an account? '.tr(),
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        GestureDetector(
            onTap: goToSignup,
            child: Text('Sign up'.tr(),
                style: Style.small3w5(context, color: TextColorRole.onSurface)))
      ]);

  List<Widget> get fields => [
        if (isEmailLogin) emailTextField else phoneTextField,
        const SizedBox(height: 12),
        passwordField
      ];

  bool get hasConnectionIssue =>
      DioErrorMessage.isConnectionMessage(authLoginBloc.state.errorMessage) ||
      DioErrorMessage.isConnectionMessage(userBloc.state.errorMessage);

  bool get isAuthenticating =>
      authLoginBloc.state.status == Status.loading ||
      (isAwaitingUser && userBloc.state.status == Status.loading);

  Future<void> retryConnection() async {
    if (authLoginBloc.state.status == Status.success && isAwaitingUser) {
      userBloc.add(
          UserProfileRequested(preferredLanguage: Localizations.localeOf(context).languageCode));
      return;
    }
    onLogin();
  }

  Widget get reloadConnectionButton => hasConnectionIssue
      ? ReloadConntectionButton(onReloadConnection: retryConnection)
      : const SizedBox.shrink();

  Widget get view => PrimaryBackground(
      isHeader: false,
      isScrollable: true,
      child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 12),
            logo,
            const SizedBox(height: 24),
            Text('Welcome back'.tr(), style: Style.headlinew7(context)),
            const SizedBox(height: 4),
            Text('Good to see you again.'.tr(),
                style: Style.small3w4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 40),
            ...fields,
            const SizedBox(height: 6),
            rememberForgotRow,
            const SizedBox(height: 12),
            BlocBuilder<AuthLoginBloc, AuthLoginState>(
                bloc: authLoginBloc,
                builder: (context, state) => Button.primary(
                    onTap: onLogin, text: 'Log in'.tr(), isLoading: isAuthenticating)),
            if (hasConnectionIssue) ...[
              const SizedBox(height: 12),
              reloadConnectionButton,
            ],
            const SizedBox(height: 16),
            signup
          ])));

  @override
  Widget build(BuildContext context) => MultiBlocListener(listeners: [
        BlocListener<AuthLoginBloc, AuthLoginState>(
            bloc: authLoginBloc, listener: authLoginListener),
        BlocListener<UserBloc, UserState>(bloc: userBloc, listener: userListener),
        BlocListener<AuthPasswordBloc, AuthPasswordState>(
            bloc: authPasswordBloc, listener: authPasswordListener)
      ], child: Scaffold(backgroundColor: context.cs.surface, body: view));
}
