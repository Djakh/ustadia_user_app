import 'package:flutter/material.dart';

import '../../domain/battle/battle_models.dart';
import '../../domain/battle/combat_config.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import 'wf_components.dart';
import 'wf_glyph.dart';

/// Picks which Special to cast. Shown as a sheet while the battle is paused,
/// so choosing never eats the attack timer. Every known spell is listed with
/// its mana cost and state (ready, resting, not enough mana), so the player
/// always sees why a spell is unavailable.
Future<String?> showSpellChooser(
  BuildContext context, {
  required List<MoveDefinition> spells,
  Map<String, SpellState> states = const {},
  required int mana,
  required int manaMax,
}) =>
    showWfSheet<String>(
      context,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(WfStrings.chooseSpell, textAlign: TextAlign.center, style: WfText.title(19)),
            const SizedBox(height: 4),
            Text(WfStrings.chooseSpellHint, textAlign: TextAlign.center, style: WfText.body(12.5)),
            const SizedBox(height: 10),
            ManaBar(mana: mana, manaMax: manaMax),
            const SizedBox(height: 14),
            for (final spell in spells)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SpecialSpellCard(
                  spell: spell,
                  state: states[spell.id],
                  onCast: states[spell.id]?.castable ?? false ? () => Navigator.of(sheetContext).pop(spell.id) : null,
                  showCastButton: true,
                  compact: true,
                ),
              ),
          ],
        ),
      ),
    );

/// Mana now / max, as a labelled bar.
class ManaBar extends StatelessWidget {
  final int mana;
  final int manaMax;

  const ManaBar({super.key, required this.mana, required this.manaMax});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const WfGlyph(WfGlyphType.sparkle, size: 15, color: WfColors.sky),
          const SizedBox(width: 6),
          Text(WfStrings.mana.toUpperCase(), style: WfText.label(11, color: WfColors.sky, spacing: 1.2)),
          const SizedBox(width: 10),
          Expanded(child: WfProgressBar(value: manaMax == 0 ? 0 : mana / manaMax, color: WfColors.sky, height: 8)),
          const SizedBox(width: 10),
          Text('$mana/$manaMax', style: WfText.title(13, color: WfColors.sky)),
        ],
      );
}

/// One spell: role, name, what it does, mana cost, cooldown and current
/// state. Used in the chooser, the Skills page and the results screen.
class SpecialSpellCard extends StatelessWidget {
  final MoveDefinition spell;
  final SpellState? state;
  final VoidCallback? onCast;
  final bool compact;
  final bool showCastButton;

  /// Replaces the cast button (Skills page: Learn / Learned / locked).
  final Widget? trailing;

  const SpecialSpellCard({
    super.key,
    required this.spell,
    this.state,
    this.onCast,
    this.compact = false,
    this.showCastButton = false,
    this.trailing,
  });

  static Color colorFor(MoveEffect effect) => switch (effect) {
        MoveEffect.ward => WfColors.sky,
        MoveEffect.bind => WfColors.resonance,
        MoveEffect.multiHit => WfColors.ember,
        MoveEffect.poison => WfColors.life,
        _ => WfColors.gold,
      };

  static WfGlyphType glyphFor(MoveEffect effect) => switch (effect) {
        MoveEffect.ward => WfGlyphType.ward,
        MoveEffect.bind => WfGlyphType.lock,
        MoveEffect.multiHit => WfGlyphType.bolt,
        MoveEffect.poison => WfGlyphType.recovery,
        _ => WfGlyphType.sparkle,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(spell.effect);
    final state = this.state;
    final castable = state?.castable ?? false;
    final dimmed = state != null && !castable;
    return Opacity(
      opacity: dimmed ? 0.62 : 1,
      child: WfPanel(
        padding: const EdgeInsets.all(12),
        glow: castable ? color : null,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color.withValues(alpha: 0.16),
                border: Border.all(color: color.withValues(alpha: 0.6)),
              ),
              child: WfGlyph(glyphFor(spell.effect), size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(WfStrings.spellName(spell.id), style: WfText.title(15))),
                      const SizedBox(width: 8),
                      for (var i = 0; i < spell.stages; i++)
                        Container(
                          width: 12,
                          height: 5,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      WfTag(WfStrings.spellRole(spell.id), color: color),
                      if (spell.manaCost > 0) WfTag(WfStrings.manaCost(spell.manaCost), color: WfColors.sky),
                      if (spell.cooldown > 0) WfTag(WfStrings.cooldownTurns(spell.cooldown), color: WfColors.textDim),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(WfStrings.spellEffect(spell.id), style: WfText.body(12.5)),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(WfStrings.spellOrigin(spell.id), style: WfText.body(11, color: WfColors.textMute)),
                  ],
                  if (state != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _stateLabel(state),
                      style: WfText.label(11, color: castable ? WfColors.gold : WfColors.textDim, spacing: 0.8),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (showCastButton && trailing == null) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 104,
                child: WfButton(label: WfStrings.cast, style: WfButtonStyle.gold, onTap: onCast),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stateLabel(SpellState state) => switch (state.block) {
        SpellBlock.none => WfStrings.ready.toUpperCase(),
        SpellBlock.cooldown => WfStrings.readyIn(state.cooldownLeft).toUpperCase(),
        SpellBlock.mana => WfStrings.needMana(state.manaMissing).toUpperCase(),
        SpellBlock.immune => WfStrings.noEffectHere.toUpperCase(),
        SpellBlock.turn => WfStrings.notNow.toUpperCase(),
      };
}
