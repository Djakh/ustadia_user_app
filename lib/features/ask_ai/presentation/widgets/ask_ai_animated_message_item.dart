import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ai_chat_message_bubble.dart';

class AskAiAnimatedMessageItem extends StatefulWidget {
  final AiChatMessageModel message;
  final bool isMe;

  const AskAiAnimatedMessageItem({super.key, required this.message, required this.isMe});

  @override
  State<AskAiAnimatedMessageItem> createState() => AskAiAnimatedMessageItemState();
}

class AskAiAnimatedMessageItemState extends State<AskAiAnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<Offset> offsetAnimation;
  late final Animation<double> opacityAnimation;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    offsetAnimation =
        Tween<Offset>(begin: Offset(widget.isMe ? 0.18 : -0.18, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic));
    opacityAnimation = CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic);
    animationController.forward();
  }

  @override
  void didUpdateWidget(covariant AskAiAnimatedMessageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final contentChanged = oldWidget.message.content != widget.message.content;
    final messageChanged = oldWidget.message.id != widget.message.id;
    if (!contentChanged && !messageChanged) return;
    animationController.forward(from: 0);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: opacityAnimation,
      child: SlideTransition(
          position: offsetAnimation,
          child: AiChatMessageBubble(
              key: ValueKey('${widget.message.id}:${widget.message.content.length}:${widget.message.isFinished}'),
              message: widget.message,
              isMe: widget.isMe,
              useDarkTheme: true)));
}
