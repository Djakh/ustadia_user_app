import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';

class AiChatMessageBubble extends StatelessWidget {
  final AiChatMessageModel message;
  final bool isMe;

  const AiChatMessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final background = isMe ? AppColors.primary : AppColors.gray100;
    final textColor = isMe ? AppColors.white : AppColors.black;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(crossAxisAlignment: alignment, children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: background, borderRadius: Style.border16),
          child: Text(message.content, style: Style.bodyw5(context).copyWith(color: textColor)))
    ]);
  }
}
