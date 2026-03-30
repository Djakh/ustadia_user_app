import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_messages_list.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_typing_indicator.dart';

class AskAiMessagesPanel extends StatelessWidget {
  final List<AiChatMessageModel> messages;
  final ScrollController scrollController;
  final bool isLoading;
  final bool isPaginating;
  final String? errorMessage;
  final bool showTypingIndicator;
  final double topPadding;
  final double bottomPadding;

  const AskAiMessagesPanel(
      {super.key,
      required this.messages,
      required this.scrollController,
      required this.isLoading,
      required this.isPaginating,
      required this.errorMessage,
      required this.showTypingIndicator,
      required this.topPadding,
      required this.bottomPadding});

  Widget get loadingView => const Center(
      child: CircularProgressIndicator(
          strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(AppColors.white)));

  Widget errorView(BuildContext context) => Center(
      child: Padding(
          padding: Style.paddingAll24,
          child: Text(errorMessage ?? 'Request failed.'.tr(),
              textAlign: TextAlign.center,
              style: Style.bodyw5(context, color: TextColorRole.whiteColor))));

  Widget contentView() => AskAiMessagesList(
      messages: messages,
      scrollController: scrollController,
      isPaginating: isPaginating,
      topPadding: topPadding,
      bottomPadding: bottomPadding);

  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(),
      child: isLoading
          ? loadingView
          : errorMessage != null && messages.isEmpty
              ? errorView(context)
              : Stack(children: [
                  Positioned.fill(child: contentView()),
                  Positioned(
                      left: 16,
                      right: 16,
                      bottom: bottomPadding - 12,
                      child: IgnorePointer(
                          child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeOut,
                              child: showTypingIndicator
                                  ? const Align(
                                      key: ValueKey('thinking_indicator'),
                                      alignment: Alignment.centerLeft,
                                      child: AskAiTypingIndicator(text: 'Thinking...'))
                                  : const SizedBox.shrink(key: ValueKey('thinking_empty')))))
                ]));
}
