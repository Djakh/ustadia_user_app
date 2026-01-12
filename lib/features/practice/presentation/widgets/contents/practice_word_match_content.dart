import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/next_task_bloc/next_task_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/practice_word_match_card.dart';

class PracticeWordMatchContent extends StatefulWidget {
  final List<(String, String)> wordMatchPairs;
  const PracticeWordMatchContent({super.key, required this.wordMatchPairs});

  @override
  State<PracticeWordMatchContent> createState() => PracticeWordMatchContentState();
}

class PracticeWordMatchContentState extends State<PracticeWordMatchContent> {
  late final List<PracticeWordMatchCardData> cards;
  late List<WordMatchCardState> states;
  final List<int> _selected = [];
  bool _lock = false;
  int matchedCount = 0;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    cards = _buildCards();
    states = List<WordMatchCardState>.filled(cards.length, WordMatchCardState.idle);
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
  }

  /// --- Methods ---

  List<PracticeWordMatchCardData> _buildCards() {
    final list = <PracticeWordMatchCardData>[];
    for (var i = 0; i < widget.wordMatchPairs.length; i++) {
      list.add(PracticeWordMatchCardData(pairId: i, text: widget.wordMatchPairs[i].$1));
      list.add(PracticeWordMatchCardData(pairId: i, text: widget.wordMatchPairs[i].$2));
    }
    list.shuffle(Random());
    return list;
  }

  void onTapCard(int index) {
    if (_lock || states[index] == WordMatchCardState.matched || _selected.contains(index)) return;

    setState(() {
      states[index] = WordMatchCardState.selected;
      _selected.add(index);
    });

    if (_selected.length == 2) _evaluate();
  }

  void _evaluate() {
    final first = _selected[0];
    final second = _selected[1];
    final isMatch = cards[first].pairId == cards[second].pairId;

    if (isMatch) {
      setState(() {
        states[first] = WordMatchCardState.matched;
        states[second] = WordMatchCardState.matched;
        _selected.clear();
        matchedCount += 2;
      });
      if (matchedCount == cards.length) {
        context.read<NextTaskBloc>().setCurrentTaskCompleted(true, isAnswerCorrect: true);
      }
      return;
    }

    setState(() {
      states[first] = WordMatchCardState.wrong;
      states[second] = WordMatchCardState.wrong;
      _lock = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        states[first] = WordMatchCardState.idle;
        states[second] = WordMatchCardState.idle;
        _selected.clear();
        _lock = false;
      });
    });
  }

  /// --- Widgets ---

  Widget gridList(BuildContext context) => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5),
      itemCount: cards.length,
      itemBuilder: (context, index) =>
          PracticeWordMatchCard(data: cards[index], state: states[index], onTap: () => onTapCard(index)));

  Widget get instruction => Text('Tap a pair that belongs together.',
      style: Style.small3w4(context, color: TextColorRole.greyColor));

  @override
  Widget build(BuildContext context) => Column(
        children: [gridList(context), const SizedBox(height: 20), instruction],
      );
}
