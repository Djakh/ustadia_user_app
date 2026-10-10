import 'package:equatable/equatable.dart';

import '../content/battle_definition.dart';
import '../content/difficulty.dart';
import '../content/enemy_definition.dart';
import '../language/challenge_type.dart';
import '../language/language_challenge.dart';
import '../progression/buffs.dart';
import '../progression/upgrades.dart';
import 'battle_assist.dart';
import 'combat_config.dart';

/// Everything needed to start a battle. Built by the mode (Sandbox today,
/// Story later); the engine itself has no idea which mode it runs in.
class BattleSetup {
  final BattleDefinition battle;
  final List<EnemyDefinition> enemies;
  final List<int> enemyHp;
  final DegreeRange degrees;
  final CombatConfig config;
  final MechanicAccess access;
  final BattleAssist assist;
  final UpgradeLevels upgrades;
  final Map<BuffType, int> inventory;
  final bool startWithWard;
  final int playerLevel;

  /// Tutorial keys the player has already seen (coach lines show once).
  final Set<String> knownTutorials;

  /// Player Specials available in this battle (starter first). Null means
  /// only the starter spell from [config].
  final List<String> spells;

  BattleSetup({
    required this.battle,
    required this.enemies,
    List<int>? enemyHp,
    required this.degrees,
    this.config = const CombatConfig(),
    this.access = MechanicAccess.all,
    this.assist = BattleAssist.none,
    this.upgrades = const UpgradeLevels(),
    this.inventory = const {},
    this.startWithWard = false,
    this.playerLevel = 1,
    this.knownTutorials = const {},
    List<String>? spells,
  })  : enemyHp = enemyHp ??
            [
              for (var i = 0; i < enemies.length; i++)
                (i < battle.enemies.length ? battle.enemies[i].hp : null) ?? enemies[i].maxHp,
            ],
        spells = spells ?? [config.playerSpecial];

  EnemyDefinition get enemy => enemies.first;
  int get playerMaxHp => config.balance.playerMaxHp;

  EnemyBehaviour behaviourOf(int index) =>
      config.behaviourFor(enemies[index].archetype.name).merge(enemies[index].behaviour);
}

enum BattlePhase { intro, turnStart, awaitingInput, resolving, stageTransition, victory, defeat }

extension BattlePhaseX on BattlePhase {
  bool get isOver => this == BattlePhase.victory || this == BattlePhase.defeat;
}

class ShieldSnapshot extends Equatable {
  final int strength;
  final int remaining;

  const ShieldSnapshot({required this.strength, required this.remaining});

  @override
  List<Object?> get props => [strength, remaining];
}

class EnemySnapshot extends Equatable {
  final int index;
  final String id;
  final String name;
  final int hp;
  final int maxHp;
  final ShieldSnapshot? shield;
  final bool staggered;

  /// What the enemy is preparing for its next turn.
  final MoveKind? intent;
  final String? intentMoveId;

  /// Poison ticks still to come (0 = not poisoned).
  final int poisonTicks;

  const EnemySnapshot({
    required this.index,
    required this.id,
    required this.name,
    required this.hp,
    required this.maxHp,
    this.shield,
    this.staggered = false,
    this.intent,
    this.intentMoveId,
    this.poisonTicks = 0,
  });

  bool get alive => hp > 0;
  double get hpFraction => maxHp == 0 ? 0 : hp / maxHp;
  bool get poisoned => poisonTicks > 0;

  @override
  List<Object?> get props => [index, hp, shield, staggered, intent, intentMoveId, poisonTicks];
}

/// Why a known spell cannot be cast right now.
enum SpellBlock { none, cooldown, mana, immune, turn }

/// One known player Special as the HUD sees it.
class SpellState extends Equatable {
  final String id;
  final int manaCost;

  /// Attack turns until the spell is ready again (0 = ready).
  final int cooldownLeft;

