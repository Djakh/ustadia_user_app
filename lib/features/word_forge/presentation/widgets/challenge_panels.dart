import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/battle/battle_models.dart';
import '../../domain/battle/combat_config.dart';
import '../../domain/language/answer_validator.dart';
import '../../domain/content/sentence_content.dart';
import '../../domain/language/challenge_type.dart';
import '../../domain/language/language_challenge.dart';
import '../../domain/progression/buffs.dart';
import '../cubit/battle_controller.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import 'buff_chips.dart';
import 'wf_components.dart';
import 'wf_glyph.dart';

/// Chooses the right input panel for the current challenge. New mechanics
/// with a new input style plug in here.
class ChallengePanel extends StatelessWidget {
  final BattleSnapshot snapshot;
  final BattleController controller;

  const ChallengePanel({super.key, required this.snapshot, required this.controller});

  @override
  Widget build(BuildContext context) {
    final challenge = snapshot.challenge;
    final showing = snapshot.phase == BattlePhase.awaitingInput || snapshot.phase == BattlePhase.resolving;
    if (challenge == null || !showing || snapshot.moveKind == null) {
      return const _Channeling();
    }
    return switch (challenge.inputMode) {
      ChallengeInputMode.choice => ChoicePanel(snapshot: snapshot, onPick: controller.submitChoice),
      ChallengeInputMode.match => MatchPanel(snapshot: snapshot, onSelect: controller.selectMatch),
      ChallengeInputMode.arrange => IncantationPanel(
          snapshot: snapshot,
          onPlace: controller.placeToken,
          onRemove: controller.removeToken,
          onUndo: controller.undoToken,
          onClear: controller.clearTokens,
        ),
    };
  }
}

class _Channeling extends StatefulWidget {
  const _Channeling();

  @override
  State<_Channeling> createState() => _ChannelingState();
}

class _ChannelingState extends State<_Channeling> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WfColors.arcane.withValues(
                        alpha: 0.25 + 0.75 * (0.5 + 0.5 * math.sin((_controller.value - i * 0.15) * math.pi * 2))),
                  ),
                ),
            ],
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// Choice challenges (antonym, synonym, missing rune, future text mechanics)
// -----------------------------------------------------------------------------

enum RuneOptionState { idle, dimmed, correct, wrong, revealedAnswer, faded }

class ChoicePanel extends StatelessWidget {
  final BattleSnapshot snapshot;
  final ValueChanged<String> onPick;

  const ChoicePanel({super.key, required this.snapshot, required this.onPick});

