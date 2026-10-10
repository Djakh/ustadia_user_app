import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/battle/battle_models.dart';
import '../../domain/battle/combat_config.dart';
import '../../domain/language/challenge_type.dart';
import '../cubit/battle_controller.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import 'wf_components.dart';
import 'wf_glyph.dart';

/// HP bar with a trailing "ghost" that drains after the hit lands.
class HpBar extends StatelessWidget {
  final String name;
  final int hp;
  final int maxHp;
  final Color color;
  final bool alignEnd;
  final bool compact;
  final Widget? badge;

  const HpBar({
    super.key,
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.color,
    this.alignEnd = false,
    this.compact = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return Semantics(
      label: '$name $hp / $maxHp',
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alignEnd && badge != null) ...[badge!, const SizedBox(width: 6)],
              Flexible(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WfText.title(13.5, color: WfColors.text)
                        .copyWith(shadows: WfFx.textOutline())),
              ),
              if (!alignEnd && badge != null) ...[const SizedBox(width: 6), badge!],
            ],
          ),
          SizedBox(height: compact ? 3 : 5),
          SizedBox(
            height: compact ? 8 : 12,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, ghost, _) => TweenAnimationBuilder<double>(
                tween: Tween(end: fraction),
                duration: const Duration(milliseconds: 260),
                builder: (context, live, _) => CustomPaint(
                  painter: _HpPainter(live: live, ghost: ghost, color: color, reverse: alignEnd),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          if (!compact) const SizedBox(height: 3),
          if (!compact)
            Text('$hp / $maxHp',
              style: WfText.label(10.5, color: WfColors.textDim, spacing: 0.5)
                  .copyWith(shadows: WfFx.textOutline())),
        ],
      ),
    );
  }
}

class _HpPainter extends CustomPainter {
  final double live;
  final double ghost;
  final Color color;
  final bool reverse;

  _HpPainter({required this.live, required this.ghost, required this.color, required this.reverse});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(track, Paint()..color = Colors.black.withValues(alpha: 0.55));
    Rect part(double fraction) => reverse
        ? Rect.fromLTRB(size.width * (1 - fraction), 0, size.width, size.height)
        : Rect.fromLTRB(0, 0, size.width * fraction, size.height);
    canvas.save();
    canvas.clipRRect(track);
    if (ghost > live) canvas.drawRect(part(ghost), Paint()..color = Colors.white.withValues(alpha: 0.55));
    canvas.drawRect(
      part(live),
      Paint()
        ..shader = LinearGradient(colors: [Color.lerp(color, Colors.white, 0.3)!, color])
            .createShader(Offset.zero & size),
    );
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height * 0.35), Paint()..color = Colors.white.withValues(alpha: 0.12));
    canvas.restore();
    canvas.drawRRect(track,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(_HpPainter oldDelegate) =>
      oldDelegate.live != live || oldDelegate.ghost != ghost || oldDelegate.color != color;
}

/// Boss phase markers.
class StagePips extends StatelessWidget {
  final int index;
  final int count;
  final bool enraged;

  /// Optional per-stage results (multi-task moves): true = success.
  final List<bool> results;

  const StagePips({super.key, required this.index, required this.count, required this.enraged, this.results = const []});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: i == index ? 22 : 10,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i < results.length
                    ? (results[i] ? WfColors.brand : WfColors.danger)
                    : i < index
                        ? WfColors.textMute
                        : (i == index ? (enraged ? WfColors.danger : WfColors.gold) : Colors.white.withValues(alpha: 0.2)),
              ),
            ),
        ],
      );
}

class ComboBadge extends StatelessWidget {
  final int combo;
  final bool flow;

  const ComboBadge({super.key, required this.combo, required this.flow});

  @override
  Widget build(BuildContext context) {
    if (combo < 2) return const SizedBox.shrink();
    final color = flow ? WfColors.gold : WfColors.arcane;
    return TweenAnimationBuilder<double>(
      key: ValueKey(combo),
      tween: Tween(begin: 1.35, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.8)),
          boxShadow: [...WfFx.shadow(color.withValues(alpha: 0.4), blurRadius: 14)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WfGlyph(WfGlyphType.flame, size: 15, color: color),
            const SizedBox(width: 5),
            Text('${WfStrings.combo.toUpperCase()} ×$combo', style: WfText.label(13, color: WfColors.text, spacing: 1)),
          ],
        ),
      ),
    );
  }
}

