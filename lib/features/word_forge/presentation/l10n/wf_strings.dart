import 'package:easy_localization/easy_localization.dart';

import '../../domain/battle/combat_config.dart';
import '../../domain/content/difficulty.dart';
import '../../domain/content/enemy_definition.dart';
import '../../domain/content/region_definition.dart';
import '../../domain/language/challenge_type.dart';
import '../../domain/progression/buffs.dart';
import '../../domain/progression/upgrades.dart';

/// All Word Forge interface text, resolved through the app's localization
/// (easy_localization, English phrases as keys). English learning content
/// (words, sentences, enemy names) is intentionally not translated.
abstract final class WfStrings {
  static String get title => 'Word Forge'.tr();
  static String get tagline => 'Words are spells. Understanding makes you stronger.'.tr();
  static String get practiceDescription => 'A fantasy adventure where English is your magic'.tr();
  static String get sandbox => 'Sandbox Adventure'.tr();
  static String get continueJourney => 'Continue journey'.tr();
  static String get startJourney => 'Begin journey'.tr();
  static String get spellbook => 'Spellbook'.tr();
  static String get skills => 'Skills & Buffs'.tr();
  static String get level => 'Level'.tr();
  static String get wordsDiscovered => 'Words discovered'.tr();
  static String get starsEarned => 'Stars'.tr();
  static String get mastered => 'Mastered'.tr();
  static String get loading => 'Forging your adventure...'.tr();
  static String get loadFailed => 'The forge failed to light. Please try again.'.tr();
  static String get retry => 'Try again'.tr();
  static String get sound => 'Sound'.tr();
  static String get effects => 'Reduced effects'.tr();
  static String nodesCleared(int done, int total) =>
      '{done} of {total} places cleared'.tr(namedArgs: {'done': '$done', 'total': '$total'});
  static String wordsCount(int count) => '{count} words'.tr(namedArgs: {'count': '$count'});
  static String pointsCount(int count) => '{count} points'.tr(namedArgs: {'count': '$count'});

  // Map
  static String get regionLocked => 'Defeat the previous boss to open this region'.tr();
  static String get regionCleared => 'Region cleared!'.tr();
  static String get nodeLocked => 'Clear a connected place to unlock this one'.tr();
  static String get enterBattle => 'Enter battle'.tr();
  static String get replayBattle => 'Replay'.tr();
  static String get claim => 'Claim'.tr();
  static String get claimed => 'Already claimed'.tr();
  static String get openMystery => 'Open'.tr();
  static String get optionalPath => 'Optional path'.tr();
  static String get bestResult => 'Best result'.tr();
  static String get firstClearReward => 'First clear reward'.tr();
  static String get vocabularyLevel => 'Vocabulary'.tr();
  static String get treasureFound => 'Treasure found!'.tr();
  static String get ambush => 'It was a trap!'.tr();

  static String nodeType(MapNodeType type) => switch (type) {
        MapNodeType.battle => 'Battle'.tr(),
        MapNodeType.elite => 'Elite battle'.tr(),
        MapNodeType.challenge => 'Speed challenge'.tr(),
        MapNodeType.bonus => 'Bonus'.tr(),
        MapNodeType.recovery => 'Rest'.tr(),
        MapNodeType.miniBoss => 'Mini-boss'.tr(),
        MapNodeType.boss => 'Boss'.tr(),
        MapNodeType.mystery => 'Mystery'.tr(),
      };

  static String nodeDescription(MapNodeType type) => switch (type) {
        MapNodeType.battle => 'A standard fight.'.tr(),
        MapNodeType.elite => 'A tougher enemy with better rewards.'.tr(),
        MapNodeType.challenge => 'Fast, timed spells. Being slow only lowers the reward.'.tr(),
        MapNodeType.bonus => 'Collect a helpful buff.'.tr(),
        MapNodeType.recovery => 'Rest and restore your defences.'.tr(),
        MapNodeType.miniBoss => 'A strong guardian blocks the road.'.tr(),
        MapNodeType.boss => 'The master of this region. Uses everything you have learned.'.tr(),
        MapNodeType.mystery => 'Treasure... or a trap?'.tr(),
      };

