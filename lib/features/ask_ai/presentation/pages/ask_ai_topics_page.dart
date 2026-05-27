import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_bloc.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_event.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_state.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ai_chat_topic_card.dart';
import 'package:ustadia_user_app/router.dart';

class AskAiTopicsPage extends StatefulWidget {
  const AskAiTopicsPage({super.key});

  @override
  State<AskAiTopicsPage> createState() => _AskAiTopicsPageState();
}

class _AskAiTopicsPageState extends State<AskAiTopicsPage> {
  bool isOpeningVoiceAgent = false;
  final GlobalKey topicsKey = GlobalKey(debugLabel: 'ask_ai_topics');

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      context.read<AskAiBloc>().add(const AskAiTopicsRequested());
    });
  }

  /// --- Methods ---
  Future<void> openTopicVoiceAgent(BuildContext context, AiChatTopicModel topic) async {
    if (isOpeningVoiceAgent) return;
    setState(() => isOpeningVoiceAgent = true);
    try {
      await context.push(askAiVoiceAgentRoute, extra: topic);
    } finally {
      if (mounted) {
        setState(() => isOpeningVoiceAgent = false);
      } else {
        isOpeningVoiceAgent = false;
      }
    }
  }

  /// --- Widgets ---

  Widget topicsList(BuildContext context, List<AiChatTopicModel> topics) => Column(
      key: topicsKey,
      children: topics
          .map((topic) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  AiChatTopicCard(topic: topic, onTap: () => openTopicVoiceAgent(context, topic))))
          .toList());

  @override
  Widget build(BuildContext context) => GuidedTutorialPage(
      pageId: TutorialPageIds.askAi,
      steps: TutorialPresets.askAi(topicsKey: topicsKey),
      child: PrimaryBackground(
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
                  ]))));
}
