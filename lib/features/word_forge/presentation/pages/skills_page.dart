import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/battle/combat_config.dart';
import '../../domain/content/word_forge_content.dart';
import '../../domain/progression/buffs.dart';
import '../../domain/progression/upgrades.dart';
import '../../domain/services/word_forge_audio.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/buff_chips.dart';
import '../widgets/spell_chooser.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import '../word_forge_scope.dart';

/// Three clearly separated ideas: PASSIVE SKILLS (permanent, cost a point),
/// SPECIALS (cast in battle, learned for a point once witnessed) and BUFFS
/// (consumables). One skill-point pool feeds the first two.
class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: ForgeBackdrop(
          glow: WfColors.resonance,
          animate: false,
          child: SafeArea(
            child: BlocBuilder<WordForgeCubit, WordForgeState>(
              builder: (context, state) {
                final cubit = context.read<WordForgeCubit>();
                final save = state.save!;
                final content = state.content!;
                final progression = cubit.dependencies.progression;
                final points = progression.availableSkillPoints(save);
                final witnessed = progression.witnessedSpells(content, save);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                      children: [
                        Row(
                          children: [
                            WfRoundButton(
                              glyph: WfGlyphType.back,
                              semanticsLabel: MaterialLocalizations.of(context).backButtonTooltip,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(WfStrings.skills, style: WfText.title(22))),
                          ],
                        ),
                        const SizedBox(height: 18),
                        WfPanel(
                          glow: points > 0 ? WfColors.resonance : null,
                          child: Row(
                            children: [
                              Text('$points', style: WfText.display(34, color: WfColors.resonance, spacing: 0)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(WfStrings.skillPoints, style: WfText.title(16)),
                                    const SizedBox(height: 3),
                                    Text(WfStrings.skillPointsHint, style: WfText.body(12.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionHeader(title: WfStrings.passiveSkills, hint: WfStrings.passiveSkillsHint),
                        for (final type in UpgradeType.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _UpgradeCard(
                              type: type,
                              level: save.upgrades[type],
                              canBuy: points > 0 && save.upgrades[type] < type.maxLevel,
                              onBuy: () async {
                                final bought = await cubit.purchaseUpgrade(type);
                                if (bought && context.mounted) {
                                  WordForgeScope.of(context).audio.play(WordForgeSfx.reward);
                                }
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                        _SectionHeader(title: WfStrings.spells, hint: WfStrings.specialsHint),
                        for (final id in content.combat.allSpecials)
                          if (content.combat.move(id) case final move?)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SpellRow(
                                move: move,
                                starter: id == content.combat.playerSpecial,
                                learned: save.spells.contains(id),
                                witnessed: witnessed.contains(id),
                                teacherName: _teacherName(content, progression.teacherOf(content, id)?.battleId),
                                canLearn: points > 0,
                                onLearn: () async {
                                  final learned = await cubit.learnSpell(id);
                                  if (learned && context.mounted) {
                                    WordForgeScope.of(context).audio.play(WordForgeSfx.spellLearned);
                                  }
                                },
                              ),
                            ),
                        const SizedBox(height: 8),
                        _SectionHeader(title: WfStrings.buffs, hint: WfStrings.buffsHint),
                        for (final buff in BuffType.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _BuffRow(buff: buff, count: save.buffs[buff] ?? 0),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  /// Name of the enemy that teaches a spell (the first enemy of its battle).
  static String? _teacherName(WordForgeContent content, String? battleId) {
    if (battleId == null) return null;
    final battle = content.battles[battleId];
    if (battle == null || battle.enemies.isEmpty) return null;
    return content.enemies[battle.enemies.first.enemyId]?.name;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String hint;

  const _SectionHeader({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: WfText.label(12)),
            const SizedBox(height: 4),
            Text(hint, style: WfText.body(12.5)),
          ],
        ),
      );
}

/// A Special on the Skills page: learned, learnable (witnessed) or locked
/// behind the enemy that teaches it.
class _SpellRow extends StatelessWidget {
  final MoveDefinition move;
  final bool starter;
  final bool learned;
  final bool witnessed;
  final String? teacherName;
  final bool canLearn;
  final VoidCallback onLearn;

  const _SpellRow({
    required this.move,
    required this.starter,
    required this.learned,
    required this.witnessed,
    required this.teacherName,
    required this.canLearn,
    required this.onLearn,
  });

  @override
  Widget build(BuildContext context) {
    final known = starter || learned;
    final Widget trailing;
    if (known) {
      trailing = SizedBox(
        width: 112,
        child: Center(
          child: Text((starter ? WfStrings.starterSpell : WfStrings.learned).toUpperCase(),
              textAlign: TextAlign.center, style: WfText.label(11, color: WfColors.gold)),
        ),
      );
    } else if (witnessed) {
      trailing = SizedBox(
        width: 112,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WfButton(label: WfStrings.learn, style: WfButtonStyle.secondary, onTap: canLearn ? onLearn : null),
            const SizedBox(height: 4),
            Text(WfStrings.learnCost, textAlign: TextAlign.center, style: WfText.body(10.5, color: WfColors.textMute)),
          ],
        ),
      );
    } else {
      trailing = SizedBox(
        width: 112,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WfGlyph(WfGlyphType.lock, size: 18, color: WfColors.textMute),
            const SizedBox(height: 4),
            Text(WfStrings.lockedSpell(teacherName ?? '?'),
                textAlign: TextAlign.center, style: WfText.body(10.5, color: WfColors.textMute)),
          ],
        ),
      );
    }
    return Opacity(
      opacity: known || witnessed ? 1 : 0.7,
      child: SpecialSpellCard(spell: move, compact: known, trailing: trailing),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final UpgradeType type;
  final int level;
  final bool canBuy;
  final VoidCallback onBuy;

  const _UpgradeCard({required this.type, required this.level, required this.canBuy, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final maxed = level >= type.maxLevel;
    return WfPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: WfColors.resonance.withValues(alpha: 0.14),
              border: Border.all(color: WfColors.resonance.withValues(alpha: 0.45)),
            ),
            child: WfGlyph(WfGlyphType.forUpgrade(type), size: 22, color: WfColors.resonance),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(WfStrings.upgradeName(type), style: WfText.title(15.5))),
                    const SizedBox(width: 8),
                    for (var i = 0; i < type.maxLevel; i++)
                      Container(
                        width: 14,
                        height: 5,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: i < level ? WfColors.resonance : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(WfStrings.upgradeDescription(type), style: WfText.body(12.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: maxed
                ? Center(child: Text(WfStrings.maxed.toUpperCase(), style: WfText.label(12, color: WfColors.gold)))
                : WfButton(
                    label: WfStrings.upgrade,
                    style: WfButtonStyle.secondary,
                    onTap: canBuy ? onBuy : null,
                  ),
          ),
        ],
      ),
    );
  }
}

class _BuffRow extends StatelessWidget {
  final BuffType buff;
  final int count;

  const _BuffRow({required this.buff, required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WfColors.panel.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WfColors.stroke),
        ),
        child: Row(
          children: [
            WfGlyph(WfGlyphType.forBuff(buff), size: 24, color: buffColor(buff)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(WfStrings.buffName(buff), style: WfText.title(14.5)),
                  const SizedBox(height: 2),
                  Text(WfStrings.buffDescription(buff), style: WfText.body(12.5)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('×$count', style: WfText.title(17, color: count > 0 ? WfColors.text : WfColors.textMute)),
          ],
        ),
      );
}
