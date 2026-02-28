import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/ask_ai/data/datasources/ai_chat_remote_data_source.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';
import 'package:ustadia_user_app/features/ask_ai/state/voice_call_notifier.dart';
import 'package:ustadia_user_app/features/ask_ai/widgets/voice_orb.dart';
import 'package:ustadia_user_app/injection_container.dart';

class VoiceCallPage extends StatefulWidget {
  final AiChatTopicModel topic;

  const VoiceCallPage({super.key, required this.topic});

  @override
  State<VoiceCallPage> createState() => VoiceCallPageState();
}

class VoiceCallPageState extends State<VoiceCallPage> with WidgetsBindingObserver {
  late final VoiceCallNotifier voiceCallNotifier;
  Timer? callLimitTimer;
  int remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    remainingSeconds = widget.topic.duration > 0 ? widget.topic.duration * 60 : 0;
    startCallLimitTimer();
    voiceCallNotifier = VoiceCallNotifier(
        aiChatRemoteDataSource: sl<AiChatRemoteDataSource>(), topicId: widget.topic.id);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      voiceCallNotifier.connect();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    callLimitTimer?.cancel();
    voiceCallNotifier.disconnect();
    voiceCallNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      voiceCallNotifier.onAppPaused();
      return;
    }
    if (state == AppLifecycleState.resumed) voiceCallNotifier.onAppResumed();
  }

  Future<bool> onBack() async {
    callLimitTimer?.cancel();
    await voiceCallNotifier.disconnect();
    return true;
  }

  bool get hasTimeLimit => widget.topic.duration > 0;

  void startCallLimitTimer() {
    if (!hasTimeLimit || remainingSeconds <= 0) return;
    callLimitTimer?.cancel();
    callLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingSeconds <= 1) {
        setState(() => remainingSeconds = 0);
        timer.cancel();
        await onBack();
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }
      setState(() => remainingSeconds -= 1);
    });
  }

  String timerValue() {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String statusText(VoiceUiState state) {
    if (state == VoiceUiState.error) return 'Error'.tr();
    if (voiceCallNotifier.assistantSpeaking) return 'Assistant speaking'.tr();
    if (voiceCallNotifier.userSpeaking) return 'Listening...'.tr();
    switch (state) {
      case VoiceUiState.connecting:
        return 'Connecting...'.tr();
      case VoiceUiState.listening:
        return 'Speak now'.tr();
      case VoiceUiState.thinking:
        return 'Thinking...'.tr();
      case VoiceUiState.speaking:
        return 'Assistant speaking'.tr();
      case VoiceUiState.error:
        return 'Error'.tr();
    }
  }

  Widget view(VoiceUiState state, String displayStatus, BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VoiceOrb(
                voiceUiState: state,
                assistantLevel: voiceCallNotifier.agentAudioLevel,
                userLevel: voiceCallNotifier.localAudioLevel,
                assistantSpeaking: voiceCallNotifier.assistantSpeaking,
                userSpeaking: voiceCallNotifier.userSpeaking,
                size: 190),
            const SizedBox(height: 24),
            Text(displayStatus, style: Style.bodyw6(context, color: TextColorRole.whiteColor)),
            if (state == VoiceUiState.error) ...[
              const SizedBox(height: 16),
              Button.primary(onTap: () => voiceCallNotifier.connect(), text: 'Reconnect'.tr())
            ]
          ],
        ),
      );

  AppBar appBar(BuildContext context) => AppBar(
      backgroundColor: AppColors.secondary,
      elevation: 0,
      leading: IconButton(
          onPressed: () async {
            await onBack();
            if (!mounted) return;
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.white)),
      actions: hasTimeLimit
          ? [
              Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.16), borderRadius: Style.border12),
                          child: Text(timerValue(),
                              style: Style.small2w5(context, color: TextColorRole.whiteColor)))))
            ]
          : null,
      title:
          Text(widget.topic.title, style: Style.body2w6(context, color: TextColorRole.whiteColor)));

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: onBack,
      child: Scaffold(
          backgroundColor: AppColors.secondary,
          appBar: appBar(context),
          body: SafeArea(
              child: AnimatedBuilder(
                  animation: voiceCallNotifier,
                  builder: (context, child) {
                    final state = voiceCallNotifier.voiceUiState;
                    final statusValue = statusText(state);
                    final errorValue = voiceCallNotifier.errorMessage;
                    final displayStatus = state == VoiceUiState.error && errorValue != null
                        ? errorValue
                        : statusValue;
                    return view(state, displayStatus, context);
                  }))));
}
