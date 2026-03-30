import 'package:flutter/material.dart';
class AskAiConversationContent extends StatelessWidget {
  final Widget messagesPanel;
  final Widget voiceAgentSection;
  final Widget microphoneButton;

  const AskAiConversationContent(
      {super.key,
      required this.messagesPanel,
      required this.voiceAgentSection,
      required this.microphoneButton});

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: messagesPanel),
        Positioned(top: 8, left: 0, right: 0, child: voiceAgentSection),
        Positioned(left: 0, right: 0, bottom: 0, child: microphoneButton)
      ]);
}
