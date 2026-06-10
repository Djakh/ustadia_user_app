import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/connection/reload_conntection_button.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_bloc.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_state.dart';
import 'package:ustadia_user_app/features/auth/data/models/otp_verification_params.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';
import 'package:ustadia_user_app/size_config.dart';

class OtpPage extends StatefulWidget {
  final String contact;
  final OtpVerificationParams? verificationParams;
  const OtpPage({super.key, required this.contact, this.verificationParams});

  @override
  State<OtpPage> createState() => OtpPageState();
}

class OtpPageState extends State<OtpPage> {
  static const codeLength = 6;
  final codes = List.generate(codeLength, (_) => TextEditingController());
  final nodes = List.generate(codeLength, (_) => FocusNode());
  Timer? countdown;
  int secondsLeft = 30;
  final AuthVerifyBloc authVerifyBloc = sl<AuthVerifyBloc>();
  late final UserBloc userBloc;
  bool isAwaitingUser = false;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    userBloc = context.read<UserBloc>();
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
    authVerifyBloc.close();
    super.dispose();
  }

  /// --- Methods ---

  String get codeValue => codes.map((c) => c.text).join();

  bool get isComplete => codeValue.length == codeLength;

  void goToHome() => context.go(dashboardRoute);

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
    final params = widget.verificationParams;
    if (params == null) return;
    for (final controller in codes) {
      controller.clear();
    }
    setState(() {});
    nodes.first.requestFocus();
    authVerifyBloc.add(AuthResendOtpRequested(tempId: params.tempId));
  }

  void onConfirm() {
    if (!isComplete) return;
    if (widget.verificationParams == null) {
      goToIntroSurvey();
      return;
    }
    if (authVerifyBloc.state.status == Status.loading) return;
    authVerifyBloc
        .add(AuthVerifyOtpRequested(tempId: widget.verificationParams!.tempId, otp: codeValue));
  }

  void onDigitChanged(int index, String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length > 1) {
      _applyBulkCode(cleaned, startIndex: index);
      return;
    }
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

  void _applyBulkCode(String value, {int startIndex = 0}) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    for (var i = 0; i < codeLength; i++) {
      final targetIndex = startIndex + i;
      if (targetIndex >= codeLength) break;
      codes[targetIndex].text = i < digits.length ? digits[i] : '';
      codes[targetIndex].selection =
          TextSelection.fromPosition(TextPosition(offset: codes[targetIndex].text.length));
    }
    final nextIndex = (startIndex + digits.length).clamp(0, codeLength - 1);
    if (digits.length >= codeLength - startIndex) {
      FocusScope.of(context).unfocus();
    } else {
      nodes[nextIndex].requestFocus();
    }
    setState(() {});
  }

  String get timerLabel {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get hasConnectionIssue =>
      DioErrorMessage.isConnectionMessage(authVerifyBloc.state.errorMessage) ||
      DioErrorMessage.isConnectionMessage(userBloc.state.errorMessage);

  bool get isAuthenticating =>
      authVerifyBloc.state.status == Status.loading ||
      (isAwaitingUser && userBloc.state.status == Status.loading);

  bool get isResendingOtp =>
      authVerifyBloc.state.status == Status.loading &&
      authVerifyBloc.state.action == AuthVerifyAction.resendOtp;

  Future<void> retryConnection() async {
    if (isAwaitingUser) {
      userBloc.add(
          UserProfileRequested(preferredLanguage: Localizations.localeOf(context).languageCode));
      return;
    }
    onConfirm();
  }

  String localizedOtpMessage(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized == 'otp resent') return 'OTP resent'.tr();
    if (normalized.contains('temp id') ||
        (normalized.contains('otp') &&
            (normalized.contains('expired') || normalized.contains('invalid')))) {
      return 'Expired or invalid OTP.'.tr();
    }
    return message.tr();
  }

  /// --- Widgets ---

  Widget get contactText => Text.rich(TextSpan(children: [
        TextSpan(
          text: widget.verificationParams?.isPhoneVerification == true
              ? 'Enter the 6-digit OTP sent to your phone to complete sign-up verification, '.tr()
              : 'Enter the 6-digit OTP sent to your email to complete sign-up verification, '.tr(),
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
      width: SizeConfig.rw * 56,
      height: SizeConfig.rh * 50,
      child: TextField(
          controller: codes[index],
          focusNode: nodes[index],
          keyboardType: TextInputType.number,
          textInputAction: index == codeLength - 1 ? TextInputAction.done : TextInputAction.next,
          textAlign: TextAlign.center,
          style: Style.body2w6(context),
          maxLength: 1,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
      onPressed: secondsLeft == 0 && !isResendingOtp ? onResend : null,
      child: Text(
          secondsLeft == 0 ? (isResendingOtp ? 'Sending...'.tr() : 'Resend'.tr()) : timerLabel,
          style: Style.small3w5(context,
                  color: secondsLeft == 0 ? TextColorRole.onSurface : TextColorRole.greyColor)
              .copyWith(color: secondsLeft == 0 ? context.cs.primary : context.cs.onSurface)));

  Widget get resend => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Didn’t receive the OTP?'.tr(),
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        resendButton
      ]);

  Widget get confirmButton => SafeArea(
      child: BlocBuilder<AuthVerifyBloc, AuthVerifyState>(
          bloc: authVerifyBloc,
          builder: (context, state) => Button.primary(
              onTap: onConfirm,
              isAvialable: isComplete && !isAuthenticating,
              isLoading: isAuthenticating,
              text: 'Confirm'.tr())));

  Widget get view => PrimaryBackground(
      isScrollable: true,
      child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AutofillGroup(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 20),
            Text('Enter OTP'.tr(), style: Style.body2w6(context)),
            const SizedBox(height: 4),
            contactText,
            const SizedBox(height: 24),
            otpRow,
            resend,
            const SizedBox(height: 24),
            confirmButton,
            if (hasConnectionIssue) ...[
              const SizedBox(height: 12),
              ReloadConntectionButton(onReloadConnection: retryConnection),
            ],
            const SizedBox(height: 12)
          ]))));

  @override
  Widget build(BuildContext context) => MultiBlocListener(listeners: [
        BlocListener<AuthVerifyBloc, AuthVerifyState>(
            bloc: authVerifyBloc,
            listener: (context, state) {
              if (mounted) setState(() {});
              if (state.status == Status.success && state.action == AuthVerifyAction.resendOtp) {
                startTimer();
                if (state.message != null && state.message!.isNotEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(localizedOtpMessage(state.message!))));
                }
                return;
              }
              if (state.status == Status.success && state.action == AuthVerifyAction.verifyOtp) {
                isAwaitingUser = true;
                userBloc.add(UserProfileRequested(
                    preferredLanguage: Localizations.localeOf(context).languageCode));
                return;
              }
              if (state.status == Status.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizedOtpMessage(state.errorMessage!))));
              }
            }),
        BlocListener<UserBloc, UserState>(
            bloc: userBloc,
            listener: (context, state) {
              if (mounted) setState(() {});
              if (!isAwaitingUser) return;
              if (state.status == Status.success) {
                isAwaitingUser = false;
                final profile = state.profile;
                if (profile != null && profile.introCompleted) {
                  goToHome();
                  return;
                }
                goToIntroSurvey();
              }
              if (state.status == Status.error && state.errorMessage != null) {
                isAwaitingUser = false;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            })
      ], child: Scaffold(backgroundColor: context.cs.surface, body: view));
}
