import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/router.dart';

class OtpPage extends StatefulWidget {
  final String contact;
  const OtpPage({super.key, required this.contact});

  @override
  State<OtpPage> createState() => OtpPageState();
}

class OtpPageState extends State<OtpPage> {
  static const codeLength = 4;
  final codes = List.generate(codeLength, (_) => TextEditingController());
  final nodes = List.generate(codeLength, (_) => FocusNode());
  Timer? countdown;
  int secondsLeft = 30;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    countdown?.cancel();
    for (final controller in codes) {
      controller.dispose();
    }
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// --- Methods ---

  String get codeValue => codes.map((c) => c.text).join();

  bool get isComplete => codeValue.length == codeLength;

  void goToHome() => context.go(homeRoute);

  void goToIntroSurvey() => context.go(introSurveyRoute);

  void startTimer() {
    countdown?.cancel();
    setState(() => secondsLeft = 30);
    countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft == 0) {
        timer.cancel();
        return;
      }
      setState(() => secondsLeft -= 1);
    });
  }

  void onResend() {
    for (final controller in codes) {
      controller.clear();
    }
    nodes.first.requestFocus();
    startTimer();
  }

  void onConfirm() {
    if (isComplete) goToIntroSurvey();
  }

  void onDigitChanged(int index, String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    codes[index].text = cleaned.isEmpty ? '' : cleaned.substring(cleaned.length - 1);
    codes[index].selection =
        TextSelection.fromPosition(TextPosition(offset: codes[index].text.length));
    if (codes[index].text.isNotEmpty && index < codeLength - 1) {
      nodes[index + 1].requestFocus();
    }
    if (codes[index].text.isEmpty && index > 0) {
      nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  String get timerLabel {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// --- Widgets ---

  Widget get contactText => Text.rich(TextSpan(children: [
        TextSpan(
          text: 'Enter the 4-digit OTP sent to your email to complete sign-up verification, ',
          style: Style.small3w4(context, color: TextColorRole.greyColor),
        ),
        TextSpan(
          text: widget.contact,
          style: Style.small3w5(context).copyWith(fontWeight: FontWeight.w600),
        )
      ]));

  InputBorder otpBorder(Color color) => OutlineInputBorder(
      borderRadius: Style.border10, borderSide: BorderSide(color: color, width: 1.4));

  Widget otpBox(int index) => SizedBox(
      width: 82.25,
      height: 54,
      child: TextField(
          controller: codes[index],
          focusNode: nodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: Style.body2w6(context),
          maxLength: 1,
          decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: context.cs.surface,
              contentPadding: EdgeInsets.zero,
              enabledBorder: otpBorder(context.cs.surface),
              focusedBorder: otpBorder(context.cs.primary)),
          onChanged: (value) => onDigitChanged(index, value)));

  Widget get otpRow => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(codeLength, (index) => otpBox(index)));

  Widget get resendButton => TextButton(
      onPressed: secondsLeft == 0 ? onResend : null,
      child: Text(secondsLeft == 0 ? 'Resend' : timerLabel,
          style: Style.small3w5(context,
                  color: secondsLeft == 0 ? TextColorRole.onSurface : TextColorRole.greyColor)
              .copyWith(color: secondsLeft == 0 ? context.cs.primary : context.cs.onSurface)));

  Widget get resend => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Didn’t receive the OTP?',
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        resendButton
      ]);

  Widget get confirmButton =>
      SafeArea(child: Button.primary(onTap: onConfirm, isAvialable: isComplete, text: 'Confirm'));

  Widget get view => PrimaryBackground(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        Text('Enter OTP', style: Style.body2w6(context)),
        const SizedBox(height: 4),
        contactText,
        const SizedBox(height: 24),
        otpRow,
        resend,
        const Spacer(),
        confirmButton
      ]));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.cs.surface,
        body: view,
      );
}
