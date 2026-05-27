import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';

class TutorialMascot extends StatelessWidget {
  final double size;
  final TutorialMascotMood mood;

  const TutorialMascot({super.key, this.size = 84, this.mood = TutorialMascotMood.happy});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: SizedBox.square(
          dimension: size,
          child: Lottie.asset(assetPath,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              errorBuilder: (context, error, stackTrace) => PencilMascotFallback(size: size))));

  String get assetPath => switch (mood) {
        TutorialMascotMood.happy => 'assets/lotties/Happy pencil.json',
        TutorialMascotMood.smart => 'assets/lotties/Pencil Smart.json',
        TutorialMascotMood.strong => 'assets/lotties/Strong Pencil.json',
        TutorialMascotMood.confused => 'assets/lotties/Confused and Nervous Pencil.json',
        TutorialMascotMood.tired => 'assets/lotties/Tired Pencil.json',
      };
}

class PencilMascotFallback extends StatelessWidget {
  final double size;

  const PencilMascotFallback({super.key, required this.size});

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: AppColors.greenE7,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18))),
      child: Icon(Icons.edit_rounded, size: size * 0.46, color: AppColors.primary));
}