  RuneOptionState _stateOf(ChallengeOption option) {
    final success = snapshot.lastTaskSuccess;
    if (snapshot.phase == BattlePhase.resolving && success != null) {
      if (option.id == const AnswerValidator().correctOptionId(snapshot.challenge!)) {
        return success ? RuneOptionState.correct : RuneOptionState.revealedAnswer;
      }
      if (option.id == snapshot.pickedOptionId) return RuneOptionState.wrong;
      return RuneOptionState.faded;
    }
    if (snapshot.dimmedOptionIds.contains(option.id)) return RuneOptionState.dimmed;
    return RuneOptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final challenge = snapshot.challenge!;
    final color = snapshot.targetShielded && snapshot.isPlayerTurn && snapshot.moveKind == MoveKind.normal
        ? WfColors.resonance
        : WfColors.forMove(snapshot.turn, snapshot.moveKind);
    final options = [
      for (final option in challenge.options)
        if (!snapshot.hiddenOptionIds.contains(option.id)) option,
    ];
    final longest = options.fold<int>(0, (length, option) => math.max(length, option.text.length));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (challenge.type == ChallengeType.missingRune)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RuneSentence(snapshot: snapshot),
          ),
        if (snapshot.revealedLetter != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${WfStrings.buffName(BuffType.reveal)}: ${snapshot.revealedLetter}…',
              style: WfText.title(14, color: WfColors.arcane),
            ),
          ),
        LayoutBuilder(builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 300 && longest <= 14;
          final columns = twoColumns ? 2 : 1;
          const spacing = 10.0;
          final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final option in options)
                SizedBox(
                  width: options.length.isOdd && option == options.last && twoColumns ? constraints.maxWidth : width,
                  child: RuneOptionButton(
                    text: option.text,
                    state: _stateOf(option),
                    accent: color,
                    enabled: snapshot.acceptsInput && !snapshot.dimmedOptionIds.contains(option.id),
                    onTap: () => onPick(option.id),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

/// Large tappable "rune tablet" answer.
class RuneOptionButton extends StatefulWidget {
  final String text;
  final RuneOptionState state;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  const RuneOptionButton({
    super.key,
    required this.text,
    required this.state,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<RuneOptionButton> createState() => _RuneOptionButtonState();
}

class _RuneOptionButtonState extends State<RuneOptionButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(RuneOptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == RuneOptionState.wrong && oldWidget.state != RuneOptionState.wrong) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final (Color border, Color fill, Color text, double glow) = switch (state) {
      RuneOptionState.idle => (widget.accent.withValues(alpha: 0.55), WfColors.panelHigh, WfColors.text, 0.0),
      RuneOptionState.dimmed => (Colors.white12, WfColors.panel, WfColors.textMute.withValues(alpha: 0.5), 0.0),
      RuneOptionState.correct => (WfColors.brand, const Color(0xFF125A3A), Colors.white, 0.6),
      RuneOptionState.wrong => (WfColors.danger, const Color(0xFF4A1426), Colors.white, 0.4),
      RuneOptionState.revealedAnswer => (WfColors.gold, const Color(0xFF4A3A12), Colors.white, 0.5),
      RuneOptionState.faded => (Colors.white10, WfColors.panel, WfColors.textMute, 0.0),
    };
    final glowColor = state == RuneOptionState.wrong
        ? WfColors.danger
        : (state == RuneOptionState.revealedAnswer ? WfColors.gold : WfColors.brand);
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      child: WfPressable(
        onTap: widget.enabled ? widget.onTap : null,
        semanticsLabel: widget.text,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(fill, Colors.white, 0.06)!, fill],
            ),
            border: Border.all(color: border, width: state == RuneOptionState.idle ? 1.4 : 2),
            boxShadow: [
              if (glow > 0) ...WfFx.shadow(glowColor.withValues(alpha: glow), blurRadius: 20),
              ...WfFx.shadow(const Color(0x55000000), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.text.toUpperCase(),
                textAlign: TextAlign.center,
                style: WfText.rune(19, color: text).copyWith(
                  decoration: state == RuneOptionState.dimmed ? TextDecoration.lineThrough : null,
                  decorationColor: WfColors.textMute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The incomplete spell sentence for Missing Rune.
class RuneSentence extends StatelessWidget {
  final BattleSnapshot snapshot;

  const RuneSentence({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final challenge = snapshot.challenge!;
    final success = snapshot.lastTaskSuccess;
    final resolving = snapshot.phase == BattlePhase.resolving && success != null;
    final parts = challenge.prompt.split(runeBlank);
    final filled = resolving ? challenge.correctAnswer : null;
    final slotColor = resolving ? (success ? WfColors.brand : WfColors.gold) : WfColors.brand;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WfColors.arcane.withValues(alpha: 0.35)),
      ),
      child: Text.rich(
        TextSpan(
          style: WfText.title(19, color: WfColors.text, weight: FontWeight.w500).copyWith(height: 1.5),
          children: [
            TextSpan(text: parts.first),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                constraints: const BoxConstraints(minWidth: 64),
                decoration: BoxDecoration(
                  color: slotColor.withValues(alpha: filled == null ? 0.08 : 0.22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: slotColor, width: 1.5),
                ),
                child: Text(filled ?? ' ', textAlign: TextAlign.center, style: WfText.title(19, color: Colors.white)),
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts.sublist(1).join(runeBlank)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Incantation (sentence construction)
// -----------------------------------------------------------------------------

class IncantationPanel extends StatelessWidget {
  final BattleSnapshot snapshot;
  final ValueChanged<String> onPlace;
  final ValueChanged<String> onRemove;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  const IncantationPanel({
    super.key,
    required this.snapshot,
    required this.onPlace,
    required this.onRemove,
    required this.onUndo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final challenge = snapshot.challenge!;
    final placed = snapshot.placedOptionIds;
    final resolving = snapshot.phase == BattlePhase.resolving && snapshot.lastTaskSuccess != null;
    final success = resolving && snapshot.lastTaskSuccess!;
    final terminator = challenge.metadata['terminator'] ?? '';
    final pool = [for (final option in challenge.options) if (!placed.contains(option.id)) option];
    final empty = challenge.options.length - placed.length;
    final slotColor = resolving ? (success ? WfColors.gold : WfColors.danger) : WfColors.gold;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Incantation area.
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: slotColor.withValues(alpha: success ? 0.9 : 0.45), width: success ? 2 : 1.2),
            boxShadow: success ? [...WfFx.shadow(WfColors.gold.withValues(alpha: 0.4), blurRadius: 22)] : null,
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final id in placed)
                _Token(
                  text: challenge.option(id)!.text,
                  placed: true,
                  glow: success,
                  onTap: snapshot.acceptsInput ? () => onRemove(id) : null,
                ),
              for (var i = 0; i < empty; i++) const _EmptySlot(),
              if (terminator.isNotEmpty) Text(terminator, style: WfText.rune(20, color: WfColors.gold)),
            ],
          ),
        ),
        if (resolving && !success) ...[
          const SizedBox(height: 8),
          Text(challenge.metadata['sentence'] ?? challenge.correctAnswer,
              textAlign: TextAlign.center, style: WfText.title(15, color: WfColors.gold)),
        ],
        const SizedBox(height: 12),
        // Word pool. Placed words keep their space so the remaining words never jump.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in challenge.options)
              Visibility(
                visible: pool.contains(option),
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _Token(
                  text: option.text,
                  placed: false,
                  hinted: snapshot.hintedOptionId == option.id,
                  justEaten: snapshot.eatenOptionId == option.id,
                  onTap: snapshot.acceptsInput && pool.contains(option) ? () => onPlace(option.id) : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallAction(glyph: WfGlyphType.undo, label: WfStrings.undo, onTap: snapshot.acceptsInput && placed.isNotEmpty ? onUndo : null),
            const SizedBox(width: 12),
            _SmallAction(glyph: WfGlyphType.clear, label: WfStrings.clear, onTap: snapshot.acceptsInput && placed.isNotEmpty ? onClear : null),
          ],
        ),
      ],
    );
  }
}

class _Token extends StatelessWidget {
  final String text;
  final bool placed;
  final bool hinted;
  final bool justEaten;
  final bool glow;
  final VoidCallback? onTap;

  const _Token({
    required this.text,
    required this.placed,
    this.hinted = false,
    this.justEaten = false,
    this.glow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = hinted
        ? WfColors.gold
        : (justEaten ? WfColors.ember : (placed ? WfColors.gold.withValues(alpha: 0.7) : WfColors.arcane.withValues(alpha: 0.6)));
    return WfPressable(
      onTap: onTap,
      semanticsLabel: text,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 46, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: placed ? const Color(0xFF3A3016) : WfColors.panelHigh,
          border: Border.all(color: border, width: hinted || justEaten ? 2.2 : 1.3),
          boxShadow: [
            if (hinted || glow) ...WfFx.shadow(WfColors.gold.withValues(alpha: 0.55), blurRadius: 16),
            if (justEaten) ...WfFx.shadow(WfColors.ember.withValues(alpha: 0.5), blurRadius: 14),
          ],
        ),
        child: Text(text.toUpperCase(), style: WfText.rune(16.5, color: WfColors.text)),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1.2),
          color: Colors.white.withValues(alpha: 0.03),
        ),
      );
}

class _SmallAction extends StatelessWidget {
  final WfGlyphType glyph;
  final String label;
  final VoidCallback? onTap;

  const _SmallAction({required this.glyph, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => WfPressable(
        onTap: onTap,
        semanticsLabel: label,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: WfColors.panel,
              border: Border.all(color: WfColors.stroke),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WfGlyph(glyph, size: 16, color: WfColors.textDim),
                const SizedBox(width: 6),
                Text(label, style: WfText.title(13, color: WfColors.textDim, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// Word Match (critical mini-game)
// -----------------------------------------------------------------------------

class MatchPanel extends StatelessWidget {
  final BattleSnapshot snapshot;
  final ValueChanged<String> onSelect;

  const MatchPanel({super.key, required this.snapshot, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final challenge = snapshot.challenge!;
    final lefts = [for (final option in challenge.options) if (challenge.isLeft(option.id)) option];
    final rights = [for (final option in challenge.options) if (!challenge.isLeft(option.id)) option];
    final hinted = snapshot.hintedOptionId;
    final hintedPartner = hinted == null ? null : challenge.pairs[hinted];
    final resolving = snapshot.phase == BattlePhase.resolving;
    Widget column(List<ChallengeOption> options) => Column(
          children: [
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MatchTile(
                  text: option.text,
                  matched: snapshot.matchedOptionIds.contains(option.id),
                  selected: snapshot.selectedOptionId == option.id,
                  missed: snapshot.missedOptionId == option.id,
                  hinted: option.id == hinted || option.id == hintedPartner,
                  failed: resolving && snapshot.lastTaskSuccess == false,
                  onTap: snapshot.acceptsInput ? () => onSelect(option.id) : null,
                ),
              ),
          ],
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(lefts)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          child: WfGlyph(WfGlyphType.secondChance, size: 18, color: WfColors.textMute),
        ),
        Expanded(child: column(rights)),
      ],
    );
  }
}

class _MatchTile extends StatefulWidget {
  final String text;
  final bool matched;
  final bool selected;
  final bool missed;
  final bool hinted;
  final bool failed;
  final VoidCallback? onTap;

  const _MatchTile({
    required this.text,
    required this.matched,
    required this.selected,
    required this.missed,
    required this.hinted,
    required this.failed,
    required this.onTap,
  });

  @override
  State<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends State<_MatchTile> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  @override
  void didUpdateWidget(_MatchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.missed && !oldWidget.missed) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.matched
        ? WfColors.brand
        : widget.selected
            ? WfColors.gold
            : (widget.missed ? WfColors.danger : (widget.hinted ? WfColors.gold : WfColors.gold.withValues(alpha: 0.45)));
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(math.sin(_shake.value * math.pi * 6) * 7 * (1 - _shake.value), 0),
        child: child,
      ),
      child: WfPressable(
        onTap: widget.matched ? null : widget.onTap,
        semanticsLabel: widget.text,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.matched ? const Color(0xFF125A3A) : (widget.selected ? const Color(0xFF4A3A12) : WfColors.panelHigh),
            border: Border.all(color: color, width: widget.selected || widget.matched || widget.hinted ? 2 : 1.3),
            boxShadow: widget.selected || widget.hinted ? [...WfFx.shadow(color.withValues(alpha: 0.45), blurRadius: 14)] : null,
          ),
          child: Text(widget.text.toUpperCase(),
              textAlign: TextAlign.center,
              style: WfText.rune(16, color: widget.matched ? Colors.white : WfColors.text)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Buffs
// -----------------------------------------------------------------------------

class BuffBar extends StatelessWidget {
  final BattleSnapshot snapshot;
  final BattleController controller;

  /// Width one buff button takes in the bar, including its padding.
  static const double slotWidth = 58;

  const BuffBar({super.key, required this.snapshot, required this.controller});

  @override
  Widget build(BuildContext context) {
    final owned = [for (final buff in BuffType.values) if ((snapshot.buffs[buff] ?? 0) > 0) buff];
    if (owned.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final buff in owned)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _BuffButton(
                buff: buff,
                count: snapshot.buffs[buff] ?? 0,
                armed: (buff == BuffType.secondChance && snapshot.secondChanceArmed) ||
                    (buff == BuffType.shield && snapshot.wardArmed),
                enabled: controller.canUseBuff(buff),
                onTap: () => controller.useBuff(buff),
              ),
            ),
        ],
      ),
    );
  }
}

class _BuffButton extends StatelessWidget {
  final BuffType buff;
  final int count;
  final bool armed;
  final bool enabled;
  final VoidCallback onTap;

  const _BuffButton({required this.buff, required this.count, required this.armed, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = buffColor(buff);
    return Tooltip(
      message: '${WfStrings.buffName(buff)} — ${WfStrings.buffDescription(buff)}',
      triggerMode: TooltipTriggerMode.longPress,
      child: WfPressable(
        onTap: enabled ? onTap : null,
        semanticsLabel: '${WfStrings.buffName(buff)} ×$count',
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled || armed ? 1 : 0.4,
          child: SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: color.withValues(alpha: armed ? 0.3 : 0.12),
                    border: Border.all(color: color.withValues(alpha: armed ? 1 : 0.55), width: armed ? 2 : 1.2),
                    boxShadow: armed ? [...WfFx.shadow(color.withValues(alpha: 0.5), blurRadius: 12)] : null,
                  ),
                  child: WfGlyph(WfGlyphType.forBuff(buff), size: 22, color: color),
                ),
                Positioned(
                  right: -2,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: WfColors.night,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.7)),
                    ),
                    child: Text('$count', style: WfText.label(10.5, color: WfColors.text, spacing: 0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
