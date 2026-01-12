// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/core/validators/password_rules.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_register_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_register_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_register_state.dart';
import 'package:ustadia_user_app/features/auth/data/models/otp_verification_params.dart';
import 'package:ustadia_user_app/injection_container.dart';
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool passwordVisible = false;
  bool confirmVisible = false;
  bool showFullNameError = false;
  bool showUsernameError = false;
  bool showPhoneError = false;
  bool showEmailError = false;
  bool showPasswordError = false;
  bool showConfirmError = false;
  bool isEmailSignUp = false;
  final AuthRegisterBloc authRegisterBloc = sl<AuthRegisterBloc>();

  /// --- Life cycle ---

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    authRegisterBloc.close();
    super.dispose();
  }

  /// --- Methods ---

  void goBack() => context.pop();

  void goToOtp() => context.push(otpRoute,
      extra: isEmailSignUp ? emailController.text.trim() : '+998 ${phoneController.text}');

  void goToOtpWithTempId(String tempId) => context.push(otpRoute,
      extra: OtpVerificationParams(tempId: tempId, email: emailController.text.trim()));

  bool get isFullNameValid => fullNameController.text.trim().isNotEmpty;

  bool get isUsernameValid => usernameController.text.trim().isNotEmpty;

  bool get isPhoneValid => phoneController.text.replaceAll(RegExp(r'\D'), '').length == 9;
  bool get isEmailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailController.text.trim());
  String get fullPhoneNumber => '+998${phoneController.text.replaceAll(RegExp(r'\D'), '')}';

  bool get hasMinLength => PasswordRules.hasMinLength(passwordController.text);
  bool get hasUpper => PasswordRules.hasUpper(passwordController.text);
  bool get hasLower => PasswordRules.hasLower(passwordController.text);
  bool get hasNumber => PasswordRules.hasNumber(passwordController.text);
  bool get hasSymbol => PasswordRules.hasSymbol(passwordController.text);

  bool get isPasswordStrong => PasswordRules.isStrong(passwordController.text);

  bool get passwordsMatch =>
      passwordController.text.isNotEmpty && passwordController.text == confirmController.text;

  void onSignUp() {
    final fullNameValid = isFullNameValid;
    final usernameValid = isUsernameValid;
    final phoneValid = isEmailSignUp ? true : isPhoneValid;
    final emailValid = isEmailSignUp ? isEmailValid : true;
    final strong = isPasswordStrong;
    final match = passwordsMatch;
    setState(() {
      showFullNameError = !fullNameValid;
      showUsernameError = !usernameValid;
      showPhoneError = !phoneValid;
      showEmailError = !emailValid;
      showPasswordError = !strong;
      showConfirmError = !match;
    });
    if (fullNameValid && usernameValid && phoneValid && emailValid && strong && match) {
      if (isEmailSignUp) {
        authRegisterBloc.add(AuthRegisterWithEmailRequested(
            firstName: fullNameController.text.trim(),
            lastName: usernameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim()));
        return;
      }
      authRegisterBloc.add(AuthRegisterWithPhoneRequested(
          firstName: fullNameController.text.trim(),
          lastName: usernameController.text.trim(),
          phoneNumber: fullPhoneNumber,
          password: passwordController.text.trim()));
    }
  }

  void goToLogin() => context.go(loginRoute);

  void toggleSignUpMethod() => setState(() {
        isEmailSignUp = !isEmailSignUp;
        showPhoneError = false;
        showEmailError = false;
        showPasswordError = false;
        showConfirmError = false;
      });

  bool get isEmailFormValid =>
      isFullNameValid && isUsernameValid && isEmailValid && isPasswordStrong && passwordsMatch;
  bool get isPhoneFormValid =>
      isFullNameValid && isUsernameValid && isPhoneValid && isPasswordStrong && passwordsMatch;

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

  List<String> get passwordIssues => PasswordRules.issues(passwordController.text);

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
            onChanged: (value) => setState(() => showFullNameError = false)),
        const SizedBox(height: 12),
        InputField.primary(
            controller: usernameController,
            label: 'Username',
            hint: 'e.g. @johndoe',
            errorText: showUsernameError ? 'Username is required.' : null,
            onChanged: (value) => setState(() => showUsernameError = false)),
        const SizedBox(height: 12),
        if (!isEmailSignUp)
          InputField.phone(
              controller: phoneController,
              label: 'Phone number',
              errorText: showPhoneError ? 'Phone number is invalid.' : null,
              onChanged: (value) => setState(() => showPhoneError = false)),
        if (isEmailSignUp)
          InputField.email(
              controller: emailController,
              label: 'Email',
              hint: 'e.g. name@email.com',
              errorText: showEmailError ? 'Email is invalid.' : null,
              onChanged: (value) => setState(() => showEmailError = false)),
        const SizedBox(height: 12),
        InputField.password(
            controller: passwordController,
            label: 'Password',
            hint: 'Must contain at least 11 characters',
            obscure: !passwordVisible,
            showVisibilityToggle: true,
            onToggleVisibility: () => setState(() => passwordVisible = !passwordVisible),
            errorText: showPasswordError ? 'Password is not strong enough.' : null,
            onChanged: (value) => setState(() {
                  showPasswordError = false;
                  showConfirmError = false;
                })),
        if (showPasswordError) ...[const SizedBox(height: 8), passwordChecklist],
        const SizedBox(height: 12),
        InputField.password(
            controller: confirmController,
            label: 'Confirm Password',
            hint: 'Must contain at least 11 characters',
            obscure: !confirmVisible,
            showVisibilityToggle: true,
            onToggleVisibility: () => setState(() => confirmVisible = !confirmVisible),
            errorText: showConfirmError && confirmController.text.isNotEmpty
                ? 'Passwords do not match.'
                : null,
            onChanged: (value) => setState(() => showConfirmError = false)),
      ]);

  Widget get footer => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Already have an account? ',
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        GestureDetector(
            onTap: goToLogin,
            child: Text('Log in', style: Style.small3w5(context, color: TextColorRole.onSurface)))
      ]);

  BlocBuilder<AuthRegisterBloc, AuthRegisterState> signUpButton() =>
      BlocBuilder<AuthRegisterBloc, AuthRegisterState>(
          bloc: authRegisterBloc,
          builder: (context, state) => Button.primary(
              onTap: onSignUp,
              text: 'Sign up',
              isAvialable: state.status != Status.loading,
              isLoading: state.status == Status.loading));

  Widget get signUpMethodButton => Button.border(
      onTap: toggleSignUpMethod,
      text: isEmailSignUp ? 'Register with Phone' : 'Register with Email');

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
        signUpButton(),
        const SizedBox(height: 16),
        signUpMethodButton,
        const SizedBox(height: 16),
        footer
      ]));

  @override
  Widget build(BuildContext context) => BlocListener<AuthRegisterBloc, AuthRegisterState>(
      bloc: authRegisterBloc,
      listener: (context, state) {
        if (state.status == Status.success && state.tempId != null) {
          goToOtpWithTempId(state.tempId!);
          return;
        }
        if (state.status == Status.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(backgroundColor: context.cs.surface, body: view));
}
