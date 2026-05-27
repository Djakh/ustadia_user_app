import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/features/ask_ai/data/datasources/ai_chat_remote_data_source.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_bloc.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_event.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_state.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_conversation_content.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_messages_panel.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_page_app_bar.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_text_message_composer.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_voice_agent_section.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_voice_controls.dart';
import 'package:ustadia_user_app/features/ask_ai/state/voice_call_notifier.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/injection_container.dart';

class VoiceAgentPage extends StatefulWidget {
  final AiChatTopicModel topic;

  const VoiceAgentPage({super.key, required this.topic});

  @override
  State<VoiceAgentPage> createState() => VoiceAgentPageState();
}

class VoiceAgentPageState extends State<VoiceAgentPage> with WidgetsBindingObserver {
  static const double messagesTopPadding = 204;
  static const double voiceControlsBottomPadding = 132;
  static const double textComposerBottomPadding = 148;
  static const Duration assistantResponseTimeout = Duration(seconds: 10);
  static const int maxInitialAssistantSyncAttempts = 5;
  static const Duration voiceStartupDelay = Duration(milliseconds: 450);
  static const Duration shutdownDelay = Duration(milliseconds: 420);
  static const Duration initialAssistantFirstSyncDelay = Duration(milliseconds: 1400);
  static const Duration initialAssistantRetryDelay = Duration(milliseconds: 2400);
  static const Duration assistantTurnSyncDelay = Duration(milliseconds: 1100);
  static const Duration latestMessagesSyncThrottle = Duration(milliseconds: 1200);
  static const Duration blockedMessagesSyncRetryDelay = Duration(milliseconds: 800);

  final ScrollController scrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  late final VoiceCallNotifier voiceCallNotifier;