/// Circular countdown. Reads the engine through a notifier so only this
/// widget repaints each frame.
class TimerRing extends StatelessWidget {
  final ValueNotifier<double> fraction;
  final bool frozen;

  const TimerRing({super.key, required this.fraction, required this.frozen});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 52,
        child: ValueListenableBuilder<double>(
          valueListenable: fraction,
          builder: (context, value, _) => CustomPaint(
            painter: _TimerPainter(value, frozen),
            child: Center(
              child: frozen
                  ? const WfGlyph(WfGlyphType.timeFreeze, size: 20, color: Color(0xFF9FE8FF))
                  : const WfGlyph(WfGlyphType.challenge, size: 18, color: WfColors.text),
            ),
          ),
        ),
      );
}

class _TimerPainter extends CustomPainter {
  final double value;
  final bool frozen;

  _TimerPainter(this.value, this.frozen);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    canvas.drawCircle(center, radius + 2, Paint()..color = Colors.black.withValues(alpha: 0.55));
    final color = frozen
        ? const Color(0xFF9FE8FF)
        : (value < 0.3 ? WfColors.danger : (value < 0.6 ? WfColors.gold : WfColors.life));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) => oldDelegate.value != value || oldDelegate.frozen != frozen;
}

/// Readable plate over the scene: what is happening and the key word.
class PromptPlate extends StatelessWidget {
  final BattleSnapshot snapshot;

  const PromptPlate({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final challenge = snapshot.challenge;
    final kind = snapshot.moveKind;
    if (challenge == null || kind == null) return const SizedBox.shrink();
    final turn = snapshot.turn;
    final color = snapshot.targetShielded && turn == BattleTurn.player && kind == MoveKind.normal
        ? WfColors.resonance
        : WfColors.forMove(turn, kind);
    final outcome = snapshot.phase == BattlePhase.resolving ? snapshot.lastOutcome : null;
    final weak = outcome?.weakCast ?? false;
    final label = switch ((turn, kind)) {
      (BattleTurn.player, MoveKind.normal) =>
        weak ? WfStrings.weakCast : (snapshot.targetShielded ? WfStrings.shield : WfStrings.yourAttack),
      (BattleTurn.player, MoveKind.critical) =>
        outcome != null && outcome.success ? WfStrings.criticalHit : WfStrings.moveLabel(snapshot.moveLabel ?? WfStrings.special),
      (BattleTurn.player, MoveKind.special) => outcome != null && outcome.spellFizzled
          ? WfStrings.fizzled
          : WfStrings.moveLabel(snapshot.moveLabel ?? WfStrings.special),
      (BattleTurn.enemy, MoveKind.normal) => WfStrings.enemyAttack,
      (BattleTurn.enemy, MoveKind.critical) => WfStrings.criticalAttack,
      _ => WfStrings.moveLabel(snapshot.moveLabel ?? WfStrings.special),
    };
    final relation = challenge.type == ChallengeType.antonym || challenge.type == ChallengeType.synonym;
    final word = relation ? challenge.prompt : null;
    final resolving = snapshot.phase == BattlePhase.resolving && relation;
    final answerColor = (snapshot.lastTaskSuccess ?? snapshot.lastOutcome?.success ?? false) ? WfColors.brand : WfColors.gold;
    final fizzled = outcome?.spellFizzled ?? false;
    final plateColor = weak || fizzled ? WfColors.textMute : color;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(animation), child: child),
      ),
      child: Container(
        key: ValueKey('${challenge.id}-$resolving-$weak'),
        padding: EdgeInsets.symmetric(horizontal: word == null ? 14 : 20, vertical: word == null ? 7 : 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xE60A0D1E),
          border: Border.all(color: plateColor.withValues(alpha: 0.85), width: kind == MoveKind.normal ? 1.5 : 2.2),
          boxShadow: [...WfFx.shadow(plateColor.withValues(alpha: weak ? 0.15 : 0.35), blurRadius: 22)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label.toUpperCase(), style: WfText.label(10.5, color: plateColor, spacing: 2)),
                if (snapshot.taskCount > 1) ...[
                  const SizedBox(width: 8),
                  StagePips(
                    index: snapshot.taskIndex,
                    count: snapshot.taskCount,
                    enraged: false,
                    results: snapshot.taskResults,
                  ),
                ],
              ],
            ),
            if (word != null) ...[
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(word.toUpperCase(), style: WfText.rune(30)),
                    if (resolving) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(challenge.type == ChallengeType.antonym ? '⟷' : '≈',
                            style: WfText.title(22, color: color)),
                      ),
                      Text(challenge.correctAnswer.toUpperCase(), style: WfText.rune(30, color: answerColor)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "YOUR TURN" / "ENEMY TURN" pill under the HP bars.
class TurnIndicator extends StatelessWidget {
  final BattleSnapshot snapshot;

  const TurnIndicator({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (snapshot.phase == BattlePhase.intro || snapshot.phase.isOver) return const SizedBox.shrink();
    final player = snapshot.isPlayerTurn;
    final color = player ? WfColors.brand : WfColors.ember;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Container(
        key: ValueKey(player),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WfGlyph(player ? WfGlyphType.sparkle : WfGlyphType.battle, size: 12, color: color),
            const SizedBox(width: 6),
            Text((player ? WfStrings.yourTurn : WfStrings.enemyTurn).toUpperCase(),
                style: WfText.label(10.5, color: color, spacing: 1.6)),
          ],
        ),
      ),
    );
  }
}

