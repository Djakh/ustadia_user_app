import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/word_match_content.dart';

class WordMatchPage extends StatelessWidget {
  const WordMatchPage({super.key});

  /// --- Data ---

  List<(String, String)> get pairs => const [
        ('Dog', 'Собака'),
        ('Cat', 'Кошка'),
        ('Water', 'Вода'),
        ('Book', 'Книга'),
      ];

  /// --- Widgets ---

  Widget get view => PrimaryBackground(
      title: 'Word match',
      child: Column(children: [
        const SizedBox(height: 24),
        WordMatchContent(wordMatchPairs: pairs),
      ]));

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: context.cs.surface, body: SafeArea(child: view));
}
