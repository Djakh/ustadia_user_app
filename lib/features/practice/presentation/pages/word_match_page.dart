import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/word_match_card.dart';

class WordMatchPage extends StatefulWidget {
  const WordMatchPage({super.key});

  @override
  State<WordMatchPage> createState() => _WordMatchPageState();
}

class _WordMatchPageState extends State<WordMatchPage> {
  late final List<WordMatchCardData> cards;
  late List<WordMatchCardState> states;
  final List<int> _selected = [];
  bool _lock = false;

  List<WordMatchCardData> buildCards() {
    const pairs = [
      ('Dog', 'Собака'),
      ('Cat', 'Кошка'),
      ('Water', 'Вода'),
      ('Book', 'Книга'),
    ];
    final list = <WordMatchCardData>[];
    for (var i = 0; i < pairs.length; i++) {
      list.add(WordMatchCardData(pairId: i, text: pairs[i].$1));
      list.add(WordMatchCardData(pairId: i, text: pairs[i].$2));
    }
    list.shuffle(Random());
    return list;
  }

  @override
  void initState() {
    super.initState();
    cards = buildCards();
    states = List<WordMatchCardState>.filled(cards.length, WordMatchCardState.idle);
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
      });
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

  Widget gridList(BuildContext context) => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5),
      itemCount: cards.length,
      itemBuilder: (context, index) =>
          WordMatchCard(data: cards[index], state: states[index], onTap: () => onTapCard(index)));

  Widget get instruction => Text('Tap a pair that belongs together.',
      style: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget get view => PrimaryBackground(
      title: 'Word match',
      child: Column(children: [
        const SizedBox(height: 12),
        gridList(context),
        const SizedBox(height: 20),
        instruction
      ]));

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: context.cs.surface, body: SafeArea(child: view));
}
