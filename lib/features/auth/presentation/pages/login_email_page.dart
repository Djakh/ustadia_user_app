import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/router.dart';

class LoginEmailPage extends StatefulWidget {
  const LoginEmailPage({super.key});

  @override
  State<LoginEmailPage> createState() => LoginEmailPageState();
}

class LoginEmailPageState extends State<LoginEmailPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;

  /// --- Life cycle ---

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// --- Methods ---

  void goBack() => context.pop();

  void goToHome() => context.go(postsRoute);

  void toggleRemember(bool value) => setState(() => rememberMe = value);

  void onLogin() => goToHome();

  /// --- Widgets ---

  Widget get header => Row(children: [
        IconButton(
            onPressed: goBack,
            icon: Icon(Icons.arrow_back_ios_new, color: context.cs.onSurface, size: 18)),
        const Spacer(),
        Text('Login with Email', style: Style.bodyw6(context))
      ]);

  Widget get rememberRow => Row(children: [
        Checkbox(
            value: rememberMe,
            activeColor: context.cs.primary,
            onChanged: (value) => toggleRemember(value ?? false)),
        Text('Remember me', style: Style.small3w4(context)),
        const Spacer(),
        TextButton(
            onPressed: () {},
            child: Text('Forgot Password?',
                style: Style.small3w4(context, color: TextColorRole.greyColor)))
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                header,
                const SizedBox(height: 32),
                InputField.email(controller: emailController, label: 'Email'),
                const SizedBox(height: 16),
                InputField.password(controller: passwordController, label: 'Password'),
                const SizedBox(height: 8),
                rememberRow,
                const SizedBox(height: 18),
                Button.primary(onTap: onLogin, text: 'Log in')
              ]))));
}