  /// Castable this very moment (own Normal-attack turn, enough mana, ready).
  final bool castable;
  final SpellBlock block;

  /// Mana still missing for a cast (0 = affordable).
  final int manaMissing;

  const SpellState({
    required this.id,
    required this.manaCost,
    this.cooldownLeft = 0,
    this.castable = false,
    this.block = SpellBlock.none,
    this.manaMissing = 0,
  });

  @override
  List<Object?> get props => [id, manaCost, cooldownLeft, castable, block, manaMissing];
}

/// Result of a whole move (all its tasks). Drives HUD and choreography.
class ActionOutcome extends Equatable {
  final BattleTurn turn;
  final MoveKind kind;
  final String? moveId;
  final MoveEffect effect;
  final int actor;
  final int target;
  final int successes;
  final int total;

  /// Damage dealt per enemy index.
  final Map<int, int> damageToEnemies;
  final int damageToPlayer;
  final bool blockedByWard;
  final bool shieldCracked;
  final bool shieldShattered;
  final bool shieldRaised;
  final bool lockApplied;
  final bool timedOut;

  /// Normal attack that failed (wrong or too slow) and landed weakly.
  final bool weakCast;

  /// Player Special that made the target lose its next turn.
  final bool staggerApplied;

  /// Ward charges gained by a player Special.
  final int wardCharges;

  /// Damage thrown back by the player's ward at the enemy whose hit it absorbed.
  final int reflected;

  /// Poison ticks applied by this move (to the target enemy, or to the
  /// player for enemy moves).
  final int poisonApplied;

  /// Player Special with no stage solved: mana spent, no cooldown started.
  final bool spellFizzled;
  final String? pickedOptionId;
  final String? correctOptionId;

  /// 0..1 visual intensity (combo, flow, success share).
  final double intensity;

  const ActionOutcome({
    required this.turn,
    required this.kind,
    this.moveId,
    this.effect = MoveEffect.damage,
    required this.actor,
    required this.target,
    required this.successes,
    required this.total,
    this.damageToEnemies = const {},
    this.damageToPlayer = 0,
    this.blockedByWard = false,
    this.shieldCracked = false,
    this.shieldShattered = false,
    this.shieldRaised = false,
    this.lockApplied = false,
    this.timedOut = false,
    this.weakCast = false,
    this.staggerApplied = false,
    this.wardCharges = 0,
    this.reflected = 0,
    this.poisonApplied = 0,
    this.spellFizzled = false,
    this.pickedOptionId,
    this.correctOptionId,
    this.intensity = 0,
  });

  bool get success => total == 0 || successes == total;
  bool get partial => successes > 0 && successes < total;
  int get totalDamageToEnemies => damageToEnemies.values.fold(0, (sum, value) => sum + value);

  @override
  List<Object?> get props => [
        turn,
        kind,
        moveId,
        actor,
        target,
        successes,
        total,
        damageToEnemies,
        damageToPlayer,
        blockedByWard,
        shieldCracked,
        shieldShattered,
        shieldRaised,
        lockApplied,
        timedOut,
        weakCast,
        staggerApplied,
        wardCharges,
        reflected,
        poisonApplied,
        spellFizzled,
        pickedOptionId,
        correctOptionId,
      ];
}

/// Immutable snapshot for the UI. Timer countdown is read separately each
/// frame (see `BattleEngine.timerFraction`) to avoid rebuilding on every tick.
class BattleSnapshot extends Equatable {
  final BattlePhase phase;
  final BattleTurn turn;
  final MoveKind? moveKind;
  final String? moveId;
  final String? moveLabel;

  /// Acting enemy index (enemy turns) or -1.
  final int actor;
  final bool criticalOpportunity;

  final int playerHp;
  final int playerMaxHp;
  final List<EnemySnapshot> enemies;
  final int targetIndex;

  final LanguageChallenge? challenge;
  final int taskIndex;
  final int taskCount;
  final List<bool> taskResults;

