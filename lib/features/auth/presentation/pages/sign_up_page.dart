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
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool passwordVisible = false;
  bool confirmVisible = false;
  bool showFullNameError = false;
  bool showUsernameError = false;
  bool showPhoneError = false;
  bool showPasswordError = false;
  bool showConfirmError = false;

  /// --- Life cycle ---

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  /// --- Methods ---

  void goBack() => context.pop();

  void goToOtp() => context.push(otpRoute, extra: '+998 ${phoneController.text}');

  bool get isFullNameValid => fullNameController.text.trim().isNotEmpty;

  bool get isUsernameValid => usernameController.text.trim().isNotEmpty;

  bool get isPhoneValid => phoneController.text.replaceAll(RegExp(r'\D'), '').length == 9;

  bool get hasMinLength => passwordController.text.length >= 12;
  bool get hasUpper => RegExp(r'[A-Z]').hasMatch(passwordController.text);
  bool get hasLower => RegExp(r'[a-z]').hasMatch(passwordController.text);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(passwordController.text);
  bool get hasSymbol => RegExp(r'[^A-Za-z0-9]').hasMatch(passwordController.text);

  bool get isPasswordStrong => hasMinLength && hasUpper && hasLower && hasNumber && hasSymbol;

  bool get passwordsMatch =>
      passwordController.text.isNotEmpty && passwordController.text == confirmController.text;

  void onSignUp() {
    final fullNameValid = isFullNameValid;
    final usernameValid = isUsernameValid;
    final phoneValid = isPhoneValid;
    final strong = isPasswordStrong;
    final match = passwordsMatch;
    setState(() {
      showFullNameError = !fullNameValid;
      showUsernameError = !usernameValid;
      showPhoneError = !phoneValid;
      showPasswordError = !strong;
      showConfirmError = !match;
    });
    if (fullNameValid && usernameValid && phoneValid && strong && match) goToOtp();
  }

  void goToLogin() => context.go(loginRoute);

  /// --- Widgets ---

  Widget get logo => Image.asset(AppImages.loginLogo, height: 50, width: 40);

  Widget rule(String text, bool met) => Row(children: [
        Icon(met ? Icons.check_circle : Icons.circle_outlined,
            size: 16, color: met ? context.cs.primary : context.cs.onTertiary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: Style.small3w4(context, color: TextColorRole.greyColor)
                    .copyWith(color: met ? context.cs.onSurface : context.cs.onTertiary)))
      ]);

  List<String> get passwordIssues {
    final issues = <String>[];
    if (!hasMinLength) issues.add('Use at least 12 characters.');
    if (!hasUpper) issues.add('Add at least one uppercase letter.');
    if (!hasLower) issues.add('Add at least one lowercase letter.');
    if (!hasNumber) issues.add('Add at least one number.');
    if (!hasSymbol) issues.add('Add at least one symbol.');
    return issues;
  }

  Widget get passwordChecklist => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: passwordIssues
          .map((issue) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(issue,
                        style: Style.small3w4(context, color: TextColorRole.greyColor)
                            .copyWith(color: Colors.red)))
              ])))
          .toList());

  Widget get form => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InputField.primary(
            controller: fullNameController,
            label: 'Full Name',
            hint: 'e.g. John Doe',
            errorText: showFullNameError ? 'Full name is required.' : null,
            onChanged: (_) => setState(() => showFullNameError = false)),
        const SizedBox(height: 12),
        InputField.primary(
            controller: usernameController,
            label: 'Username',
            hint: 'e.g. @johndoe',
            errorText: showUsernameError ? 'Username is required.' : null,
            onChanged: (_) => setState(() => showUsernameError = false)),
        const SizedBox(height: 12),
        InputField.phone(
            controller: phoneController,
            label: 'Phone number',
            errorText: showPhoneError ? 'Phone number is invalid.' : null,
            onChanged: (_) => setState(() => showPhoneError = false)),
        const SizedBox(height: 12),
        InputField.password(
            controller: passwordController,
            label: 'Password',
            hint: 'Must contain at least 12 characters',
            obscure: !passwordVisible,
            showVisibilityToggle: true,
            onToggleVisibility: () => setState(() => passwordVisible = !passwordVisible),
            errorText: showPasswordError ? 'Password is not strong enough.' : null,
            onChanged: (_) => setState(() {
                  showPasswordError = false;
                  showConfirmError = false;
                })),
        if (showPasswordError) ...[const SizedBox(height: 8), passwordChecklist],
        const SizedBox(height: 12),
        InputField.password(
            controller: confirmController,
            label: 'Confirm Password',
            hint: 'Must contain at least 12 characters',
            obscure: !confirmVisible,
            showVisibilityToggle: true,
            onToggleVisibility: () => setState(() => confirmVisible = !confirmVisible),
            errorText: showConfirmError && confirmController.text.isNotEmpty
                ? 'Passwords do not match.'
                : null,
            onChanged: (_) => setState(() => showConfirmError = false)),
      ]);

  Widget get footer => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Already have an account? ',
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        GestureDetector(
            onTap: goToLogin,
            child: Text('Log in', style: Style.small3w5(context, color: TextColorRole.onSurface)))
      ]);

  Widget get view => PrimaryBackground(
      isHeader: false,
      child: ListView(children: [
        const SizedBox(height: 12),
        logo,
        const SizedBox(height: 16),
        Text('Create your account', style: Style.body2w6(context)),
        const SizedBox(height: 4),
        Text('It takes less than a minute.',
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
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
