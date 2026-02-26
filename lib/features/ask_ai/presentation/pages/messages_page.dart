import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_bloc.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_event.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_state.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/pages/voice_call_page.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ai_chat_message_bubble.dart';

class MessagesPage extends StatefulWidget {
  final AiChatTopicModel topic;

  const MessagesPage({super.key, required this.topic});

  @override
  State<MessagesPage> createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<AskAiBloc>().add(AskAiTopicOpened(topic: widget.topic));
    });
  }

  Widget messagesList(List<AiChatMessageModel> list, String userId) => ListView.builder(
      reverse: true,
      itemCount: list.length,
      padding: const EdgeInsets.only(bottom: 40),
      itemBuilder: (context, index) {
        final message = list[list.length - 1 - index];
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AiChatMessageBubble(message: message, isMe: message.role == 'user'));
      });

  Future<void> openVoice(BuildContext context) async {
    await Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (context) => VoiceCallPage(topic: widget.topic)));
    if (!mounted) return;
    context
        .read<AskAiBloc>()
        .add(AskAiMessagesRequested(topicId: widget.topic.id, page: 1, limit: 50));
  }

  /// --- Widgets ---

  Widget get view => BlocBuilder<AskAiBloc, AskAiState>(
        builder: (context, state) => state.messagesStatus.isLoading
            ? ShimmerList(
                itemCount: 4,
                itemHeight: 72,
                borderRadius: Style.border20,
                padding: const EdgeInsets.only(bottom: 40))
            : messagesList(state.messages, state.userId),
      );

  AppBar appBar(BuildContext context) => AppBar(
      backgroundColor: context.cs.surface,
      title: Text(widget.topic.title, style: Style.body2w6(context)));

  FloatingActionButton floatActionButton(BuildContext context) => FloatingActionButton(
      backgroundColor: context.cs.primary,
      onPressed: () => openVoice(context),
      child: const Icon(Icons.mic));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.cs.surface,
        appBar: appBar(context),
        body: SafeArea(
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: view)),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: floatActionButton(context),
      );
}
