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
  final ScrollController scrollController = ScrollController();
  int currentPage = 1;
  bool hasMoreMessages = true;
  bool isPaginating = false;
  static const int pageLimit = 50;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<AskAiBloc>().add(AskAiTopicOpened(topic: widget.topic));
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void onScroll() {
    if (!scrollController.hasClients) return;
    final threshold = 200.0;
    final currentOffset = scrollController.offset;
    final maxOffset = scrollController.position.maxScrollExtent;
    if (currentOffset < maxOffset - threshold) return;
    requestNextPage();
  }

  void requestNextPage() {
    if (!hasMoreMessages || isPaginating) return;
    final blocState = context.read<AskAiBloc>().state;
    if (blocState.messagesStatus.isLoading) return;
    isPaginating = true;
    currentPage += 1;
    context.read<AskAiBloc>().add(
        AskAiMessagesRequested(topicId: widget.topic.id, page: currentPage, limit: pageLimit));
    if (mounted) setState(() {});
  }

  Widget messagesList(List<AiChatMessageModel> list, String userId) => ListView.builder(
      controller: scrollController,
      reverse: true,
      itemCount: list.length + (isPaginating ? 1 : 0),
      padding: const EdgeInsets.only(bottom: 40),
      itemBuilder: (context, index) {
        if (isPaginating && index == list.length) {
          return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))));
        }
        final message = list[list.length - 1 - index];
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AiChatMessageBubble(message: message, isMe: message.role == 'user'));
      });

  Future<void> openVoice(BuildContext context) async {
    await Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (context) => VoiceCallPage(topic: widget.topic)));
    if (!mounted) return;
    currentPage = 1;
    hasMoreMessages = true;
    isPaginating = false;
    context
        .read<AskAiBloc>()
        .add(AskAiMessagesRequested(topicId: widget.topic.id, page: 1, limit: pageLimit));
  }

  /// --- Widgets ---

  Widget get view => BlocConsumer<AskAiBloc, AskAiState>(
      listener: (context, state) {
        if (state.messagesStatus.isSuccess) {
          if (isPaginating) {
            final loadedCount = state.messages.length;
            final estimatedPreviousCount = (currentPage - 1) * pageLimit;
            hasMoreMessages = loadedCount > estimatedPreviousCount;
            isPaginating = false;
            if (mounted) setState(() {});
            return;
          }
          currentPage = 1;
          hasMoreMessages = state.messages.length >= pageLimit;
          isPaginating = false;
          if (mounted) setState(() {});
          return;
        }
        if (state.messagesStatus.isError) {
          if (isPaginating && currentPage > 1) currentPage -= 1;
          isPaginating = false;
          if (mounted) setState(() {});
        }
      },
      builder: (context, state) {
        final isInitialLoading = state.messagesStatus.isLoading && state.messages.isEmpty;
        if (isInitialLoading) {
          return ShimmerList(
              itemCount: 4,
              itemHeight: 72,
              borderRadius: Style.border20,
              padding: const EdgeInsets.only(bottom: 40));
        }
        return messagesList(state.messages, state.userId);
      });

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
