import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_bloc.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_state.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/pages/messages_page.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ai_chat_topic_card.dart';

class TopicsPage extends StatelessWidget {
  const TopicsPage({super.key});

  void openTopic(BuildContext context, AiChatTopicModel topic) {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (context) => MessagesPage(topic: topic)));
  }

  Widget topicsList(BuildContext context, List<AiChatTopicModel> topics) => Column(
      children: topics
          .map((topic) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AiChatTopicCard(topic: topic, onTap: () => openTopic(context, topic))))
          .toList());

  @override
  Widget build(BuildContext context) => PrimaryBackground(
      isScrollable: true,
      backgroundColor: context.cs.surface,
      child: BlocStatusView<AskAiBloc, AskAiState, List<AiChatTopicModel>>(
          bloc: context.read<AskAiBloc>(),
          statusOf: (s) => s.topicsStatus,
          errorOf: (s) => s.errorMessage,
          data: (s) => s.topics,
          isEmpty: (data) => data.isEmpty,
          empty: Center(child: Text('No topics found'.tr())),
          loading: ShimmerList(
              itemCount: 4,
              itemHeight: 92,
              padding: Style.paddingPrimary,
              borderRadius: Style.border20),
          builder: (context, topics) => Column(children: [
                const SizedBox(height: 24),
                topicsList(context, topics),
                const SizedBox(height: 80)
              ])));
}