/// Enemy HP rows (one or two), with shield pips, intent icon and tap-to-target.
class EnemyBars extends StatelessWidget {
  final BattleSnapshot snapshot;
  final ValueChanged<int> onTarget;

  const EnemyBars({super.key, required this.snapshot, required this.onTarget});

  @override
  Widget build(BuildContext context) {
    final multi = snapshot.enemies.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final enemy in snapshot.enemies)
          Padding(
            padding: EdgeInsets.only(bottom: multi ? 6 : 0),
            child: Opacity(
              opacity: enemy.alive ? 1 : 0.35,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: multi && enemy.alive ? () => onTarget(enemy.index) : null,
                child: Container(
                  padding: multi ? const EdgeInsets.fromLTRB(6, 3, 6, 3) : EdgeInsets.zero,
                  decoration: multi && snapshot.targetIndex == enemy.index && enemy.alive
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: WfColors.brand.withValues(alpha: 0.7)),
                          color: WfColors.brand.withValues(alpha: 0.08),
                        )
                      : null,
                  child: HpBar(
                    name: enemy.name,
                    hp: enemy.hp,
                    maxHp: enemy.maxHp,
                    color: snapshot.enraged ? WfColors.danger : WfColors.ember,
                    alignEnd: true,
                    compact: multi,
                    badge: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (enemy.intent != null && enemy.intent != MoveKind.normal) IntentIcon(kind: enemy.intent!),
                        if (enemy.shield != null) ...[
                          const SizedBox(width: 4),
                          ShieldPips(shield: enemy.shield!),
                        ],
                        if (enemy.staggered) ...[
                          const SizedBox(width: 4),
                          const WfGlyph(WfGlyphType.sparkle, size: 13, color: WfColors.gold),
                        ],
                        if (enemy.poisoned) ...[
                          const SizedBox(width: 4),
                          PoisonPips(ticks: enemy.poisonTicks),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small telegraph icon: what an enemy is preparing.
class IntentIcon extends StatefulWidget {
  final MoveKind kind;

  const IntentIcon({super.key, required this.kind});

  @override
  State<IntentIcon> createState() => _IntentIconState();
}

class _IntentIconState extends State<IntentIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final critical = widget.kind == MoveKind.critical;
    final color = critical ? WfColors.danger : WfColors.resonance;
    return Tooltip(
      message: '${WfStrings.preparing}: ${critical ? WfStrings.criticalAttack : WfStrings.enemySpecial}',
      child: FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(_pulse),
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.25), border: Border.all(color: color)),
          child: WfGlyph(critical ? WfGlyphType.bolt : WfGlyphType.sparkle, size: 12, color: color),
        ),
      ),
    );
  }
}

class ShieldPips extends StatelessWidget {
  final ShieldSnapshot shield;

