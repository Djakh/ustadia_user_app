// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
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
  bool rememberMe = false;
  bool showError = false;
  bool showEmailError = false;
  bool showPasswordError = false;
  bool isEmailLogin = false;
  bool passwordVisible = false;
  final AuthLoginBloc authLoginBloc = sl<AuthLoginBloc>();
  final AuthPasswordBloc authPasswordBloc = sl<AuthPasswordBloc>();
  final AuthLocalDataSource authLocalDataSource = sl<AuthLocalDataSource>();
  final UserBloc userBloc = sl<UserBloc>();
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
    authLoginBloc.close();
    authPasswordBloc.close();
    super.dispose();
  }

  /// --- Listeners ---

  void authPasswordListener(context, state) {
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

  void userListener(context, state) {
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

  void authLoginListener(context, state) {
    if (state.status == Status.success) {
      saveRememberedCredentials();
      isAwaitingUser = true;
      userBloc.add(const UserProfileRequested());
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

  void goToOtp() => context.push(otpRoute,
      extra: isEmailLogin ? emailController.text.trim() : '+998 ${phoneController.text}');

  void goToHome() => context.go(dashboardRoute);
  void goToIntroSurvey() => context.go(introSurveyRoute);

  void goToSignup() => context.go(signUpRoute);

  void toggleRemember(bool value) {
    setState(() => rememberMe = value);
    if (!value) authLocalDataSource.clearRememberedCredentials();
  }

  void onLogin() {
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

  void toggleLoginMethod() => setState(() {
        isEmailLogin = !isEmailLogin;
        showError = false;
        showEmailError = false;
        showPasswordError = false;
      });

  void loadRememberedCredentials() {
    final shouldRemember = authLocalDataSource.isRememberMeEnabled();
    if (!shouldRemember) return;
    final method = authLocalDataSource.getLastLoginMethod();
    final lastEmail = authLocalDataSource.getLastEmail();
    final lastPhone = authLocalDataSource.getLastPhone();
    final lastPassword = authLocalDataSource.getLastPassword();
    setState(() {
      rememberMe = true;
      isEmailLogin = method == 'email';
      if (isEmailLogin) {
        emailController.text = lastEmail;
      } else {
        phoneController.text = lastPhone;
      }
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
    await authLocalDataSource.setLastEmail(emailController.text.trim());
    await authLocalDataSource.setLastPhone(phoneController.text.trim());
    await authLocalDataSource.setLastPassword(passwordController.text.trim());
  }

  /// --- Showed Widgets ---

  Future<void> showForgotPasswordDialog(AuthContactType type) async {
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

  Widget get logo => Image.asset(AppImages.loginLogo, height: 50, width: 40);

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

  Widget get phoneTextField => InputField.phone(
      controller: phoneController,
      label: 'Phone number'.tr(),
      errorText: showError ? 'Phone number is invalid.' : null,
      onChanged: (value) => setState(() => showError = false));

  Widget get emailTextField => InputField.email(
      controller: emailController,
      label: 'Email'.tr(),
      hint: 'e.g. name@email.com',
      errorText: showEmailError ? 'Email is invalid.' : null,
      onChanged: (value) => setState(() => showEmailError = false));

  Widget get passwordField => InputField.password(
      controller: passwordController,
      label: 'Password'.tr(),
      hint: 'Enter your password',
      obscure: !passwordVisible,
      showVisibilityToggle: true,
      onToggleVisibility: () => setState(() => passwordVisible = !passwordVisible),
      errorText: showPasswordError ? 'Password is required.' : null,
      onChanged: (value) => setState(() => showPasswordError = false));

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
            child: Text('Sign up'.tr(), style: Style.small3w5(context, color: TextColorRole.onSurface)))
      ]);

  List<Widget> get fields => isEmailLogin
      ? [emailTextField, const SizedBox(height: 12), passwordField]
      : [phoneTextField, const SizedBox(height: 12), passwordField];

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
                    onTap: onLogin, text: 'Log in'.tr(), isLoading: state.status == Status.loading)),
            const SizedBox(height: 16),
            divider,
            const SizedBox(height: 16),
            BlocBuilder<AuthLoginBloc, AuthLoginState>(
                bloc: authLoginBloc,
                builder: (context, state) => Button.border(
                    onTap: toggleLoginMethod,
                    text: isEmailLogin ? 'Log in with Phone'.tr() : 'Log in with Email'.tr(),
                    isAvialable: state.status != Status.loading)),
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