  static String enemyTrait(EnemyArchetype archetype) => switch (archetype) {
        EnemyArchetype.goblin => 'Quick attacks. Counter them with opposites.'.tr(),
        EnemyArchetype.stoneGuardian => 'Stone skin weakens normal attacks. Raises shields; slow but heavy.'.tr(),
        EnemyArchetype.rogueMage => 'Weaves incomplete spells. Find the missing rune.'.tr(),
        EnemyArchetype.wordEater => 'Eats words while you build sentences.'.tr(),
        EnemyArchetype.mimic => 'Uses look-alike words. Read carefully!'.tr(),
        EnemyArchetype.wisp => 'Fragile but very fast. Think quickly.'.tr(),
        EnemyArchetype.eliteMage => 'Mixes every kind of magic.'.tr(),
        EnemyArchetype.brute => 'Slow but hits hard. Watch for its heavy spell.'.tr(),
        EnemyArchetype.boss => 'Changes tactics in every phase.'.tr(),
      };

  /// CEFR-style label for an internal difficulty range.
  static String cefrFor(DegreeRange range) {
    const labels = {1: 'A1', 2: 'A1–A2', 3: 'A2', 4: 'A2–B1', 5: 'B1', 6: 'B1–B2'};
    final low = labels[range.min] ?? 'B2';
    final high = labels[range.max] ?? 'B2';
    if (low == high) return low;
    final start = low.split('–').first;
    final end = high.split('–').last;
    return start == end ? start : '$start–$end';
  }

  // Start / saves / characters
  static String get loadGame => 'Load game'.tr();
  static String get newGame => 'New game'.tr();
  static String get startHint => 'Begin your journey as a young apprentice'.tr();
  static String slotLabel(int index) => 'Save slot {n}'.tr(namedArgs: {'n': '$index'});
  static String get emptySlot => 'Empty slot'.tr();
  static String get corruptedSlot => 'This save could not be read'.tr();
  static String get corruptedHint => 'Your other saves are safe. You can start a new game here.'.tr();
  static String get chooseSlot => 'Choose a save slot'.tr();
  static String get overwriteTitle => 'Replace this save?'.tr();
  static String get overwriteMessage =>
      'This save slot already contains progress. Starting a new game here will replace it.'.tr();
  static String get replace => 'Replace'.tr();
  static String get cancel => 'Cancel'.tr();
  static String get load => 'Load'.tr();
  static String get chooseApprentice => 'Choose your apprentice'.tr();
  static String get chooseApprenticeHint =>
      'Both apprentices learn exactly the same magic. Choose the one you like.'.tr();
  static String get confirm => 'Confirm'.tr();
  static String get introTitle => 'Your training begins'.tr();
  static String get introBody =>
      'Every English word you understand becomes a spell. The more you learn, the stronger your magic grows.'.tr();
  static String get beginTraining => 'Begin training'.tr();
  static String percentComplete(int percent) => '{percent}% complete'.tr(namedArgs: {'percent': '$percent'});
  static String levelValue(int level) => 'Level {n}'.tr(namedArgs: {'n': '$level'});
  static String characterName(String label) => label.tr();