  const ShieldPips({super.key, required this.shield});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WfGlyph(WfGlyphType.ward, size: 14, color: WfColors.resonance),
          const SizedBox(width: 2),
          for (var i = 0; i < shield.strength; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < shield.remaining ? WfColors.resonance : Colors.white.withValues(alpha: 0.15),
              ),
            ),
        ],
      );
}

/// Spells button with the mana pool. Glows gold when at least one spell can
/// be cast right now; on the player's attack turn it always opens the spell
/// panel, so the reason a spell is unavailable is one tap away.
class SpecialMeter extends StatelessWidget {
  final BattleSnapshot snapshot;
  final VoidCallback onActivate;

  const SpecialMeter({super.key, required this.snapshot, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    if (!snapshot.specialUnlocked) return const SizedBox.shrink();
    final usable = snapshot.specialReady;
    final canOpen = snapshot.acceptsInput && snapshot.isPlayerTurn && snapshot.moveKind == MoveKind.normal;
    final fraction = snapshot.manaMax == 0 ? 0.0 : snapshot.mana / snapshot.manaMax;
    return WfPressable(
      onTap: canOpen ? onActivate : null,
      semanticsLabel: '${WfStrings.spells}: ${WfStrings.mana} ${snapshot.mana}/${snapshot.manaMax}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WfShape.pill),
          color: usable ? WfColors.gold.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.4),
          border: Border.all(color: usable ? WfColors.gold : WfColors.stroke, width: usable ? 1.8 : 1),
          boxShadow: usable ? [...WfFx.shadow(WfColors.gold.withValues(alpha: 0.55), blurRadius: 18)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WfGlyph(WfGlyphType.sparkle, size: 16, color: usable ? WfColors.gold : WfColors.sky),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(WfStrings.spells.toUpperCase(),
                    style: WfText.label(11, color: usable ? WfColors.gold : WfColors.textDim, spacing: 1.2)),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 56,
                      child: WfProgressBar(value: fraction, color: usable ? WfColors.gold : WfColors.sky, height: 5),
                    ),
                    const SizedBox(width: 6),
                    Text('${snapshot.mana}/${snapshot.manaMax}',
                        style: WfText.label(10, color: usable ? WfColors.gold : WfColors.sky, spacing: 0.4)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Status pips: poison drops with the ticks left.
class PoisonPips extends StatelessWidget {
  final int ticks;

  const PoisonPips({super.key, required this.ticks});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WfGlyph(WfGlyphType.recovery, size: 13, color: WfColors.life),
          for (var i = 0; i < ticks.clamp(0, 5); i++)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(left: 2),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: WfColors.life),
            ),
        ],
      );
}

/// Transient notices (new word, Word Flow, Second Chance...).
class NoticeBanner extends StatelessWidget {
  final ValueNotifier<BattleNotice?> notice;

  const NoticeBanner({super.key, required this.notice});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<BattleNotice?>(
        valueListenable: notice,
        builder: (context, value, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: value == null ? const SizedBox.shrink() : _NoticeCard(key: ValueKey(value.id), notice: value, onDone: () {
            if (this.notice.value?.id == value.id) this.notice.value = null;
          }),
        ),
      );
}

class _NoticeCard extends StatefulWidget {
  final BattleNotice notice;
  final VoidCallback onDone;

  const _NoticeCard({super.key, required this.notice, required this.onDone});

  @override
  State<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<_NoticeCard> {
  @override
  void initState() {
    super.initState();
    final duration = widget.notice.kind == BattleNoticeKind.discovery ? 2600 : 1500;
    Future.delayed(Duration(milliseconds: duration), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;
    final color = switch (notice.kind) {
      BattleNoticeKind.discovery => WfColors.gold,
      BattleNoticeKind.success => WfColors.life,
      BattleNoticeKind.warning => WfColors.ember,
      BattleNoticeKind.info => WfColors.arcane,
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xEE0A0D1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.8)),
        boxShadow: [...WfFx.shadow(color.withValues(alpha: 0.3), blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(notice.title.toUpperCase(), style: WfText.label(10.5, color: color, spacing: 1.8)),
          if (notice.word != null) ...[
            const SizedBox(height: 2),
            Text(notice.word!.toUpperCase(), style: WfText.rune(17)),
          ],
          if (notice.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(notice.subtitle!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WfText.body(12, color: WfColors.textDim)),
          ],
        ],
      ),
    );
  }
}
