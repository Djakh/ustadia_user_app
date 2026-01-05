import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_build_sentence_content.dart';

class PracticeBuildSentencePage extends StatelessWidget {
  const PracticeBuildSentencePage({super.key});

  /// --- Data ---

  List<String> get correctOrder => const ['I', 'go', 'to', 'school', 'every', 'day'];

  /// --- Widgets ---

  Widget get view => PrimaryBackground(
      title: 'Build the sentence',
      child: Center(child: PracticeBuildSentenceContent(correctOrder: correctOrder)));

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: context.cs.surface, body: SafeArea(child: view));
}
