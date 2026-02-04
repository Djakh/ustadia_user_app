import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/text/html_text.dart';

class AssignmentContentView extends StatelessWidget {
  final String title;
  final List<String> content;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget? leadingCard;

  const AssignmentContentView(
      {super.key,
      required this.title,
      required this.content,
      required this.actionLabel,
      required this.onAction,
      this.leadingCard});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingCard != null) ...[leadingCard!, const SizedBox(height: 16)],
          Text(title, style: Style.body2w6(context)),
          const SizedBox(height: 12),
          Column(
              children: content
                  .map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HtmlText(
                          data: paragraph,
                          textStyle: Style.bodyw4(context, color: TextColorRole.greyColor))))
                  .toList()),
          const SizedBox(height: 20),
          Button.primary(onTap: onAction, text: actionLabel)
        ]
      );
}
