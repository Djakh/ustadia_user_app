// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_state.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_state.dart';
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
  final forgotEmailController = TextEditingController();
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
  bool isForgotDialogOpen = false;
  bool isResetDialogOpen = false;
  String resetEmail = '';
  String pendingForgotEmail = '';

  /// --- Life cycle ---

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    forgotEmailController.dispose();
    resetEmailController.dispose();
    resetOtpController.dispose();
    resetPasswordController.dispose();
    authLoginBloc.close();
    authPasswordBloc.close();
    super.dispose();
  }

  /// --- Methods ---

  bool get isPhoneValid => phoneController.text.replaceAll(RegExp(r'\D'), '').length >= 9;
  bool get isEmailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailController.text.trim());
  bool get isPasswordValid => passwordController.text.trim().isNotEmpty;

  void goToOtp() => context.push(otpRoute,
      extra: isEmailLogin ? emailController.text.trim() : '+998 ${phoneController.text}');

  void goToHome() => context.go(dashboardRoute);

  void goToSignup() => context.go(signUpRoute);

  void toggleRemember(bool value) => setState(() => rememberMe = value);

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
    setState(() => showError = !phoneValid);
    if (phoneValid) goToOtp();
  }

  void loginWithEmail() {
    if (authLoginBloc.state.status == AuthLoginStatus.loading) return;
    authLoginBloc.add(AuthLoginWithEmailRequested(
        email: emailController.text.trim(), password: passwordController.text.trim()));
  }

  void toggleLoginMethod() => setState(() {
        isEmailLogin = !isEmailLogin;
        showError = false;
        showEmailError = false;
        showPasswordError = false;
      });

  Future<void> showForgotPasswordDialog() async {
    bool showDialogEmailError = false;
    forgotEmailController.text = emailController.text.trim();
    isForgotDialogOpen = true;
    await showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                    title: const Text('Forgot password'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      InputField.email(
                          controller: forgotEmailController,
                          label: 'Email',
                          hint: 'e.g. name@email.com',
                          errorText: showDialogEmailError ? 'Email is invalid.' : null,
                          onChanged: (value) => setState(() => showDialogEmailError = false))
                    ]),
                    actions: [
                      BlocBuilder<AuthPasswordBloc, AuthPasswordState>(
                          bloc: authPasswordBloc,
                          builder: (context, state) => Button.primary(
                              onTap: () {
                                final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(forgotEmailController.text.trim());
                                if (!isValid) {
                                  setState(() => showDialogEmailError = true);
                                  return;
                                }
                                pendingForgotEmail = forgotEmailController.text.trim();
                                resetEmail = '';
                                authPasswordBloc
                                    .add(AuthForgotPasswordRequested(email: pendingForgotEmail));
                              },
                              text: 'Send OTP',
                              isLoading: state.status == AuthPasswordStatus.loading &&
                                  state.action == AuthPasswordAction.forgotPassword))
                    ])));
    isForgotDialogOpen = false;
  }

  Future<void> showResetPasswordDialog(String email) async {
    bool showDialogEmailError = false;
    bool showOtpError = false;
    bool showPasswordError = false;
    resetEmailController.text = email;
    resetOtpController.clear();
    resetPasswordController.clear();
    isResetDialogOpen = true;
    await showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                    title: const Text('Reset password'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      InputField.email(
                          controller: resetEmailController,
                          label: 'Email',
                          hint: 'e.g. name@email.com',
                          errorText: showDialogEmailError ? 'Email is invalid.' : null,
                          onChanged: (value) => setState(() => showDialogEmailError = false)),
                      const SizedBox(height: 12),
                      InputField.primary(
                          controller: resetOtpController,
                          label: 'OTP',
                          hint: 'Enter 6-digit OTP',
                          errorText: showOtpError ? 'OTP is required.' : null,
                          onChanged: (value) => setState(() => showOtpError = false)),
                      const SizedBox(height: 12),
                      InputField.password(
                          controller: resetPasswordController,
                          label: 'New password',
                          hint: 'Enter new password',
                          obscure: true,
                          errorText: showPasswordError ? 'Password is required.' : null,
                          onChanged: (value) => setState(() => showPasswordError = false))
                    ]),
                    actions: [
                      BlocBuilder<AuthPasswordBloc, AuthPasswordState>(
                          bloc: authPasswordBloc,
                          builder: (context, state) => Button.primary(
                              onTap: () {
                            final isEmailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(resetEmailController.text.trim());
                            final otpValid = resetOtpController.text.trim().isNotEmpty;
                            final passwordValid = resetPasswordController.text.trim().isNotEmpty;
                                setState(() {
                                  showDialogEmailError = !isEmailValid;
                                  showOtpError = !otpValid;
                                  showPasswordError = !passwordValid;
                                });
                            if (!isEmailValid || !otpValid || !passwordValid) return;
                            authPasswordBloc.add(AuthResetPasswordRequested(
                                email: resetEmailController.text.trim(),
                                otp: resetOtpController.text.trim(),
                                newPassword: resetPasswordController.text.trim()));
                          },
                              text: 'Reset password',
                              isLoading: state.status == AuthPasswordStatus.loading &&
                                  state.action == AuthPasswordAction.resetPassword))
                    ])));
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
        Text('Remember me', style: Style.small2w4(context, color: TextColorRole.greyColor))
      ]);

  Widget get rememberForgotRow => Row(children: [
        rememberCheckBox,
        Text('Remember me', style: Style.small2w4(context, color: TextColorRole.greyColor)),
        const Spacer(),
        TextButton(
            onPressed: showForgotPasswordDialog,
            child: Text('Forgot Password?', style: Style.small2w5(context)))
      ]);

  Widget get phoneTextField => InputField.phone(
      controller: phoneController,
      label: 'Phone number',
      errorText: showError ? 'Phone number is invalid.' : null,
      onChanged: (value) => setState(() => showError = false));

  Widget get emailTextField => InputField.email(
      controller: emailController,
      label: 'Email',
      hint: 'e.g. name@email.com',
      errorText: showEmailError ? 'Email is invalid.' : null,
      onChanged: (value) => setState(() => showEmailError = false));

  Widget get passwordField => InputField.password(
      controller: passwordController,
      label: 'Password',
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
            child: Text('or', style: Style.small3w4(context, color: TextColorRole.greyColor))),
        Expanded(child: Divider(color: context.cs.onTertiary.withValues(alpha: 0.4)))
      ]);

  Widget get signup => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Don\'t have an account? ',
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        GestureDetector(
            onTap: goToSignup,
            child: Text('Sign up', style: Style.small3w5(context, color: TextColorRole.onSurface)))
      ]);

  List<Widget> get fields =>
      isEmailLogin ? [emailTextField, const SizedBox(height: 12), passwordField] : [phoneTextField];

  Widget get view => PrimaryBackground(
      isHeader: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const SizedBox(height: 12),
        logo,
        const SizedBox(height: 24),
        Text('Welcome back', style: Style.headlinew7(context)),
        const SizedBox(height: 4),
        Text('Good to see you again.',
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 40),
        ...fields,
        const SizedBox(height: 6),
        if (isEmailLogin) rememberForgotRow,
        if (!isEmailLogin) rememberRow,
        const SizedBox(height: 12),
        BlocBuilder<AuthLoginBloc, AuthLoginState>(
            bloc: authLoginBloc,
            builder: (context, state) => Button.primary(
                onTap: onLogin,
                text: 'Log in',
                isLoading: state.status == AuthLoginStatus.loading)),
        const SizedBox(height: 16),
        divider,
        const SizedBox(height: 16),
        BlocBuilder<AuthLoginBloc, AuthLoginState>(
            bloc: authLoginBloc,
            builder: (context, state) => Button.border(
                onTap: toggleLoginMethod,
                text: isEmailLogin ? 'Log in with Phone' : 'Log in with Email',
                isAvialable: state.status != AuthLoginStatus.loading)),
        const SizedBox(height: 16),
        signup
      ]));

  @override
  Widget build(BuildContext context) => MultiBlocListener(listeners: [
        BlocListener<AuthLoginBloc, AuthLoginState>(
            bloc: authLoginBloc,
            listener: (context, state) {
              if (state.status == AuthLoginStatus.success) {
                goToHome();
                return;
              }
              if (state.status == AuthLoginStatus.failure && state.errorMessage != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            }),
        BlocListener<AuthPasswordBloc, AuthPasswordState>(
            bloc: authPasswordBloc,
            listener: (context, state) {
              if (state.status == AuthPasswordStatus.success) {
                if (state.action == AuthPasswordAction.forgotPassword) {
                  if (isForgotDialogOpen && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  if (state.message != null && state.message!.isNotEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.message!)));
                  }
                  if (pendingForgotEmail.isNotEmpty) {
                    resetEmail = pendingForgotEmail;
                    pendingForgotEmail = '';
                  }
                  if (isForgotDialogOpen && resetEmail.isNotEmpty) {
                    showResetPasswordDialog(resetEmail);
                  }
                }
                if (state.action == AuthPasswordAction.resetPassword) {
                  if (isResetDialogOpen && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  if (state.message != null && state.message!.isNotEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.message!)));
                  }
                }
                return;
              }
              if (state.status == AuthPasswordStatus.failure && state.errorMessage != null) {
                pendingForgotEmail = '';
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            })
      ], child: Scaffold(backgroundColor: context.cs.surface, body: view));
}
