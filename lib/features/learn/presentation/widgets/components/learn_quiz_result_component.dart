import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class LearnQuizResultComponent extends StatelessWidget {
  const LearnQuizResultComponent({super.key});

  /// --- Methods ---

  void backToTopic(BuildContext context) => context.pop(true);

  /// --- Widgets ---

  Widget view(BuildContext context) => Column(children: [
        const Spacer(),
        Image.asset(AppImages.learnListeningCheck, height: 160, width: 160),
        Text('Task completed!', style: Style.body3w7(context)),
        const Spacer(),
        Button.primary(onTap: () => backToTopic(context), text: 'Back to topic')
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
