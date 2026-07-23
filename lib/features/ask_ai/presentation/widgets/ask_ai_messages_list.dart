import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_animated_message_item.dart';

class AskAiMessagesList extends StatelessWidget {
  final List<AiChatMessageModel> messages;
  final ScrollController scrollController;
  final bool isPaginating;
  final double topPadding;
  final double bottomPadding;
  final ValueChanged<AiChatMessageModel>? onReport;

  const AskAiMessagesList(
      {super.key,
      required this.messages,
      required this.scrollController,
      required this.isPaginating,
      required this.topPadding,
      required this.bottomPadding,
      this.onReport});

  Widget itemBuilder(BuildContext context, int index) {
    if (index >= messages.length) {
      return const Padding(
          key: ValueKey('pagination_loader'),
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))));
    }
    final message = messages[messages.length - 1 - index];
    return Padding(
        key: ValueKey(message.id),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AskAiAnimatedMessageItem(
            message: message,
            isMe: message.role == 'user',
            onReport: message.role == 'user' ? null : () => onReport?.call(message)));
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
      itemCount: messages.length + (isPaginating ? 1 : 0),
      itemBuilder: itemBuilder);
}