  final Set<String> dimmedOptionIds;
  final Set<String> hiddenOptionIds;
  final String? revealedLetter;
  final List<String> placedOptionIds;
  final String? hintedOptionId;
  final String? eatenOptionId;
  final Set<String> matchedOptionIds;
  final String? selectedOptionId;
  final String? missedOptionId;

  final double timerTotal;
  final bool timerFrozen;

  final int combo;
  final int maxCombo;
  final bool wordFlow;
  final double specialCharge;
  final bool specialReady;
  final bool specialUnlocked;
  final bool playerLocked;

  final int stageIndex;
  final int stageCount;
  final String? stageName;
  final bool enraged;

  final Map<BuffType, int> buffs;
  final Set<BuffType> usedThisChallenge;
  final bool secondChanceArmed;

  /// Enemy hits the player's ward will still absorb.
  final int wardCharges;

  /// Player Specials known in this battle (starter first).
  final List<String> knownSpells;

  /// Mana now / maximum, and the state of every known spell.
  final int mana;
  final int manaMax;
  final List<SpellState> spells;

  /// Poison ticks the player still has to take.
  final int playerPoisonTicks;
  final int score;
  final ActionOutcome? lastOutcome;

  /// Result of the task just answered inside a multi-task move.
  final bool? lastTaskSuccess;

  /// Option picked in the task just answered (choice tasks).
  final String? pickedOptionId;

  /// One-time coaching line key for the current move.
  final String? coachKey;

  const BattleSnapshot({
    required this.phase,
    this.turn = BattleTurn.player,
    this.moveKind,
    this.moveId,
    this.moveLabel,
    this.actor = -1,
    this.criticalOpportunity = false,
    required this.playerHp,
    required this.playerMaxHp,
    required this.enemies,
    this.targetIndex = 0,
    this.challenge,
    this.taskIndex = 0,
    this.taskCount = 0,
    this.taskResults = const [],
    this.dimmedOptionIds = const {},
    this.hiddenOptionIds = const {},
    this.revealedLetter,
    this.placedOptionIds = const [],
    this.hintedOptionId,
    this.eatenOptionId,
    this.matchedOptionIds = const {},
    this.selectedOptionId,
    this.missedOptionId,
    this.timerTotal = 0,
    this.timerFrozen = false,
    this.combo = 0,
    this.maxCombo = 0,
    this.wordFlow = false,
    this.specialCharge = 0,
    this.specialReady = false,
    this.specialUnlocked = false,
    this.playerLocked = false,
    this.stageIndex = 0,
    this.stageCount = 1,
    this.stageName,
    this.enraged = false,
    this.buffs = const {},
    this.usedThisChallenge = const {},
    this.secondChanceArmed = false,
    this.wardCharges = 0,
    this.knownSpells = const [],
    this.mana = 0,
    this.manaMax = 100,
    this.spells = const [],
    this.playerPoisonTicks = 0,
    this.score = 0,
    this.lastOutcome,
    this.lastTaskSuccess,
    this.pickedOptionId,
    this.coachKey,
  });

  bool get hasTimer => timerTotal > 0;
  bool get wardArmed => wardCharges > 0;
  bool get playerPoisoned => playerPoisonTicks > 0;
  SpellState? spell(String id) {
    for (final state in spells) {
      if (state.id == id) return state;
    }
    return null;
  }
  bool get acceptsInput => phase == BattlePhase.awaitingInput;
  bool get isPlayerTurn => turn == BattleTurn.player;
  double get playerHpFraction => playerMaxHp == 0 ? 0 : playerHp / playerMaxHp;
  EnemySnapshot? get target => targetIndex < enemies.length ? enemies[targetIndex] : null;
  EnemySnapshot get primary => enemies.first;
  bool get targetShielded => target?.shield != null;

