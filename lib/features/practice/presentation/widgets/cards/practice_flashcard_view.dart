import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/practice/data/models/flashcard_model.dart';

class PracticeFlashcardView extends StatelessWidget {
  final FlashcardModel flashcard;
  final bool showMeaning;
  final VoidCallback onToggle;

  const PracticeFlashcardView(
      {super.key, required this.flashcard, required this.showMeaning, required this.onToggle});

  /// --- Widgets ---

  Widget get iconImage => Image.asset(AppImages.flapIcon, height: 24, width: 24);

  Row tapToFlipWidgets(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        iconImage,
        const SizedBox(width: 6),
        Text('Tap to flip', style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget faceContent(BuildContext context) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Word', style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 8),
        Text(flashcard.word, style: Style.headline5w7(context)),
        const SizedBox(height: 24),
        tapToFlipWidgets(context)
      ]);

  Widget backContent(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Meaning', style: Style.small3w4(context)),
          const SizedBox(height: 12),
          Text(flashcard.meaning, textAlign: TextAlign.center, style: Style.body3w4(context))
        ],
      ));

  Widget get faceCard => Container(
      key: const ValueKey<bool>(false),
      decoration: BoxDecoration(borderRadius: Style.border20, color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 6))
      ]),
      child: Center(child: faceContentView));

  Widget get backCard => Container(
      key: const ValueKey<bool>(true),
      decoration: BoxDecoration(
          borderRadius: Style.border20,
          image: const DecorationImage(
              image: AssetImage(AppImages.flashcardBackrgound), fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6))
          ]),
      child: Center(child: backContentView));

  Widget get faceContentView => Builder(builder: faceContent);

  Widget get backContentView => Builder(builder: backContent);

  Widget cardBody(BuildContext context) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) {
        final rotateAnim = Tween(begin: math.pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, child) {
              final isUnder = (child!.key != ValueKey<bool>(showMeaning));
              final value = isUnder ? math.min(rotateAnim.value, math.pi / 2) : rotateAnim.value;
              return Transform(
                  transform: Matrix4.rotationY(value),
                  alignment: Alignment.center,
                  child: isUnder
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: child)
                      : child);
            });
      },
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: showMeaning ? backCard : faceCard);

  Widget view(BuildContext context) => InkWell(
      onTap: onToggle,
      borderRadius: Style.border20,
      child: Ink(
          height: 477,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: Style.border20,
              border: Border.all(color: Colors.black12)),
          child: cardBody(context)));

  @override
  Widget build(BuildContext context) => view(context);
}
