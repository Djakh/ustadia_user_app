import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class AudioCard extends StatefulWidget {
  const AudioCard({super.key});

  @override
  State<AudioCard> createState() => AudioCardState();
}

class AudioCardState extends State<AudioCard> {
  final FlutterTts tts = FlutterTts();
  bool isPlaying = false;
  String get sampleText => 'Welcome to the listening lesson. Tap continue when ready.';

  /// --- Methods ---
  Future<void> configureTts() async {
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.55);
    await tts.setPitch(1.0);
    await tts.setVolume(1.0);
    await tts.awaitSpeakCompletion(true);
  }

  @override
  void initState() {
    super.initState();
    configureTts();
    tts.setCompletionHandler(() => setState(() => isPlaying = false));
    tts.setCancelHandler(() => setState(() => isPlaying = false));
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> toggleAudio() async {
    if (isPlaying) {
      await tts.stop();
      if (!mounted) return;
      setState(() => isPlaying = false);
      return;
    }
    setState(() => isPlaying = true);
    await tts.setSpeechRate(0.55);
    await tts.speak(sampleText);
  }

  /// --- Widgets ---
  Widget playButton() => Container(
      height: 36,
      width: 36,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: Center(
          child: SvgPicture.asset(
              isPlaying ? AppImages.learnListeningStop : AppImages.learnListeningPlay,
              height: 16,
              width: 16,
              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn))));

  Widget view(BuildContext context) => Row(children: [
        SvgPicture.asset(AppImages.learnListeningAudio, height: 32, width: 32),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Audio lesson', style: Style.bodyw6(context)),
          const SizedBox(height: 4),
          Text(isPlaying ? 'Playing...' : 'Tap to listen',
              style: Style.small3w4(context, color: TextColorRole.greyColor))
        ])),
        InkWell(onTap: toggleAudio, borderRadius: Style.border20, child: playButton())
      ]);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: Style.border20,
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))
          ]),
      child: view(context));
}
