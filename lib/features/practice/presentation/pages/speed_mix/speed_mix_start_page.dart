import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/router.dart';

class SpeedMixStartPage extends StatelessWidget {
  const SpeedMixStartPage({super.key});

  /// --- Widgets ---

  Widget startButton(BuildContext context) =>
      Button.primary(onTap: () => context.pushReplacement(speedMixPracticeRoute), text: 'Start (2:00)');

  Widget startCard(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(AppImages.speedMixLightning, height: 160, width: 160),
          const SizedBox(height: 12),
          Text('Speed mix', style: Style.body3w7(context)),
          const SizedBox(height: 4),
          Text('A fast mix of tasks. You have 2 minutes',
              style: Style.bodyw4(context, color: TextColorRole.greyColor)),
          const Spacer(),
          startButton(context)
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.cs.surface,
        body: PrimaryBackground(
            title: 'Speed Mix',
            child: Padding(
                padding: const EdgeInsets.all(12), child: Center(child: startCard(context)))),
      );
}
