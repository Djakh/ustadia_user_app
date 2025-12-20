// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  bool rememberMe = false;
  bool showError = false;

  /// --- Life cycle ---

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  /// --- Methods ---

  bool get isPhoneValid => phoneController.text.replaceAll(RegExp(r'\D'), '').length >= 9;

  void goToOtp() => context.push(otpRoute, extra: '+998 ${phoneController.text}');

  void goToSignup() => context.go(signUpRoute);

  void toggleRemember(bool value) => setState(() => rememberMe = value);

  void onLogin() {
    final valid = isPhoneValid;
    setState(() => showError = !valid);
    if (valid) goToOtp();
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
        Text('Remember me', style: Style.small2w4(context, color: TextColorRole.greyColor)),
        const Spacer(),
        TextButton(
            onPressed: () {}, child: Text('Forgot Password?', style: Style.small2w5(context)))
      ]);

  Widget get phoneTextField => InputField.phone(
      controller: phoneController,
      label: 'Phone number',
      errorText: showError ? 'Phone number is invalid.' : null,
      onChanged: (_) => setState(() => showError = false));

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
        phoneTextField,
        const SizedBox(height: 6),
        rememberRow,
        const SizedBox(height: 12),
        Button.primary(onTap: onLogin, text: 'Log in'),
        const SizedBox(height: 12),
        signup
      ]));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
