// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/router.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  /// --- Life cycle ---

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  /// --- Methods ---

  void goBack() => context.pop();

  void goToOtp() => context.push(otpRoute, extra: emailController.text);

  void onSignUp() => goToOtp();

  void goToLogin() => context.go(loginRoute);

  /// --- Widgets ---

  Widget get logo => Image.asset(AppImages.loginLogo, height: 50, width: 40);

  Widget get header => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Row(children: [
          IconButton(
              onPressed: goBack,
              icon: Icon(Icons.arrow_back_ios_new, color: context.cs.onSurface, size: 18)),
          const Spacer()
        ]),
        const SizedBox(height: 12),
        logo,
        const SizedBox(height: 16),
        Text('Create your account', style: Style.body2w6(context)),
        const SizedBox(height: 4),
        Text('It takes less than a minute.',
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget get form => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InputField.primary(controller: fullNameController, label: 'Full Name', hint: 'e.g. John Doe'),
        const SizedBox(height: 12),
        InputField.primary(
            controller: usernameController, label: 'Username', hint: 'e.g. @johndoe'),
        const SizedBox(height: 12),
        InputField.email(
            controller: emailController, label: 'Email', hint: 'e.g. name@example.com'),
        const SizedBox(height: 12),
        InputField.password(
            controller: passwordController,
            label: 'Password',
            hint: 'Must contain at least 6 characters'),
        const SizedBox(height: 12),
        InputField.password(
            controller: confirmController,
            label: 'Confirm Password',
            hint: 'Must contain at least 6 characters'),
      ]);

  Widget get footer => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Already have an account? ',
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        GestureDetector(
            onTap: goToLogin,
            child: Text('Log in', style: Style.small3w5(context, color: TextColorRole.onSurface)))
      ]);

  Widget get view => PrimaryBackground(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        const SizedBox(height: 28),
        form,
        const SizedBox(height: 20),
        Button.primary(onTap: onSignUp, text: 'Sign up'),
        const SizedBox(height: 16),
        footer
      ]));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
