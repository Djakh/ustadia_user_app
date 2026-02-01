import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_option_button.dart';

class AssignmentQuizView extends StatelessWidget {
  final String question;
  final List<String> options;
  final VoidCallback onSelect;
  final Color accentColor;

  const AssignmentQuizView(
      {super.key,
      required this.question,
      required this.options,
      required this.onSelect,
      required this.accentColor});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: Style.border32,
                border: Border.all(color: AppColors.gray100),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
                ]),
            child: Text(question,
                textAlign: TextAlign.center, style: Style.body2w6(context))),
        const SizedBox(height: 20),
        Column(
            children: options
                .map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AssignmentOptionButton(
                        label: option, onTap: onSelect, accentColor: accentColor)))
                .toList())
      ]);
}
