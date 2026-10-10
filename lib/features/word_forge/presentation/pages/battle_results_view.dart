import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/content/word_forge_content.dart';
import '../../domain/sandbox/sandbox_progression.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/buff_chips.dart';
import '../widgets/spell_chooser.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import 'spellbook_page.dart';

/// Results, rewards and word progress after a battle.
class BattleResultsView extends StatelessWidget {
  final BattleOutcomeSummary summary;
  final WordForgeContent content;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const BattleResultsView({
    super.key,
    required this.summary,
    required this.content,
    required this.onContinue,
    required this.onRetry,
  });

  String _time(double seconds) {
    final total = seconds.round();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final victory = summary.victory;
    final result = summary.result;
    final accent = victory ? WfColors.gold : WfColors.resonance;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.78),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(offset: Offset(0, (1 - value) * 30), child: child),
                ),
                child: WfPanel(
                  glow: accent,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        (victory ? WfStrings.victory : WfStrings.defeat).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: WfText.display(30, color: accent, spacing: 3)
                            .copyWith(shadows: WfFx.textGlow(accent.withValues(alpha: 0.7), 22)),
                      ),
                      const SizedBox(height: 14),
                      if (victory) ...[
                        Center(child: _AnimatedStars(stars: summary.stars)),
                        const SizedBox(height: 12),
                        _Objectives(summary: summary),
                      ] else
                        Text(WfStrings.defeatEncouragement, textAlign: TextAlign.center, style: WfText.body(14.5)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _Stat(label: WfStrings.accuracy, value: '${(result.accuracy * 100).round()}%'),
                          _Stat(label: WfStrings.bestCombo, value: '×${result.maxCombo}'),
                          _Stat(label: WfStrings.time, value: _time(result.durationSeconds)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _XpBlock(summary: summary),
                      if (summary.witnessedSpellId != null && content.combat.move(summary.witnessedSpellId!) != null) ...[
                        const SizedBox(height: 18),
                        _Heading(WfStrings.witnessed),
                        const SizedBox(height: 8),
                        SpecialSpellCard(spell: content.combat.move(summary.witnessedSpellId!)!, compact: true),
                        const SizedBox(height: 6),
                        Text(WfStrings.witnessedHint, textAlign: TextAlign.center, style: WfText.body(12.5)),
                      ],
                      if (summary.buffsGained.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _Heading(WfStrings.rewards),
                        const SizedBox(height: 8),
                        BuffChips(buffs: summary.buffsGained, showPlus: true),
                      ],
                      if (summary.discoveredWordIds.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _Heading(WfStrings.newWords),
                        const SizedBox(height: 8),
                        _WordWrap(ids: summary.discoveredWordIds, content: content, color: WfColors.gold),
                      ],
                      if (summary.masteryChanges.any((change) => change.to > change.from && change.from > 0)) ...[
                        const SizedBox(height: 18),
                        _Heading(WfStrings.masteryUp),
                        const SizedBox(height: 8),
                        for (final change in summary.masteryChanges.where((c) => c.to > c.from && c.from > 0).take(5))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text((content.words[change.wordId]?.text ?? change.wordId).toUpperCase(),
                                      style: WfText.rune(14.5)),
                                ),
                                MasteryStars(level: change.to, size: 14),
                              ],
                            ),
                          ),
                      ],
                      if (summary.reviewWordIds.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _Heading(WfStrings.toReview),
                        const SizedBox(height: 8),
                        _WordWrap(ids: summary.reviewWordIds.take(8).toList(), content: content, color: WfColors.ember),
                      ],
                      const SizedBox(height: 24),
                      if (victory) ...[
                        WfButton(label: WfStrings.continueLabel, glyph: WfGlyphType.forward, onTap: onContinue),
                        const SizedBox(height: 10),
                        WfButton(label: WfStrings.replayBattle, style: WfButtonStyle.secondary, onTap: onRetry),
                      ] else ...[
                        WfButton(label: WfStrings.retry, glyph: WfGlyphType.secondChance, onTap: onRetry),
                        const SizedBox(height: 10),
                        WfButton(label: WfStrings.backToMap, style: WfButtonStyle.secondary, onTap: onContinue),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Why the stars were (not) earned: one line per objective.
class _Objectives extends StatelessWidget {
  final BattleOutcomeSummary summary;

  const _Objectives({required this.summary});

  @override
  Widget build(BuildContext context) {
    final result = summary.result;
    final rating = context.read<WordForgeCubit>().dependencies.progression.starRating;
    final accuracy = (result.accuracy * 100).round();
    final rows = [
      (WfStrings.objectiveVictory, true),
      (WfStrings.objectiveAccuracy(accuracy, (rating.accuracyForStar * 100).round()), rating.accuracyStar(result)),
      (WfStrings.objectiveTurns(summary.attackTurns, summary.turnBudget), rating.efficiencyStar(result, summary.turnBudget)),
    ];
    return Column(
      children: [
        for (final (label, done) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WfGlyph(done ? WfGlyphType.check : WfGlyphType.close, size: 14, color: done ? WfColors.gold : WfColors.textMute),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: WfText.body(13, color: done ? WfColors.text : WfColors.textMute)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnimatedStars extends StatelessWidget {
  final int stars;

  const _AnimatedStars({required this.stars});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 500 + i * 220),
              curve: Interval(i * 0.25, 1, curve: Curves.elasticOut),
              builder: (context, value, child) => Transform.scale(scale: i < stars ? value : 1, child: child),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: i == 1 ? 0 : 10),
                child: WfGlyph(
                  WfGlyphType.star,
                  size: i == 1 ? 58 : 46,
                  color: i < stars ? WfColors.gold : Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
        ],
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: WfText.title(20)),
            const SizedBox(height: 3),
            Text(label.toUpperCase(), textAlign: TextAlign.center, style: WfText.label(10)),
          ],
        ),
      );
}

class _XpBlock extends StatelessWidget {
  final BattleOutcomeSummary summary;

  const _XpBlock({required this.summary});

  @override
  Widget build(BuildContext context) {
    final after = summary.levelAfter;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const WfGlyph(WfGlyphType.bolt, size: 16, color: WfColors.gold),
              const SizedBox(width: 6),
              Text('+${summary.xpGained} ${WfStrings.xp}', style: WfText.title(16, color: WfColors.gold)),
              const Spacer(),
              if (summary.leveledUp)
                WfTag('${WfStrings.levelUp} ${after.level}', color: WfColors.life)
              else
                Text('${WfStrings.level} ${after.level}', style: WfText.body(13)),
            ],
          ),
          const SizedBox(height: 10),
          WfProgressBar(value: after.progress),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: WfText.label(11));
}

class _WordWrap extends StatelessWidget {
  final List<String> ids;
  final WordForgeContent content;
  final Color color;

  const _WordWrap({required this.ids, required this.content, required this.color});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final id in ids)
            if (content.words[id] case final word?)
              WfPressable(
                onTap: () => showSpellDetails(context,
                        word: word, stats: context.read<WordForgeCubit>().state.save?.words[word.id])
                    .ignore(),
                semanticsLabel: word.text,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.55)),
                  ),
                  child: Text(word.text.toUpperCase(), style: WfText.rune(13.5)),
                ),
              ),
        ],
      );
}
