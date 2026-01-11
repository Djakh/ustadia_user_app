import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_state.dart';
import 'package:ustadia_user_app/features/auth/presentation/widgets/dialogs/auth_contact_type.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final AuthContactType contactType;
  final TextEditingController controller;
  final AuthPasswordBloc authPasswordBloc;
  final AuthPasswordAction loadingAction;
  final void Function(String value) onSubmit;

  const ForgotPasswordDialog(
      {super.key,
      required this.contactType,
      required this.controller,
      required this.authPasswordBloc,
      required this.loadingAction,
      required this.onSubmit});

  @override
  State<ForgotPasswordDialog> createState() => ForgotPasswordDialogState();
}

class ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  bool showError = false;

  bool get isEmail => widget.contactType == AuthContactType.email;

  bool get isValid {
    if (isEmail) {
      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
          .hasMatch(widget.controller.text.trim());
    }
    return widget.controller.text.replaceAll(RegExp(r'\D'), '').length >= 9;
  }

  String get normalizedValue {
    if (isEmail) return widget.controller.text.trim();
    final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    return '+998$digits';
  }

  void submit() {
    if (!isValid) {
      setState(() => showError = true);
      return;
    }
    widget.onSubmit(normalizedValue);
  }

  Widget get inputField => isEmail
      ? InputField.email(
          controller: widget.controller,
          label: 'Email',
          hint: 'e.g. name@email.com',
          errorText: showError ? 'Email is invalid.' : null,
          onChanged: (value) => setState(() => showError = false))
      : InputField.phone(
          controller: widget.controller,
          label: 'Phone number',
          errorText: showError ? 'Phone number is invalid.' : null,
          onChanged: (value) => setState(() => showError = false));

  @override
  Widget build(BuildContext context) => AlertDialog(
      title: const Text('Forgot password'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [inputField]),
      actions: [
        BlocBuilder<AuthPasswordBloc, AuthPasswordState>(
            bloc: widget.authPasswordBloc,
            builder: (context, state) => Button.primary(
                onTap: submit,
                text: 'Send OTP',
                isLoading:
                    state.status == AuthPasswordStatus.loading && state.action == widget.loadingAction))
      ]);
}