  // Battle
  static String get you => 'You'.tr();
  static String get yourTurn => 'Your turn'.tr();
  static String get enemyTurn => 'Enemy turn'.tr();
  static String get yourAttack => 'Your attack'.tr();
  static String get enemyAttack => 'Enemy attack'.tr();
  static String get criticalAttack => 'Critical attack!'.tr();
  static String get criticalOpportunity => 'Critical opportunity'.tr();
  static String get special => 'Special'.tr();
  static String get specialReady => 'Special ready'.tr();
  static String get useSpecial => 'Use special'.tr();
  static String get enemySpecial => 'Enemy special'.tr();
  static String get weakCast => 'Weak cast'.tr();
  static String get weakCastHint => 'Too slow or wrong: the spell still hits, but weakly.'.tr();
  static String get weakCastCounter => 'Weak cast — a wrong word leaves you open!'.tr();
  static String get criticalHit => 'Critical hit!'.tr();
  static String get bound => 'Bound! The enemy loses a turn'.tr();
  static String get wardRaised => 'Ward raised'.tr();
  static String wardCharges(int n) => 'Ward: {n} hits'.tr(namedArgs: {'n': '$n'});
  static String get stoneSkin => 'Stone skin'.tr();
  static String get chooseSpell => 'Choose a spell'.tr();
  static String get chooseSpellHint => 'Each spell costs mana and needs its own English.'.tr();
  static String stages(int n) => '{n} stages'.tr(namedArgs: {'n': '$n'});
  static String get cast => 'Cast'.tr();
  static String get spells => 'Spells'.tr();
  static String get mana => 'Mana'.tr();
  static String manaCost(int n) => '{n} mana'.tr(namedArgs: {'n': '$n'});
  static String cooldownTurns(int n) => 'Rests {n} turns'.tr(namedArgs: {'n': '$n'});
  static String get ready => 'Ready'.tr();
  static String readyIn(int n) => 'Ready in {n} turns'.tr(namedArgs: {'n': '$n'});
  static String needMana(int n) => 'Need {n} more mana'.tr(namedArgs: {'n': '$n'});
  static String get noEffectHere => 'No effect on this enemy'.tr();
  static String get notNow => 'Only on your attack turn'.tr();
  static String get fizzled => 'Fizzled! Mana spent, no cooldown'.tr();
  static String get enemyPoisoned => 'Poisoned! It will suffer before each of its turns'.tr();
  static String get youArePoisoned => 'You are poisoned!'.tr();
  static String get poisonTick => 'Poison'.tr();
  static String get reflected => 'Reflected!'.tr();
  static String get ethereal => 'Ethereal'.tr();
  static String get etherealHint => 'Cannot be poisoned.'.tr();
  static String get witnessed => 'Spell witnessed'.tr();
  static String get witnessedHint => 'You saw this magic up close. Learn it on the Skills page for one skill point.'.tr();
  static String get learn => 'Learn'.tr();
  static String get learnCost => 'Costs 1 skill point'.tr();
  static String get learned => 'Learned'.tr();
  static String get starterSpell => 'Your first spell'.tr();
  static String lockedSpell(String enemy) => 'Defeat {name} to witness this spell'.tr(namedArgs: {'name': enemy});
  static String get passiveSkills => 'Passive skills'.tr();
  static String get passiveSkillsHint => 'Permanent improvements. Each level costs one skill point.'.tr();
  static String get specialsHint => 'Spells you cast in battle. Each costs mana and rests a few turns after a successful cast.'.tr();

  /// Player Special spells, by move id.
  static String spellName(String id) => switch (id) {
        'apprentice_incantation' => 'Apprentice Incantation'.tr(),
        'guardian_ward' => 'Guardian Ward'.tr(),
        'thorn_blight' => 'Thorn Blight'.tr(),
        'rune_bind' => 'Rune Bind'.tr(),
        'word_storm_spell' => 'Word Storm'.tr(),
        _ => id.tr(),
      };

  static String spellRole(String id) => switch (id) {
        'apprentice_incantation' => 'Damage'.tr(),
        'guardian_ward' => 'Defence'.tr(),
        'thorn_blight' => 'Poison'.tr(),
        'rune_bind' => 'Control'.tr(),
        _ => 'Damage'.tr(),
      };

  static String spellEffect(String id) => switch (id) {
        'apprentice_incantation' => 'Big damage that also splashes a second enemy. Three stages: opposite, similar, then a sentence.'.tr(),
        'guardian_ward' => 'Absorbs the next 2 enemy hits and throws damage back each time. Opposite, then a sentence.'.tr(),
        'thorn_blight' => 'Poisons the enemy: damage before each of its turns for 3 turns, through stone skin and shields. Similar word, then a sentence.'.tr(),
        'rune_bind' => 'The enemy loses its next turn, plus damage. A sentence, then a similar word.'.tr(),
        'word_storm_spell' => 'Three quick words. Every correct word is a hit.'.tr(),
        _ => '',
      };

  static String spellOrigin(String id) => switch (id) {
        'guardian_ward' => 'Witnessed at the Keeper of the Gate'.tr(),
        'thorn_blight' => 'Witnessed at the Thornmother'.tr(),
        'rune_bind' => 'Witnessed at the Ruin Scribes'.tr(),
        'word_storm_spell' => 'Witnessed at the Thornmother'.tr(),
        _ => 'Your first spell'.tr(),
      };
  static String get newSpell => 'New spell learned'.tr();
  static String get spellsKnown => 'Spells'.tr();
  static String get shield => 'Shield'.tr();
  static String get staggered => 'Staggered!'.tr();
  static String get lockedTurn => 'Your attack is locked!'.tr();
  static String get parried => 'Parried!'.tr();
  static String get target => 'Target'.tr();
  static String get preparing => 'Preparing'.tr();
  static String stageProgress(int index, int total) =>
      '{n} of {total}'.tr(namedArgs: {'n': '$index', 'total': '$total'});
  static String moveLabel(String label) => label.tr();

