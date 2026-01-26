import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/next_task_bloc/next_task_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/practice_word_match_card.dart';

class PracticeWordMatchContent extends StatefulWidget {
  final List<PracticeWordMatchCardData> sources;
  final List<PracticeWordMatchCardData> targets;
  final VoidCallback? onCompleted;
  const PracticeWordMatchContent(
      {super.key, required this.sources, required this.targets, this.onCompleted});

  @override
  State<PracticeWordMatchContent> createState() => PracticeWordMatchContentState();
}

class PracticeWordMatchContentState extends State<PracticeWordMatchContent> {
  late final List<PracticeWordMatchCardData> sources;
  late final List<PracticeWordMatchCardData> targets;
  late final List<PracticeWordMatchCardData> cards;
  late final int sourceCount;
  late List<WordMatchCardState> states;
  final List<int> _selected = [];
  bool _lock = false;
  int matchedCount = 0;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    sources = [...widget.sources]..shuffle(Random());
    targets = [...widget.targets]..shuffle(Random());
    cards = [...sources, ...targets];
    sourceCount = sources.length;
    states = List<WordMatchCardState>.filled(cards.length, WordMatchCardState.idle);
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
  }

  /// --- Methods ---

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
        widget.onCompleted?.call();
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
  Widget wordList(List<PracticeWordMatchCardData> list, int offset) => Column(
        children: List.generate(
            list.length,
            (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PracticeWordMatchCard(
                    data: list[index],
                    state: states[offset + index],
                    onTap: () => onTapCard(offset + index)))),
      );

  Widget gridList(BuildContext context) => Row(children: [
        Expanded(child: wordList(sources, 0)),
        const SizedBox(width: 12),
        Expanded(child: wordList(targets, sourceCount)),
      ]);

  Widget get instruction => Text('Tap a pair that belongs together.',
      style: Style.small3w4(context, color: TextColorRole.greyColor));

  @override
  Widget build(BuildContext context) => Column(
        children: [gridList(context), const SizedBox(height: 20), instruction],
      );
}
