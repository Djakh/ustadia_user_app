import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';

class AiChatMessageBubble extends StatelessWidget {
  final AiChatMessageModel message;
  final bool isMe;
  final bool useDarkTheme;

  const AiChatMessageBubble(
      {super.key, required this.message, required this.isMe, this.useDarkTheme = false});

  @override
  Widget build(BuildContext context) {
    final background = useDarkTheme
        ? isMe
            ? AppColors.primary
            : AppColors.white.withValues(alpha: 0.08)
        : isMe
            ? AppColors.primary
            : AppColors.gray100;
    final textColor = useDarkTheme
        ? AppColors.white
        : isMe
            ? AppColors.white
            : AppColors.black;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(crossAxisAlignment: alignment, children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: background,
              borderRadius: Style.border16,
              border: useDarkTheme && !isMe
                  ? Border.all(color: AppColors.white.withValues(alpha: 0.08))
                  : null),
          child: Text(message.content, style: Style.bodyw5(context).copyWith(color: textColor)))
    ]);
  }
}