  /// What the player must do right now, in plain words.
  static String instruction({
    required BattleTurn turn,
    required MoveKind kind,
    required ChallengeType type,
    required bool shield,
  }) {
    switch (type) {
      case ChallengeType.wordMatch:
        return 'Match the opposites'.tr();
      case ChallengeType.incantation:
        return 'Tap the words in the right order'.tr();
      case ChallengeType.missingRune:
        return 'Complete the sentence'.tr();
      case ChallengeType.synonym:
        if (turn == BattleTurn.player && kind == MoveKind.normal) {
          return shield ? 'Break the shield with a SIMILAR word'.tr() : 'Attack with a SIMILAR word'.tr();
        }
        return 'Find a word with a SIMILAR meaning'.tr();
      case ChallengeType.antonym:
        if (turn == BattleTurn.enemy) {
          return kind == MoveKind.critical ? 'Quick! Defend with the OPPOSITE'.tr() : 'Defend with the OPPOSITE'.tr();
        }
        return 'Find the OPPOSITE word'.tr();
    }
  }

  /// One-time coaching lines, keyed by the engine's tutorial keys.
  static String? coach(String? key) => switch (key) {
        'attack' => 'Your attack: find a similar word before the ring runs out. Slow or wrong still casts, but weakly — and a wrong word leaves you open.'.tr(),
        'defence' => 'The enemy attacks: defend with the opposite word.'.tr(),
        'criticalDefence' => 'Critical attack! Same rule — answer quickly.'.tr(),
        'criticalAttack' => 'Bonus challenge! Win it for extra damage. Your attack already hit.'.tr(),
        'special' => 'Complete the incantation. Every correct stage adds power. No stage solved: the mana is gone, nothing else.'.tr(),
        'guardianWard' => 'Guardian Ward: solve both stages and the next two enemy hits are absorbed.'.tr(),
        'wordStorm' => 'Word Storm: quick words, one hit each. Speed matters!'.tr(),
        'thornBlight' => 'Thorn Blight: solve both stages and the enemy is poisoned for three turns.'.tr(),
        'thornCurse' => 'Thorn Curse! Defend, or the poison will bite before each of your turns.'.tr(),
        'runeBind' => 'Rune Bind: solve both stages and the enemy loses its next turn.'.tr(),
        'shield' => 'Similar words crack the shield. Break it to stun the enemy.'.tr(),
        'runeLock' => 'Rune Lock: complete the sentence or lose your next attack.'.tr(),
        'enemySpecial' => 'Enemy special: solve every part to block it.'.tr(),
        'twoEnemies' => 'Two enemies! Tap an enemy to choose your target.'.tr(),
        _ => null,
      };
  static String get combo => 'Combo'.tr();
  static String get wordFlow => 'Word Flow'.tr();
  static String get newWord => 'New word'.tr();
  static String get paused => 'Paused'.tr();
  static String get resume => 'Continue'.tr();
  static String get retreat => 'Retreat'.tr();
  static String get retreatQuestion => 'Leave the battle? Words you practised are still saved.'.tr();
  static String get stay => 'Stay'.tr();
  static String get undo => 'Undo'.tr();
  static String get clear => 'Clear'.tr();
  static String get phase => 'Phase'.tr();
  static String get timeUp => 'Time is up!'.tr();
  static String get secondChanceSaved => 'Second Chance!'.tr();
  static String get wardBlocked => 'Blocked!'.tr();
  static String get enraged => 'Enraged'.tr();
  static String get unstable => 'Unstable! Fix the order'.tr();
  static String get wordEaten => 'A word was eaten!'.tr();

