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
    final textColor = useDarkTheme
        ? AppColors.white
        : isMe
            ? AppColors.white
            : AppColors.black;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.82;
    return Column(crossAxisAlignment: alignment, children: [
      ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: useDarkTheme && !isMe
                      ? AppColors.white.withValues(alpha: 0.08)
                      : isMe
                          ? AppColors.primary
                          : AppColors.gray100,
                  gradient: useDarkTheme && isMe
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.green6A])
                      : null,
                  borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 8),
                      bottomRight: Radius.circular(isMe ? 8 : 18)),
                  border: useDarkTheme
                      ? Border.all(color: AppColors.white.withValues(alpha: isMe ? 0.08 : 0.1))
                      : null,
                  boxShadow: useDarkTheme
                      ? [
                          BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.14),
                              blurRadius: 14,
                              offset: const Offset(0, 8))
                        ]
                      : null),
              child: Text(message.content,
                  style: Style.bodyw5(context).copyWith(color: textColor, height: 1.45))))
    ]);
  }
}
