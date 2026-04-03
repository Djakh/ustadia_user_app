import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/validators/password_rules.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_state.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/auth/presentation/widgets/dialogs/auth_contact_type.dart';

class ResetPasswordDialog extends StatefulWidget {
  final AuthContactType contactType;
  final TextEditingController contactController;
  final TextEditingController otpController;
  final TextEditingController passwordController;
  final AuthPasswordBloc authPasswordBloc;
  final AuthPasswordAction loadingAction;
  final void Function(String contactValue, String otp, String newPassword) onSubmit;

  const ResetPasswordDialog(
      {super.key,
      required this.contactType,
      required this.contactController,
      required this.otpController,
      required this.passwordController,
      required this.authPasswordBloc,
      required this.loadingAction,
      required this.onSubmit});

  @override
  State<ResetPasswordDialog> createState() => ResetPasswordDialogState();
}

class ResetPasswordDialogState extends State<ResetPasswordDialog> {
  bool showContactError = false;
  bool showOtpError = false;
  bool showPasswordError = false;

  bool get isEmail => widget.contactType == AuthContactType.email;

  bool get isContactValid {
    if (isEmail) {
      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(widget.contactController.text.trim());
    }
    return widget.contactController.text.replaceAll(RegExp(r'\D'), '').length >= 9;
  }

  String get normalizedContact {
    if (isEmail) return widget.contactController.text.trim();
    final digits = widget.contactController.text.replaceAll(RegExp(r'\D'), '');
    return "+$digits";
  }

  void submit() {
    final isOtpValid = widget.otpController.text.trim().isNotEmpty;
    final isPasswordValid = PasswordRules.isStrong(widget.passwordController.text.trim());
    setState(() {
      showContactError = !isContactValid;
      showOtpError = !isOtpValid;
      showPasswordError = !isPasswordValid;
    });
    if (!isContactValid || !isOtpValid || !isPasswordValid) return;
    widget.onSubmit(
        normalizedContact, widget.otpController.text.trim(), widget.passwordController.text.trim());
  }

  Widget get contactField => isEmail
      ? InputField.email(
          controller: widget.contactController,
          label: 'Email'.tr(),
          hint: 'e.g. name@email.com'.tr(),
          readOnly: true,
          errorText: showContactError ? 'Email is invalid.'.tr() : null)
      : InputField.primary(
          controller: widget.contactController,
          label: 'Phone number'.tr(),
          readOnly: true,
          errorText: showContactError ? 'Phone number is invalid.'.tr() : null);

  Widget get passwordChecklist =>
      PasswordChecklist(issues: PasswordRules.issues(widget.passwordController.text));

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text('Reset password'.tr()),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            contactField,
            const SizedBox(height: 12),
            InputField.primary(
                controller: widget.otpController,
                label: 'OTP'.tr(),
                hint: 'Enter 6-digit OTP'.tr(),
                errorText: showOtpError ? 'OTP is required.'.tr() : null,
                onChanged: (value) => setState(() => showOtpError = false)),
            const SizedBox(height: 12),
            InputField.password(
                controller: widget.passwordController,
                label: 'New password'.tr(),
                hint: 'Enter new password'.tr(),
                obscure: true,
                errorText: showPasswordError ? 'Password is not strong enough.'.tr() : null,
                onChanged: (value) => setState(() => showPasswordError = false)),
            if (showPasswordError) passwordChecklist
          ]),
          actions: [
            BlocBuilder<AuthPasswordBloc, AuthPasswordState>(
                bloc: widget.authPasswordBloc,
                builder: (context, state) => Button.primary(
                    onTap: submit,
                    text: 'Reset password'.tr(),
                    isLoading:
                        state.status == Status.loading && state.action == widget.loadingAction))
          ]);
}

class PasswordChecklist extends StatelessWidget {
  final List<String> issues;

  const PasswordChecklist({super.key, required this.issues});

  Widget view(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: issues
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

  @override
  Widget build(BuildContext context) => view(context);
}