  // Results
  static String get victory => 'Victory'.tr();
  static String get defeat => 'The spell faded'.tr();
  static String get defeatEncouragement =>
      'Every battle teaches you new words. Try again — you are getting closer.'.tr();
  static String get accuracy => 'Accuracy'.tr();
  static String get bestCombo => 'Best combo'.tr();
  static String get time => 'Time'.tr();
  static String get xp => 'XP'.tr();
  static String get levelUp => 'Level up!'.tr();
  static String get rewards => 'Rewards'.tr();
  static String get newWords => 'New words'.tr();
  static String get toReview => 'Words to review'.tr();
  static String get masteryUp => 'Mastery improved'.tr();
  static String get objectiveVictory => 'Victory'.tr();
  static String objectiveAccuracy(int percent, int needed) =>
      'Accuracy {percent}% (need {needed}%)'.tr(namedArgs: {'percent': '$percent', 'needed': '$needed'});
  static String objectiveTurns(int used, int budget) =>
      'Attack turns {used} of {budget}'.tr(namedArgs: {'used': '$used', 'budget': '$budget'});
  static String get continueLabel => 'Continue'.tr();
  static String get backToMap => 'Back to map'.tr();
  static String get newRegion => 'New region unlocked'.tr();

  // Spellbook
  static String get search => 'Search words'.tr();
  static String get all => 'All'.tr();
  static String get discovered => 'Discovered'.tr();
  static String get needsPractice => 'Needs practice'.tr();
  static String get meaning => 'Meaning'.tr();
  static String get opposite => 'Opposite'.tr();
  static String get similar => 'Similar'.tr();
  static String get example => 'Example'.tr();
  static String get mastery => 'Mastery'.tr();
  static String get sentenceSkill => 'Sentences'.tr();
  static String get seen => 'Seen'.tr();
  static String get correct => 'Correct'.tr();
  static String get undiscoveredHint => 'Find this word on your journey to unlock it.'.tr();
  static String get noWordsFound => 'No words found'.tr();
  static String discoveredOf(int done, int total) =>
      '{done} / {total} discovered'.tr(namedArgs: {'done': '$done', 'total': '$total'});
  static String masteryLabel(int level) => switch (level) {
        0 => 'Undiscovered'.tr(),
        1 => 'Discovered'.tr(),
        2 => 'Recognised'.tr(),
        3 => 'Reliable understanding'.tr(),
        4 => 'Strong understanding'.tr(),
        _ => 'Mastered'.tr(),
      };

  // Skills & buffs
  static String get skillPoints => 'Skill points'.tr();
  static String get skillPointsHint => 'Earn a skill point every time you level up. Spend it on a passive skill or a new spell.'.tr();
  static String get upgrade => 'Upgrade'.tr();
  static String get maxed => 'Max'.tr();
  static String get buffs => 'Buffs'.tr();
  static String get buffsHint => 'Tap a buff during battle to use it. Hold it to read what it does.'.tr();

  static String buffName(BuffType buff) => switch (buff) {
        BuffType.hint => 'Hint'.tr(),
        BuffType.reveal => 'Reveal'.tr(),
        BuffType.timeFreeze => 'Time Freeze'.tr(),
        BuffType.extraTime => 'Extra Time'.tr(),
        BuffType.secondChance => 'Second Chance'.tr(),
        BuffType.runeSense => 'Rune Sense'.tr(),
        BuffType.shield => 'Ward'.tr(),
      };

  static String buffDescription(BuffType buff) => switch (buff) {
        BuffType.hint => 'Dims one wrong answer. In sentences, it glows on the next word.'.tr(),
        BuffType.reveal => 'Shows the first letter. In sentences, it places the next word.'.tr(),
        BuffType.timeFreeze => 'Stops the timer for 6 seconds.'.tr(),
        BuffType.extraTime => 'Adds 5 seconds to the timer.'.tr(),
        BuffType.secondChance => 'Your next wrong answer is forgiven.'.tr(),
        BuffType.runeSense => 'Removes a wrong answer now and in the next 2 challenges.'.tr(),
        BuffType.shield => 'Blocks the damage of your next mistake.'.tr(),
      };

  static String upgradeName(UpgradeType type) => switch (type) {
        UpgradeType.focus => 'Focus'.tr(),
        UpgradeType.insight => 'Insight'.tr(),
        UpgradeType.protection => 'Protection'.tr(),
        UpgradeType.momentum => 'Momentum'.tr(),
      };

  static String upgradeDescription(UpgradeType type) => switch (type) {
        UpgradeType.focus => '+1 second on timed spells per level.'.tr(),
        UpgradeType.insight => 'Level 1: hints also show the first letter. Level 2: hints dim two answers.'.tr(),
        UpgradeType.protection => 'A free Ward at the start of every few battles.'.tr(),
        UpgradeType.momentum => 'Combos of 4 or more make your attacks 5% stronger per level.'.tr(),
      };
}
