import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/router.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

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

  bool get isComplete => codeValue.length == codeLength && !codeValue.contains('');

  void goBack() => context.pop();

  void goToHome() => context.go(postsRoute);

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
    if (isComplete) goToHome();
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

  Widget get appBar => Row(children: [
        IconButton(
            onPressed: goBack,
            icon: Icon(Icons.arrow_back_ios_new, color: context.cs.onSurface, size: 18)),
      ]);

  Widget get headline => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Enter OTP', style: Style.body2w6(context)),
        const SizedBox(height: 6),
        Text(
            'Enter the 4-digit OTP sent to your email to complete sign-up verification, +998 (99) 971 23 45',
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  InputBorder otpBorder(Color color) => OutlineInputBorder(
      borderRadius: Style.border10, borderSide: BorderSide(color: color, width: 1.4));

  Widget otpBox(int index) => SizedBox(
      width: 58,
      height: 56,
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
              enabledBorder: otpBorder(context.cs.onTertiary.withOpacity(0.4)),
              focusedBorder: otpBorder(context.cs.primary)),
          onChanged: (value) => onDigitChanged(index, value)));

  Widget get otpRow => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(codeLength, (index) => otpBox(index)));

  Widget get resend => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Resend code in', style: Style.small3w4(context, color: TextColorRole.greyColor)),
        TextButton(
            onPressed: secondsLeft == 0 ? onResend : null,
            child: Text(secondsLeft == 0 ? 'Resend now' : timerLabel,
                style: Style.small3w5(context,
                        color: secondsLeft == 0 ? TextColorRole.onSurface : TextColorRole.greyColor)
                    .copyWith(
                        color: secondsLeft == 0 ? context.cs.primary : context.cs.onTertiary)))
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                appBar,
                const SizedBox(height: 20),
                headline,
                const SizedBox(height: 24),
                otpRow,
                const SizedBox(height: 12),
                resend,
                const SizedBox(height: 24),
                Button.primary(onTap: onConfirm, isAvialable: isComplete, text: 'Confirm')
              ]))));
}