  @override
  List<Object?> get props => [
        phase,
        turn,
        moveKind,
        moveId,
        actor,
        criticalOpportunity,
        playerHp,
        enemies,
        targetIndex,
        challenge,
        taskIndex,
        taskResults,
        dimmedOptionIds,
        hiddenOptionIds,
        revealedLetter,
        placedOptionIds,
        hintedOptionId,
        eatenOptionId,
        matchedOptionIds,
        selectedOptionId,
        missedOptionId,
        timerTotal,
        timerFrozen,
        combo,
        maxCombo,
        wordFlow,
        specialCharge,
        specialReady,
        playerLocked,
        stageIndex,
        enraged,
        buffs,
        usedThisChallenge,
        secondChanceArmed,
        wardCharges,
        knownSpells,
        mana,
        manaMax,
        spells,
        playerPoisonTicks,
        score,
        lastOutcome,
        lastTaskSuccess,
        pickedOptionId,
        coachKey,
      ];
}

/// One answered task, used for stars, rewards and word mastery.
class ChallengeRecord extends Equatable {
  final ChallengeType type;
  final BattleTurn turn;
  final MoveKind kind;
  final String? moveId;
  final List<String> wordIds;
  final String? focusWordId;
  final String contentKey;
  final bool success;
  final bool firstTry;
  final int attempts;
  final double responseSeconds;
  final double targetSeconds;
  final bool timedOut;

  const ChallengeRecord({
    required this.type,
    this.turn = BattleTurn.player,
    this.kind = MoveKind.normal,
    this.moveId,
    required this.wordIds,
    this.focusWordId,
    this.contentKey = '',
    required this.success,
    required this.firstTry,
    required this.attempts,
    required this.responseSeconds,
    required this.targetSeconds,
    this.timedOut = false,
  });

  @override
  List<Object?> get props => [type, turn, kind, wordIds, success, firstTry, attempts, responseSeconds];
}

class BattleResult extends Equatable {
  final bool victory;
  final bool abandoned;
  final List<ChallengeRecord> records;
  final int maxCombo;
  final int score;
  final double playerHpFraction;
  final Map<BuffType, int> buffsConsumed;
  final double durationSeconds;

  /// Tutorial keys first seen in this battle.
  final Set<String> tutorialsSeen;
  final int specialsUsed;
  final int criticalsLanded;

  /// Player attack turns taken (Normal attacks and Specials), for the
  /// efficiency star.
  final int attackTurns;

  /// Player Specials cast, by move id.
  final List<String> spellsUsed;

  /// Casts with no stage solved (mana spent, no effect).
  final List<String> spellsFizzled;
  final int manaSpent;
  final int manaGained;

  /// Damage the player took, including poison ticks.
  final int damageTaken;

  const BattleResult({
    required this.victory,
    this.abandoned = false,
    required this.records,
    required this.maxCombo,
    required this.score,
    required this.playerHpFraction,
    required this.buffsConsumed,
    required this.durationSeconds,
    this.tutorialsSeen = const {},
    this.specialsUsed = 0,
    this.criticalsLanded = 0,
    this.attackTurns = 0,
    this.spellsUsed = const [],
    this.spellsFizzled = const [],
    this.manaSpent = 0,
    this.manaGained = 0,
    this.damageTaken = 0,
  });

  int get correctFirstTry => records.where((record) => record.firstTry).length;

  double get accuracy => records.isEmpty ? 0 : correctFirstTry / records.length;

  /// Mean of response / target time over answered challenges (1.0 = on target).
  double get speedRatio {
    final timed = records.where((record) => record.targetSeconds > 0).toList();
    if (timed.isEmpty) return 1;
    final total = timed.fold<double>(0, (sum, r) => sum + r.responseSeconds / r.targetSeconds);
    return total / timed.length;
  }

  @override
  List<Object?> get props => [victory, abandoned, records, maxCombo, score, playerHpFraction];
}
