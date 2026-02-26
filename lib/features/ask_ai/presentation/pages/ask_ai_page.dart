import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_bloc.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_event.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/pages/topics_page.dart';

class AskAiPage extends StatefulWidget {
  const AskAiPage({super.key});

  @override
  State<AskAiPage> createState() => AskAiPageState();
}

class AskAiPageState extends State<AskAiPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      context.read<AskAiBloc>().add(const AskAiTopicsRequested());
    });
  }

  @override
  Widget build(BuildContext context) => const TopicsPage();
}
