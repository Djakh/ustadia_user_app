import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/battle/battle_models.dart';
import '../../domain/battle/combat_config.dart';
import '../../domain/content/battle_definition.dart';
import '../../domain/content/enemy_definition.dart';
import '../../domain/content/region_definition.dart';
import '../../domain/progression/buffs.dart';
import '../../domain/progression/player_level.dart';
import '../../domain/progression/upgrades.dart';
import '../cubit/word_forge_cubit.dart';
import '../theme/wf_theme.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import '../word_forge_scope.dart';
import 'battle_page.dart';

/// Debug-only practice arena: pick any enemy, start with any spells and mana,
/// force enemy Specials, and fight without touching the save. Reachable from
/// the hub in debug builds only. English strings are deliberately not
/// localised (never shipped).
class QaArenaPage extends StatefulWidget {
  const QaArenaPage({super.key});

  @override
  State<QaArenaPage> createState() => _QaArenaPageState();
}

class _QaArenaPageState extends State<QaArenaPage> {
  String? _enemyId;
  bool _allSpells = true;
  bool _fullMana = true;
  bool _forceEnemySpecials = false;
  bool _startWithWard = false;
  bool _enemyHalfHp = false;
  bool _maxUpgrades = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WordForgeCubit>();
    final content = cubit.state.content!;
    final enemies = content.enemies.values.toList()..sort((a, b) => a.maxHp.compareTo(b.maxHp));
    _enemyId ??= enemies.first.id;
    final enemy = content.enemies[_enemyId]!;
    final behaviour = content.combat.behaviourFor(enemy.archetype.name).merge(enemy.behaviour);
    return Scaffold(
      backgroundColor: WfColors.night,
      body: ForgeBackdrop(
        glow: WfColors.ember,
        animate: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                children: [
                  Row(
                    children: [
                      WfRoundButton(
                        glyph: WfGlyphType.back,
                        semanticsLabel: 'Back',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text('QA Arena (debug)', style: WfText.title(22))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Practice fights never change the save. Results are shown but not kept.', style: WfText.body(12.5)),
                  const SizedBox(height: 16),
                  WfPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ENEMY', style: WfText.label(12)),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: _enemyId,
                          isExpanded: true,
                          dropdownColor: WfColors.panelHigh,
                          style: WfText.body(14, color: WfColors.text),
                          items: [
                            for (final item in enemies)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text('${item.name}  ·  ${item.archetype.name}  ·  ${item.maxHp} HP'
                                    '${item.title == null ? '' : '  ·  ${item.title}'}'),
                              ),
                          ],
                          onChanged: (value) => setState(() => _enemyId = value),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'element ${behaviour.element} · specials ${behaviour.specials.join(', ')}'
                          '${behaviour.armor > 0 ? ' · stone skin' : ''}${behaviour.poisonImmune ? ' · ethereal' : ''}',
                          style: WfText.body(12, color: WfColors.textDim),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _toggle('All four spells known', _allSpells, (v) => setState(() => _allSpells = v)),
                  _toggle('Start with full mana', _fullMana, (v) => setState(() => _fullMana = v)),
                  _toggle('Enemy always uses Specials (telegraphs)', _forceEnemySpecials, (v) => setState(() => _forceEnemySpecials = v)),
                  _toggle('Start with a Ward (buff)', _startWithWard, (v) => setState(() => _startWithWard = v)),
                  _toggle('Enemy starts at half HP (quick 3★ / 1★ checks)', _enemyHalfHp, (v) => setState(() => _enemyHalfHp = v)),
                  _toggle('All passive skills maxed', _maxUpgrades, (v) => setState(() => _maxUpgrades = v)),
                  const SizedBox(height: 16),
                  WfButton(label: 'Fight', style: WfButtonStyle.gold, onTap: () => _fight(context, content, enemy)),
                  const SizedBox(height: 18),
                  Text('CHECKLIST HINTS', style: WfText.label(12)),
                  const SizedBox(height: 6),
                  Text(
                    '• Timer timeout: just wait on your attack.\n'
                    '• Wrong answer: tap a wrong word (weak cast + counter).\n'
                    '• Two Specials in one battle: full mana + any enemy with 100+ HP.\n'
                    '• Poison: Thorn Blight on a golem (ticks through stone skin); a wisp is immune.\n'
                    '• Enemy poison: Thornmother with "always uses Specials".\n'
                    '• Reflect: Guardian Ward, then fail a defence.\n'
                    '• Boss Special: Keeper of the Gate / Thornmother / Lexicon Lich.\n'
                    '• Stars: half HP enemy + all correct = 3★; many wrong = 1★.\n'
                    '• Skill-point unlocks and male/female: use the normal Skills and Character pages.',
                    style: WfText.body(12.5, color: WfColors.textDim),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: WfText.body(13.5, color: WfColors.text))),
            Switch(value: value, activeTrackColor: WfColors.gold, onChanged: onChanged),
          ],
        ),
      );

  void _fight(BuildContext context, dynamic content, EnemyDefinition enemy) {
    final cubit = context.read<WordForgeCubit>();
    final save = cubit.state.save!;
    final combat = content.combat as CombatConfig;
    // The node whose battle stars this enemy, so the results screen names it;
    // otherwise the first battle of the first region.
    MapNodeDefinition? node;
    RegionDefinition? region;
    for (final r in content.regions) {
      for (final n in r.nodes) {
        final battle = n.battleId == null ? null : content.battles[n.battleId];
        if (battle != null && battle.enemies.first.enemyId == enemy.id) {
          node = n;
          region = r;
          break;
        }
      }
      if (node != null) break;
    }
    region ??= content.regions.first as RegionDefinition;
    node ??= region.nodes.firstWhere((n) => n.battleId != null);
    final battle = content.battles[node.battleId] as BattleDefinition;
    final sameEnemy = battle.enemies.first.enemyId == enemy.id;
    final definition = sameEnemy
        ? battle
        : BattleDefinition(
            id: 'qa_${enemy.id}',
            enemies: [BattleEnemy(enemy.id)],
            degrees: region.degrees,
            rewards: const BattleRewards(xp: 0),
          );
    final config = CombatConfig(
      balance: combat.balance,
      meter: SpecialMeterConfig(
        max: combat.meter.max,
        start: _fullMana ? combat.meter.max : combat.meter.start,
        normalHit: combat.meter.normalHit,
        weakCast: combat.meter.weakCast,
        defence: combat.meter.defence,
        criticalDefence: combat.meter.criticalDefence,
        criticalAttack: combat.meter.criticalAttack,
        shieldBreak: combat.meter.shieldBreak,
        comboMilestone: combat.meter.comboMilestone,
        comboMilestoneEvery: combat.meter.comboMilestoneEvery,
        flowBonus: combat.meter.flowBonus,
      ),
      pacing: _forceEnemySpecials
          ? PacingConfig(
              playerCriticalChance: combat.pacing.playerCriticalChance,
              playerCriticalCap: combat.pacing.playerCriticalCap,
              comboCriticalBonus: combat.pacing.comboCriticalBonus,
              criticalCooldownTurns: combat.pacing.criticalCooldownTurns,
              enemySpecialCooldown: 0,
              minNormalEnemyTurns: 0,
            )
          : combat.pacing,
      timers: combat.timers,
      gates: combat.gates,
      holds: combat.holds,
      archetypes: {
        ...combat.archetypes,
        if (_forceEnemySpecials)
          enemy.archetype.name: combat.behaviourFor(enemy.archetype.name).merge(const {'specialChance': 1.0}),
      },
      moves: combat.moves,
      playerCriticals: combat.playerCriticals,
      playerSpecial: combat.playerSpecial,
      learnableSpecials: combat.learnableSpecials,
    );
    final definitions = [for (final slot in definition.enemies) content.enemies[slot.enemyId] as EnemyDefinition];
    final setup = BattleSetup(
      battle: definition,
      enemies: definitions,
      enemyHp: [
        for (var i = 0; i < definitions.length; i++)
          (((i < definition.enemies.length ? definition.enemies[i].hp : null) ?? definitions[i].maxHp) * (_enemyHalfHp ? 0.5 : 1)).round(),
      ],
      degrees: definition.degrees,
      config: config,
      access: MechanicAccess.all,
      upgrades: _maxUpgrades
          ? const UpgradeLevels({UpgradeType.focus: 3, UpgradeType.insight: 2, UpgradeType.protection: 3, UpgradeType.momentum: 3})
          : save.upgrades,
      inventory: {for (final buff in BuffType.values) buff: 3},
      startWithWard: _startWithWard,
      playerLevel: PlayerLevel.fromXp(save.xp).level,
      knownTutorials: save.tutorialFlags,
      spells: _allSpells ? combat.allSpecials : [combat.playerSpecial, ...save.spells],
    );
    WordForgeScope.of(context);
    WordForgeNavigator.push(context, BattlePage(node: node, region: region, practiceSetup: setup));
  }
}
