import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';

class AiChatTopicCard extends StatelessWidget {
  final AiChatTopicModel topic;
  final VoidCallback onTap;

  const AiChatTopicCard({super.key, required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) => PrimaryBox(
      onTap: onTap,
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(topic.title, style: Style.body2w6(context)),
        const SizedBox(height: 6),
        Text(topic.description, style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 6),
        Text('${topic.duration}s', style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]));
}