  io.Socket? socket;
  Timer? callLimitTimer;
  Timer? initialMessagesSyncTimer;
  Timer? assistantResponseTimer;
  Timer? assistantTurnMessagesSyncTimer;
  Timer? voiceStartupTimer;
  Timer? shutdownTimer;
  int remainingSeconds = 0;
  int currentPage = 1;
  bool hasMoreMessages = true;
  bool isPaginating = false;
  bool socketConnected = false;
  bool waitingForAssistantResponse = false;
  bool initialAssistantSyncCompleted = false;
  int initialAssistantSyncAttempts = 0;
  bool lastAssistantSpeaking = false;
  bool textComposerVisible = false;
  bool isClosing = false;
  bool shutdownScheduled = false;
  DateTime? lastLatestMessagesRequestAt;
  static const int pageLimit = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    remainingSeconds = widget.topic.duration > 0 ? widget.topic.duration * 60 : 0;
    scrollController.addListener(onScroll);
    voiceCallNotifier = VoiceCallNotifier(
        aiChatRemoteDataSource: sl<AiChatRemoteDataSource>(), topicId: widget.topic.id);
    voiceCallNotifier.addListener(handleVoiceNotifierChanged);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      context.read<AskAiBloc>().add(AskAiTopicOpened(topic: widget.topic));
      startCallLimitTimer();
      schedulePageStartup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    callLimitTimer?.cancel();
    initialMessagesSyncTimer?.cancel();
    assistantResponseTimer?.cancel();
    assistantTurnMessagesSyncTimer?.cancel();
    voiceStartupTimer?.cancel();
    scrollController.removeListener(onScroll);
    scrollController.dispose();
    messageController.dispose();
    messageFocusNode.dispose();
    voiceCallNotifier.removeListener(handleVoiceNotifierChanged);
    scheduleBackgroundShutdown();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isClosing) return;
    if (state == AppLifecycleState.paused) {
      unawaited(disconnectSocket());
      unawaited(voiceCallNotifier.onAppPaused());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      connectSocket();
      if (voiceCallNotifier.isConnected) {
        unawaited(voiceCallNotifier.onAppResumed());
      } else {
        unawaited(connectVoice());
      }
    }
  }

  bool get hasTimeLimit => widget.topic.duration > 0;

  void startCallLimitTimer() {
    if (!hasTimeLimit || remainingSeconds <= 0) return;
    callLimitTimer?.cancel();
    callLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingSeconds <= 1) {
        setState(() => remainingSeconds = 0);
        timer.cancel();
        beginClosing();
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }
      setState(() => remainingSeconds -= 1);
    });
  }

  void schedulePageStartup() {
    voiceStartupTimer?.cancel();
    Future.microtask(() {
      if (!mounted || isClosing) return;
      connectSocket();
    });
    voiceStartupTimer = Timer(voiceStartupDelay, () {
      if (!mounted || isClosing) return;
      unawaited(connectVoice());
    });
  }

  Future<void> connectVoice() async {
    if (isClosing) return;
    if (voiceCallNotifier.isConnected || voiceCallNotifier.isConnecting) return;
    await voiceCallNotifier.connect();
  }

  void connectSocket() {
    if (isClosing) return;
    final currentSocket = socket;
    if (currentSocket != null) {
      if (!currentSocket.connected) currentSocket.connect();
      return;
    }
    final token = sl<AuthLocalDataSource>().getAccessToken();
    final baseUrl = sl<AiChatRemoteDataSource>().dio.options.baseUrl;
    if (token.isEmpty || baseUrl.isEmpty) return;

    final nextSocket = io.io(
        '$baseUrl/ai-chat',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io')
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build());

    nextSocket.onConnect((_) {
      if (!mounted || isClosing) return;
      setState(() => socketConnected = true);
      scheduleInitialMessagesSync();
    });
    nextSocket.onDisconnect((_) {
      if (!mounted || isClosing) return;
      setState(() => socketConnected = false);
    });
    nextSocket.onConnectError((error) {
      debugPrint('[AskAiSocket] connect_error: $error');
      if (!mounted || isClosing) return;
      setState(() => socketConnected = false);
    });
    nextSocket.on('ai_chat_connected', (_) {
      if (!mounted || isClosing) return;
      setState(() => socketConnected = true);
      scheduleInitialMessagesSync();
    });
    nextSocket.on('ai_chat_error', (error) {
      debugPrint('[AskAiSocket] ai_chat_error: $error');
      if (mounted && waitingForAssistantResponse) {
        clearAssistantWaitingState();
      }
    });
    nextSocket.on('newMessage', (payload) {
      if (payload is! Map) return;
      final data = Map<String, dynamic>.from(payload);
      if (data['topicId']?.toString() != widget.topic.id) return;
      final message = AiChatMessageModel.fromJson(data);
      context.read<AskAiBloc>().add(AskAiMessageReceived(message: message));
      if (message.role == 'assistant' && waitingForAssistantResponse && mounted) {
        clearAssistantWaitingState();
      }
      if (message.role == 'user' && !waitingForAssistantResponse && mounted) {
        startAssistantWaitingState();
      }
      if (message.isFinished) {
        voiceCallNotifier.setMicrophoneEnabled(false);
      }
      if (scrollController.hasClients && scrollController.offset < 120) {
        scrollController.animateTo(0,
            duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
      }
    });

    socket = nextSocket;
    nextSocket.connect();
  }

  Future<void> disconnectSocket({bool updateState = true}) async {
    final currentSocket = socket;
    socket = null;
    if (currentSocket == null) return;
    currentSocket.dispose();
    if (updateState && mounted && !isClosing) {
      setState(() => socketConnected = false);
    }
  }

  void beginClosing() {
    if (isClosing) return;
    isClosing = true;
    callLimitTimer?.cancel();
    initialMessagesSyncTimer?.cancel();
    assistantResponseTimer?.cancel();
    assistantTurnMessagesSyncTimer?.cancel();
    voiceStartupTimer?.cancel();
    voiceCallNotifier.removeListener(handleVoiceNotifierChanged);
    scheduleBackgroundShutdown();
  }

  void scheduleBackgroundShutdown() {
    if (shutdownScheduled) return;
    shutdownScheduled = true;
    final currentSocket = socket;
    socket = null;
    shutdownTimer = Timer(shutdownDelay, () {
      currentSocket?.dispose();
      voiceCallNotifier.dispose();
    });
  }

  void handleVoiceNotifierChanged() {
    if (!mounted) return;
    if (voiceCallNotifier.assistantSpeaking) {
      clearAssistantWaitingState();
      scheduleInitialMessagesSync();
    }
    if (lastAssistantSpeaking &&
        !voiceCallNotifier.assistantSpeaking &&
        !initialAssistantSyncCompleted) {
      scheduleInitialMessagesSync();
    }
    if (lastAssistantSpeaking && !voiceCallNotifier.assistantSpeaking) {
      scheduleAssistantTurnMessagesSync();
    }
    lastAssistantSpeaking = voiceCallNotifier.assistantSpeaking;
  }

  void scheduleInitialMessagesSync() {
    if (initialAssistantSyncCompleted) return;
    if (initialAssistantSyncAttempts >= maxInitialAssistantSyncAttempts) return;
    final blocState = context.read<AskAiBloc>().state;
    final hasAssistantMessage = blocState.messages.any((message) => message.role == 'assistant');
    if (hasAssistantMessage) {
      initialAssistantSyncCompleted = true;
      initialMessagesSyncTimer?.cancel();
      return;
    }
    initialMessagesSyncTimer?.cancel();
    initialMessagesSyncTimer = Timer(initialAssistantFirstSyncDelay, syncLatestMessages);
  }

  void syncLatestMessages() {
    if (!mounted || isClosing || initialAssistantSyncCompleted) return;
    final blocState = context.read<AskAiBloc>().state;
    final hasAssistantMessage = blocState.messages.any((message) => message.role == 'assistant');
    if (hasAssistantMessage) {
      initialAssistantSyncCompleted = true;
      initialMessagesSyncTimer?.cancel();
      return;
    }
    final didRequest = requestLatestMessages(force: initialAssistantSyncAttempts == 0);
    if (didRequest) {
      initialAssistantSyncAttempts += 1;
    }
    if (!initialAssistantSyncCompleted &&
        initialAssistantSyncAttempts < maxInitialAssistantSyncAttempts) {
      initialMessagesSyncTimer?.cancel();
      initialMessagesSyncTimer = Timer(
          didRequest ? initialAssistantRetryDelay : blockedMessagesSyncRetryDelay,
          syncLatestMessages);
    }
  }

  void scheduleAssistantTurnMessagesSync() {
    assistantTurnMessagesSyncTimer?.cancel();
    assistantTurnMessagesSyncTimer = Timer(assistantTurnSyncDelay, syncMessagesAfterAssistantTurn);
  }

  void syncMessagesAfterAssistantTurn() {
    requestLatestMessages(force: true);
  }

  bool requestLatestMessages({bool force = false}) {
    if (!mounted || isClosing) return false;
    final bloc = context.read<AskAiBloc>();
    if (bloc.state.messagesStatus.isLoading) return false;
    final now = DateTime.now();
    final lastRequestAt = lastLatestMessagesRequestAt;
    if (!force &&
        lastRequestAt != null &&
        now.difference(lastRequestAt) < latestMessagesSyncThrottle) {
      return false;
    }
    lastLatestMessagesRequestAt = now;
    bloc.add(AskAiMessagesRequested(topicId: widget.topic.id, page: 1, limit: pageLimit));
    return true;
  }

  void onScroll() {
    if (!scrollController.hasClients) return;
    const threshold = 200.0;
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
    context
        .read<AskAiBloc>()
        .add(AskAiMessagesRequested(topicId: widget.topic.id, page: currentPage, limit: pageLimit));
    if (mounted) setState(() {});
  }

  Future<void> onMicTap() async {
    final isStoppingTurn = voiceCallNotifier.micEnabled;
    final shouldWaitImmediately = isStoppingTurn &&
        (voiceCallNotifier.userTurnHasSpeech ||
            voiceCallNotifier.userSpeaking ||
            voiceCallNotifier.localSpeaking);
    if (shouldWaitImmediately) {
      startAssistantWaitingState(stopMicrophone: false);
    }
    await voiceCallNotifier.toggleMicrophone();
    if (!mounted) return;
    if (isStoppingTurn) {
      final shouldWait = shouldWaitImmediately || voiceCallNotifier.consumeUserTurnHasSpeech();
      if (shouldWait) {
        startAssistantWaitingState(stopMicrophone: false);
      } else {
        clearAssistantWaitingState();
      }
      return;
    }
    if (waitingForAssistantResponse) {
      clearAssistantWaitingState();
    }
  }

  Future<void> sendTextMessage() async {
    final transcript = messageController.text.trim();
    final languageCode = context.locale.languageCode;
    if (transcript.isEmpty) return;
    if (voiceCallNotifier.micEnabled) {
      await voiceCallNotifier.setMicrophoneEnabled(false);
    }
    final currentSocket = socket;
    if (currentSocket?.connected != true) {
      connectSocket();
      return;
    }
    currentSocket!.emit('sendMessage',
        {'topicId': widget.topic.id, 'transcript': transcript, 'language': languageCode});
    messageController.clear();
    messageFocusNode.unfocus();
    startAssistantWaitingState();
  }

  void startAssistantWaitingState({bool stopMicrophone = true}) {
    assistantResponseTimer?.cancel();
    if (stopMicrophone && voiceCallNotifier.micEnabled) {
      unawaited(voiceCallNotifier.setMicrophoneEnabled(false));
    }
    if (!waitingForAssistantResponse && mounted) {
      setState(() => waitingForAssistantResponse = true);
    }
    assistantResponseTimer = Timer(assistantResponseTimeout, handleAssistantResponseTimeout);
  }

  void clearAssistantWaitingState() {
    assistantResponseTimer?.cancel();
    if (!waitingForAssistantResponse || !mounted) return;
    setState(() => waitingForAssistantResponse = false);
  }

  void handleAssistantResponseTimeout() {
    if (!mounted || !waitingForAssistantResponse) return;
    setState(() => waitingForAssistantResponse = false);
    requestLatestMessages(force: true);
  }

  bool get canTapMicrophone =>
      !waitingForAssistantResponse &&
      !voiceCallNotifier.isMicrophoneTransitioning &&
      (voiceCallNotifier.micEnabled ||
          (voiceCallNotifier.isConnected && !voiceCallNotifier.isConnecting));

  bool get canSendTextMessage =>
      socketConnected && !waitingForAssistantResponse && !voiceCallNotifier.assistantSpeaking;

  double get activeMessagesBottomPadding =>
      textComposerVisible ? textComposerBottomPadding : voiceControlsBottomPadding;

  String microphoneButtonText() {
    if (voiceCallNotifier.isConnecting) return 'Connecting...'.tr();
    if (voiceCallNotifier.assistantSpeaking) return 'Agent is speaking'.tr();
    if (waitingForAssistantResponse) return 'Thinking...'.tr();
    if (voiceCallNotifier.micEnabled) return 'Speak now'.tr();
    return 'Tap microphone'.tr();
  }

  Future<void> onAppBarBack() async {
    if (isClosing) return;
    beginClosing();
    Navigator.of(context).pop();
  }

  String timerValue() {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String statusText(VoiceUiState state) {
    if (state == VoiceUiState.error) return 'Error'.tr();
    if (voiceCallNotifier.isConnecting) return 'Connecting to agent...'.tr();
    if (!socketConnected) return 'Connecting messages...'.tr();
    if (voiceCallNotifier.assistantSpeaking) return 'Speaking'.tr();
    if (waitingForAssistantResponse) return 'Thinking...'.tr();
    if (voiceCallNotifier.micEnabled && voiceCallNotifier.userSpeaking) return 'Listening...'.tr();
    if (voiceCallNotifier.micEnabled) return 'Speak now'.tr();
    if (!voiceCallNotifier.isConnected) return 'Connecting to agent...'.tr();
    return 'Tap microphone'.tr();
  }

  String displayStatusText(VoiceUiState voiceState) {
    final statusValue = statusText(voiceState);
    final errorValue = voiceCallNotifier.errorMessage;
    return voiceState == VoiceUiState.error && errorValue != null ? errorValue : statusValue;
  }

  void showTextComposer() {
    if (voiceCallNotifier.micEnabled) {
      unawaited(voiceCallNotifier.setMicrophoneEnabled(false));
    }
    if (!textComposerVisible && mounted) {
      setState(() => textComposerVisible = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted || !textComposerVisible) return;
      messageFocusNode.requestFocus();
    });
  }

  void showVoiceControls() {
    messageFocusNode.unfocus();
    if (!textComposerVisible || !mounted) return;
    setState(() => textComposerVisible = false);
  }

  void handleMessagesStateChanged(AskAiState state) {
    final hasAssistantMessage = state.messages.any((message) => message.role == 'assistant');
    if (hasAssistantMessage) {
      initialAssistantSyncCompleted = true;
      initialMessagesSyncTimer?.cancel();
      initialAssistantSyncAttempts = 0;
    }
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
  }

  Widget messagesPanel(AskAiState state) => AskAiMessagesPanel(
      messages: state.messages,
      scrollController: scrollController,
      isLoading: state.messagesStatus.isLoading && state.messages.isEmpty,
      isPaginating: isPaginating,
      showTypingIndicator: waitingForAssistantResponse,
      topPadding: messagesTopPadding,
      bottomPadding: activeMessagesBottomPadding,
      errorMessage:
          state.messagesStatus.isError && state.messages.isEmpty ? state.errorMessage : null);

  Widget conversationBody() => BlocConsumer<AskAiBloc, AskAiState>(
      listener: (context, state) => handleMessagesStateChanged(state),
      builder: (context, state) => AskAiConversationContent(
          messagesPanel: messagesPanel(state),
          voiceAgentSection: voiceAgentSection,
          bottomControl: bottomControl));

  Widget loadingBody(BuildContext context) => SafeArea(
      child: Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
                const SizedBox(height: 18),
                Text('Preparing AI agent...'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Opening voice chat'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.white.withValues(alpha: 0.72)))
              ]))));

  Widget body(BuildContext context) => SafeArea(child: conversationBody());

  Widget get voiceAgentSection => AnimatedBuilder(
      animation: voiceCallNotifier,
      builder: (context, child) => AskAiVoiceAgentSection(
          voiceCallNotifier: voiceCallNotifier,
          voiceUiState: voiceCallNotifier.voiceUiState,
          statusText: displayStatusText(voiceCallNotifier.voiceUiState)));

  Widget get voiceControls => AnimatedBuilder(
      animation: voiceCallNotifier,
      builder: (context, child) => AskAiVoiceControls(
          key: const ValueKey('voice_controls'),
          isConnecting:
              voiceCallNotifier.isConnecting || voiceCallNotifier.isMicrophoneTransitioning,
          isRecording: voiceCallNotifier.micEnabled && !waitingForAssistantResponse,
          outputMode: voiceCallNotifier.outputMode,
          labelText: microphoneButtonText(),
          onMicrophoneTap: canTapMicrophone ? onMicTap : null,
          onAudioOutputTap: voiceCallNotifier.toggleAudioOutputMode,
          onKeyboardTap: showTextComposer));

  Widget get textMessageComposer => AnimatedBuilder(
      animation: voiceCallNotifier,
      builder: (context, child) => AskAiTextMessageComposer(
          key: const ValueKey('text_composer'),
          controller: messageController,
          focusNode: messageFocusNode,
          canSend: canSendTextMessage,
          onSend: sendTextMessage,
          onVoiceModeTap: showVoiceControls));

  Widget get bottomControl => AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: textComposerVisible ? textMessageComposer : voiceControls);

  @override
  Widget build(BuildContext context) => GuidedTutorialPage(
      pageId: TutorialPageIds.voiceAgent,
      steps: TutorialPresets.voiceAgent(),
      child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (isClosing) return;
            beginClosing();
            Navigator.of(this.context).pop();
          },
          child: Scaffold(
              backgroundColor: AppColors.secondary,
              appBar: AskAiPageAppBar(
                  title: widget.topic.title,
                  hasTimeLimit: hasTimeLimit,
                  timerText: timerValue(),
                  onBack: onAppBarBack),
              body: body(context))));
}
