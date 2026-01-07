import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_writing_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_writing_method_card.dart';

class LearnWritingBottomSheet extends StatelessWidget {
  final Function(LearnWritingMethodType type) onTap;
  const LearnWritingBottomSheet({super.key, required this.onTap});

  Container view(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('How do you want to write?', style: Style.body2w7(context)),
        const SizedBox(height: 16),
        LearnWritingMethodCard(
            title: 'Upload paper writing',
            subtitle: 'Take a photo of your notebook',
            image: AppImages.learnWritingUploadMethod,
            onTap: () => onTap(LearnWritingMethodType.upload)),
        const SizedBox(height: 8),
        LearnWritingMethodCard(
            title: 'In-app writing',
            subtitle: 'Type directly in the app',
            image: AppImages.learnWritingInappMethod,
            onTap: () => onTap(LearnWritingMethodType.inApp)),
        const SizedBox(height: 16),
      ]));

  @override
  Widget build(BuildContext context) => view(context);
}
