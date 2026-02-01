import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AssignmentResultRow extends StatelessWidget {
  final String text;

  const AssignmentResultRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: AppColors.greenE7, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 14, color: AppColors.success)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: Style.small3w4(context, color: TextColorRole.greyColor)))
        ]
      );
}
