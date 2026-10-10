import '../content/json_utils.dart';
import '../language/challenge_type.dart';
import '../language/distractor_style.dart';

/// The only three attack categories, for the player and for enemies.
enum MoveKind {
  normal,
  critical,
  special;

  static MoveKind parse(Object? raw) =>
      MoveKind.values.firstWhere((value) => value.name == raw, orElse: () => MoveKind.normal);
}

enum BattleTurn { player, enemy }

/// What a move does when it resolves.
enum MoveEffect {
  /// Failed tasks let damage through (enemy) / successful tasks deal damage (player).
  damage,

  /// Raises a protective barrier on an enemy.
  shield,

  /// Failure locks the player's next attack.
  lock,

  /// Player Special: raises a ward that absorbs the next enemy hits.
  ward,

  /// Player Special: the enemy loses its next turn (plus some damage).
  bind,

  /// Player Special: every solved task is one hit.
  multiHit,

  /// Damage over time: the target takes [MoveDefinition.amount] at the start
  /// of each of its turns for [MoveDefinition.duration] turns. Ticks ignore
  /// stone skin and shields. Enemy version: failure poisons the player.
  poison;

  static MoveEffect parse(Object? raw) =>
      MoveEffect.values.firstWhere((value) => value.name == raw, orElse: () => MoveEffect.damage);
}

/// Which timing rule a move's shared timer uses (see [TimerPolicy]).
enum TimerUse {
  none,

  /// Normal attacks and defences: relaxed, with reading time.
  normal,
  enemyCritical,
  playerCritical,
  enemySpecial;

  static TimerUse parse(Object? raw) =>
      TimerUse.values.firstWhere((value) => value.name == raw, orElse: () => TimerUse.none);
}

enum EnemyRole {
  attacker,

  /// Prefers to protect an ally in two-enemy fights.
  guardian;

  static EnemyRole parse(Object? raw) =>
      EnemyRole.values.firstWhere((value) => value.name == raw, orElse: () => EnemyRole.attacker);
}

/// One English task inside a move. A move with several tasks is a
/// multi-stage / rapid challenge built from the same reusable components.
class TaskSpec {
  /// One of these types is picked for the task (e.g. missing rune or sentence).
  final List<ChallengeType> types;
  final int degreeOffset;
  final DistractorStyle? style;

  /// Reuse the previous task's prompt word (Mirror Spell: synonym + antonym).
  final bool samePrompt;

  /// Prefer words the player already knows (used under time pressure).
  final bool preferFamiliar;

  const TaskSpec(this.types, {this.degreeOffset = 0, this.style, this.samePrompt = false, this.preferFamiliar = false});

  factory TaskSpec.fromJson(Object? json) {
    if (json is String) {
      final type = ChallengeType.tryParse(json);
      if (type == null) throw FormatException('Unknown task "$json"');
      return TaskSpec([type]);
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final types = [
        ...JsonRead.strings(map, 'types').map(ChallengeType.tryParse).whereType<ChallengeType>(),
        if (ChallengeType.tryParse(map['type']) case final type?) type,
      ];
      if (types.isEmpty) throw FormatException('Task without type: $json');
      return TaskSpec(
        types,
        degreeOffset: JsonRead.integer(map, 'degreeOffset', fallback: 0),
        style: map['style'] == null ? null : DistractorStyle.parse(map['style']),
        samePrompt: JsonRead.boolean(map, 'samePrompt'),
        preferFamiliar: JsonRead.boolean(map, 'preferFamiliar'),
      );
    }
    throw FormatException('Invalid task: $json');
  }
}

/// A data-driven move: an enemy Special, a player Critical mini-game or the
/// player's Special incantation.
class MoveDefinition {
  final String id;

  /// English display label, resolved through localisation in the UI.
  final String label;
  final MoveKind kind;
  final MoveEffect effect;
  final List<TaskSpec> tasks;
  final TimerUse timer;
  final double timerScale;

  /// Enemy moves: share of the enemy attack taken per failed task.
  final double damagePerFailure;

  /// Shield moves: barrier strength (0 = use the enemy's behaviour value).
  final int shieldStrength;
  final double weight;

  /// Tutorial key shown the first time the move appears.
  final String tutorial;

  /// Player Specials: damage of the spell (per hit for [MoveEffect.multiHit];
  /// 0 = the balance default).
  final int amount;

  /// Player wards: enemy hits absorbed on full success.
  final int charges;

  /// Player Specials: mana spent when the cast begins (0 = free).
  final int manaCost;

  /// Player Specials: attack turns to wait after a cast that did something.
  final int cooldown;

  /// Poison: number of ticks on full success.
  final int duration;

  /// Player wards: damage thrown back at an attacker whose hit was absorbed.
  final int reflect;

  const MoveDefinition({
    required this.id,
    required this.label,
    this.kind = MoveKind.special,
    this.effect = MoveEffect.damage,
    this.tasks = const [],
    this.timer = TimerUse.none,
    this.timerScale = 1,
    this.damagePerFailure = 1,
    this.shieldStrength = 0,
    this.weight = 1,
    this.tutorial = 'enemySpecial',
    this.amount = 0,
    this.charges = 2,
    this.manaCost = 0,
    this.cooldown = 0,
    this.duration = 3,
    this.reflect = 0,
  });

  /// Rough power shown to the player: number of English stages.
  int get stages => tasks.length;

  bool get isPlayerSpecial => kind == MoveKind.special && manaCost > 0;

  factory MoveDefinition.fromJson(Map<String, dynamic> json) => MoveDefinition(
        id: JsonRead.string(json, 'id'),
        label: JsonRead.optString(json, 'label') ?? JsonRead.string(json, 'id'),
        kind: MoveKind.parse(json['kind'] ?? 'special'),
        effect: MoveEffect.parse(json['effect']),
        tasks: json['tasks'] is List ? (json['tasks'] as List).map(TaskSpec.fromJson).toList() : const [],
        timer: TimerUse.parse(json['timer']),
        timerScale: JsonRead.number(json, 'timerScale', fallback: 1),
        damagePerFailure: JsonRead.number(json, 'damagePerFailure', fallback: 1),
        shieldStrength: JsonRead.integer(json, 'shieldStrength', fallback: 0),
        weight: JsonRead.number(json, 'weight', fallback: 1),
        tutorial: JsonRead.optString(json, 'tutorial') ?? 'enemySpecial',
        amount: JsonRead.integer(json, 'amount', fallback: 0),
        charges: JsonRead.integer(json, 'charges', fallback: 2),
        manaCost: JsonRead.integer(json, 'manaCost', fallback: 0).clamp(0, 999),
        cooldown: JsonRead.integer(json, 'cooldown', fallback: 0).clamp(0, 99),
        duration: JsonRead.integer(json, 'duration', fallback: 3).clamp(1, 9),
        reflect: JsonRead.integer(json, 'reflect', fallback: 0).clamp(0, 999),
      );
}

/// How an enemy archetype fights. Values come from combat.json archetypes and
/// can be overridden per enemy.
class EnemyBehaviour {
  final double criticalChance;
  final double specialChance;
  final List<String> specials;
  final String? signature;
  final int shieldStrength;
  final EnemyRole role;

  /// Share of Normal-attack damage this enemy ignores (stone skin).
  /// Criticals and Specials always pierce it.
  final double armor;

  /// Multiplies the time the player gets against this enemy's attacks:
  /// below 1 = quick enemy, above 1 = slow, obviously telegraphed enemy.
  final double timerScale;

  /// Visual/audio family of this enemy's magic (slash, rock, arcane, ink,
  /// spark, smash, thorn, frost, steel). Purely presentational.
  final String element;

  /// Ethereal enemies (wisps) cannot be poisoned.
  final bool poisonImmune;

  const EnemyBehaviour({
    this.criticalChance = 0.15,
    this.specialChance = 0.1,
    this.specials = const [],
    this.signature,
    this.shieldStrength = 1,
    this.role = EnemyRole.attacker,
    this.armor = 0,
    this.timerScale = 1,
    this.element = 'arcane',
    this.poisonImmune = false,
  });

  EnemyBehaviour merge(Map<String, dynamic> json) => EnemyBehaviour(
        criticalChance: JsonRead.number(json, 'criticalChance', fallback: criticalChance),
        specialChance: JsonRead.number(json, 'specialChance', fallback: specialChance),
        specials: json.containsKey('specials') ? JsonRead.strings(json, 'specials') : specials,
        signature: JsonRead.optString(json, 'signature') ?? signature,
        shieldStrength: JsonRead.integer(json, 'shieldStrength', fallback: shieldStrength),
        role: json.containsKey('role') ? EnemyRole.parse(json['role']) : role,
        armor: JsonRead.number(json, 'armor', fallback: armor).clamp(0.0, 0.6),
        timerScale: JsonRead.number(json, 'timerScale', fallback: timerScale).clamp(0.5, 2.0),
        element: JsonRead.optString(json, 'element') ?? element,
        poisonImmune: json.containsKey('poisonImmune') ? JsonRead.boolean(json, 'poisonImmune') : poisonImmune,
      );
}

/// Damage and pacing numbers. The player never sees these formulas.
class BalanceConfig {
  final int playerMaxHp;
  final int normalDamage;
  final int counterDamage;
  final int criticalCounterDamage;
  final int criticalAttackDamage;
  final int specialDamage;
  final double specialSplash;

  /// Share of Normal damage dealt by a Weak Cast (wrong answer or timeout).
  final double weakCastShare;

  /// Share of the enemy's attack it lands as a counter when the player's
  /// attack word was wrong (timeouts are not countered).
  final double weakCastCounterShare;

  /// Special damage share by success fraction: [0 tasks, ≥1/3, ≥2/3, all].
  final List<double> specialPartial;
  final double enemyCriticalMultiplier;
  final double enragedMultiplier;
  final double comboStep;
  final int comboCap;
  final int flowThreshold;
  final double flowSeconds;
  final double flowDamageBonus;
  final int optionCount;
  final int matchMistakesAllowed;
  final int incantationAttempts;
  final double timeFreezeSeconds;
  final double extraTimeSeconds;
  final int runeSenseChallenges;

  const BalanceConfig({
    this.playerMaxHp = 100,
    this.normalDamage = 14,
    this.counterDamage = 5,
    this.criticalCounterDamage = 9,
    this.criticalAttackDamage = 18,
    this.specialDamage = 56,
    this.specialSplash = 0.5,
    this.weakCastShare = 0.35,
    this.weakCastCounterShare = 0.25,
    this.specialPartial = const [0.0, 0.3, 0.65, 1.0],
    this.enemyCriticalMultiplier = 1.6,
    this.enragedMultiplier = 1.2,
    this.comboStep = 0.03,
    this.comboCap = 8,
    this.flowThreshold = 5,
    this.flowSeconds = 15,
    this.flowDamageBonus = 0.15,
    this.optionCount = 4,
    this.matchMistakesAllowed = 2,
    this.incantationAttempts = 2,
    this.timeFreezeSeconds = 6,
    this.extraTimeSeconds = 5,
    this.runeSenseChallenges = 3,
  });

  factory BalanceConfig.fromJson(Map<String, dynamic> json) {
    const d = BalanceConfig();
    final partial = json['specialPartial'];
    return BalanceConfig(
      playerMaxHp: JsonRead.integer(json, 'playerMaxHp', fallback: d.playerMaxHp),
      normalDamage: JsonRead.integer(json, 'normalDamage', fallback: d.normalDamage),
      counterDamage: JsonRead.integer(json, 'counterDamage', fallback: d.counterDamage),
      criticalCounterDamage: JsonRead.integer(json, 'criticalCounterDamage', fallback: d.criticalCounterDamage),
      criticalAttackDamage: JsonRead.integer(json, 'criticalAttackDamage', fallback: d.criticalAttackDamage),
      specialDamage: JsonRead.integer(json, 'specialDamage', fallback: d.specialDamage),
      specialSplash: JsonRead.number(json, 'specialSplash', fallback: d.specialSplash),
      weakCastShare: JsonRead.number(json, 'weakCastShare', fallback: d.weakCastShare).clamp(0.0, 1.0),
      weakCastCounterShare: JsonRead.number(json, 'weakCastCounterShare', fallback: d.weakCastCounterShare).clamp(0.0, 1.0),
      specialPartial: partial is List && partial.length == 4
          ? partial.map((value) => (value as num).toDouble()).toList()
          : d.specialPartial,
      enemyCriticalMultiplier: JsonRead.number(json, 'enemyCriticalMultiplier', fallback: d.enemyCriticalMultiplier),
      enragedMultiplier: JsonRead.number(json, 'enragedMultiplier', fallback: d.enragedMultiplier),
      comboStep: JsonRead.number(json, 'comboStep', fallback: d.comboStep),
      comboCap: JsonRead.integer(json, 'comboCap', fallback: d.comboCap),
      flowThreshold: JsonRead.integer(json, 'flowThreshold', fallback: d.flowThreshold),
      flowSeconds: JsonRead.number(json, 'flowSeconds', fallback: d.flowSeconds),
      flowDamageBonus: JsonRead.number(json, 'flowDamageBonus', fallback: d.flowDamageBonus),
      optionCount: JsonRead.integer(json, 'optionCount', fallback: d.optionCount),
      matchMistakesAllowed: JsonRead.integer(json, 'matchMistakesAllowed', fallback: d.matchMistakesAllowed),
      incantationAttempts: JsonRead.integer(json, 'incantationAttempts', fallback: d.incantationAttempts),
      timeFreezeSeconds: JsonRead.number(json, 'timeFreezeSeconds', fallback: d.timeFreezeSeconds),
      extraTimeSeconds: JsonRead.number(json, 'extraTimeSeconds', fallback: d.extraTimeSeconds),
      runeSenseChallenges: JsonRead.integer(json, 'runeSenseChallenges', fallback: d.runeSenseChallenges),
    );
  }

  double comboMultiplier(int combo) => 1 + combo.clamp(0, comboCap) * comboStep;

  int get weakCastDamage => (normalDamage * weakCastShare).round().clamp(1, normalDamage);

  /// Special damage share for [successes] out of [total] tasks.
  double specialShare(int successes, int total) {
    if (total <= 0) return specialPartial.last;
    final fraction = successes / total;
    if (fraction >= 1) return specialPartial[3];
    if (fraction >= 0.66) return specialPartial[2];
    if (fraction >= 0.33) return specialPartial[1];
    return specialPartial[0];
  }
}

/// Mana: the single pool every player Special draws from. Starts each
/// battle at [start], never persists between battles, and grows with good
/// English (hits, defences, Criticals). Tuned so an average learner casts
/// roughly one Special per normal fight and three to four per boss.
class SpecialMeterConfig {
  final int max;
  final int start;
  final int normalHit;
  final int weakCast;
  final int defence;
  final int criticalDefence;
  final int criticalAttack;
  final int shieldBreak;
  final int comboMilestone;
  final int comboMilestoneEvery;
  final int flowBonus;

  const SpecialMeterConfig({
    this.max = 100,
    this.start = 20,
    this.normalHit = 9,
    this.weakCast = 0,
    this.defence = 7,
    this.criticalDefence = 12,
    this.criticalAttack = 10,
    this.shieldBreak = 8,
    this.comboMilestone = 6,
    this.comboMilestoneEvery = 4,
    this.flowBonus = 2,
  });

  factory SpecialMeterConfig.fromJson(Map<String, dynamic> json) {
    const d = SpecialMeterConfig();
    return SpecialMeterConfig(
      max: JsonRead.integer(json, 'max', fallback: d.max),
      start: JsonRead.integer(json, 'start', fallback: d.start),
      normalHit: JsonRead.integer(json, 'normalHit', fallback: d.normalHit),
      weakCast: JsonRead.integer(json, 'weakCast', fallback: d.weakCast),
      defence: JsonRead.integer(json, 'defence', fallback: d.defence),
      criticalDefence: JsonRead.integer(json, 'criticalDefence', fallback: d.criticalDefence),
      criticalAttack: JsonRead.integer(json, 'criticalAttack', fallback: d.criticalAttack),
      shieldBreak: JsonRead.integer(json, 'shieldBreak', fallback: d.shieldBreak),
      comboMilestone: JsonRead.integer(json, 'comboMilestone', fallback: d.comboMilestone),
      comboMilestoneEvery: JsonRead.integer(json, 'comboMilestoneEvery', fallback: d.comboMilestoneEvery),
      flowBonus: JsonRead.integer(json, 'flowBonus', fallback: d.flowBonus),
    );
  }
}

/// Frequency and fairness rules for Critical / Special moments.
class PacingConfig {
  final double playerCriticalChance;
  final double playerCriticalCap;
  final double comboCriticalBonus;

  /// Turns (player + enemy) that must pass after any Critical before a random one.
  final int criticalCooldownTurns;

  /// Own turns an enemy waits between two Specials.
  final int enemySpecialCooldown;

  /// Normal enemy turns required between two non-normal enemy moves.
  final int minNormalEnemyTurns;

  const PacingConfig({
    this.playerCriticalChance = 0.3,
    this.playerCriticalCap = 0.55,
    this.comboCriticalBonus = 0.03,
    this.criticalCooldownTurns = 3,
    this.enemySpecialCooldown = 3,
    this.minNormalEnemyTurns = 1,
  });

  factory PacingConfig.fromJson(Map<String, dynamic> json) {
    const d = PacingConfig();
    return PacingConfig(
      playerCriticalChance: JsonRead.number(json, 'playerCriticalChance', fallback: d.playerCriticalChance),
      playerCriticalCap: JsonRead.number(json, 'playerCriticalCap', fallback: d.playerCriticalCap),
      comboCriticalBonus: JsonRead.number(json, 'comboCriticalBonus', fallback: d.comboCriticalBonus),
      criticalCooldownTurns: JsonRead.integer(json, 'criticalCooldownTurns', fallback: d.criticalCooldownTurns),
      enemySpecialCooldown: JsonRead.integer(json, 'enemySpecialCooldown', fallback: d.enemySpecialCooldown),
      minNormalEnemyTurns: JsonRead.integer(json, 'minNormalEnemyTurns', fallback: d.minNormalEnemyTurns),
    );
  }
}

/// Seconds for timed moves. See [TimerPolicy] for how they are combined.
class TimerConfigSet {
  /// Normal attack / defence base seconds for degrees 1-2, 3 and 4+.
  /// Relaxed on purpose: urgency, not anxiety.
  final List<double> normal;
  final double minimumNormalSeconds;

  /// Enemy Critical base seconds for degrees 1-2, 3 and 4+.
  final List<double> enemyCritical;
  final double minimumChoiceSeconds;
  final double readingPerExtraChar;
  final int comfortableChars;
  final double unfamiliarBonus;
  final double familiarDiscount;
  final double hardWordBonus;
  final double playerCriticalPerPair;
  final double playerCriticalMatchBase;
  final double playerCriticalPerToken;
  final double playerCriticalSentenceBase;
  final double rapidPerTask;
  final double enemySpecialPerChoice;
  final double enemySpecialPerToken;
  final double enemySpecialSentenceBase;
  final double runeSeconds;

  const TimerConfigSet({
    this.normal = const [8.0, 7.5, 7.0],
    this.minimumNormalSeconds = 5,
    this.enemyCritical = const [5.5, 4.75, 4.0],
    this.minimumChoiceSeconds = 3.5,
    this.readingPerExtraChar = 0.06,
    this.comfortableChars = 26,
    this.unfamiliarBonus = 1.0,
    this.familiarDiscount = 0.4,
    this.hardWordBonus = 0.5,
    this.playerCriticalPerPair = 2.6,
    this.playerCriticalMatchBase = 3,
    this.playerCriticalPerToken = 1.5,
    this.playerCriticalSentenceBase = 4,
    this.rapidPerTask = 4,
    this.enemySpecialPerChoice = 6.5,
    this.enemySpecialPerToken = 1.4,
    this.enemySpecialSentenceBase = 6,
    this.runeSeconds = 8,
  });

  factory TimerConfigSet.fromJson(Map<String, dynamic> json) {
    const d = TimerConfigSet();
    final critical = json['enemyCritical'];
    final normal = json['normal'];
    return TimerConfigSet(
      normal: normal is List && normal.length == 3 ? normal.map((value) => (value as num).toDouble()).toList() : d.normal,
      minimumNormalSeconds: JsonRead.number(json, 'minimumNormalSeconds', fallback: d.minimumNormalSeconds),
      enemyCritical: critical is List && critical.length == 3
          ? critical.map((value) => (value as num).toDouble()).toList()
          : d.enemyCritical,
      minimumChoiceSeconds: JsonRead.number(json, 'minimumChoiceSeconds', fallback: d.minimumChoiceSeconds),
      readingPerExtraChar: JsonRead.number(json, 'readingPerExtraChar', fallback: d.readingPerExtraChar),
      comfortableChars: JsonRead.integer(json, 'comfortableChars', fallback: d.comfortableChars),
      unfamiliarBonus: JsonRead.number(json, 'unfamiliarBonus', fallback: d.unfamiliarBonus),
      familiarDiscount: JsonRead.number(json, 'familiarDiscount', fallback: d.familiarDiscount),
      hardWordBonus: JsonRead.number(json, 'hardWordBonus', fallback: d.hardWordBonus),
      playerCriticalPerPair: JsonRead.number(json, 'playerCriticalPerPair', fallback: d.playerCriticalPerPair),
      playerCriticalMatchBase: JsonRead.number(json, 'playerCriticalMatchBase', fallback: d.playerCriticalMatchBase),
      playerCriticalPerToken: JsonRead.number(json, 'playerCriticalPerToken', fallback: d.playerCriticalPerToken),
      playerCriticalSentenceBase:
          JsonRead.number(json, 'playerCriticalSentenceBase', fallback: d.playerCriticalSentenceBase),
      rapidPerTask: JsonRead.number(json, 'rapidPerTask', fallback: d.rapidPerTask),
      enemySpecialPerChoice: JsonRead.number(json, 'enemySpecialPerChoice', fallback: d.enemySpecialPerChoice),
      enemySpecialPerToken: JsonRead.number(json, 'enemySpecialPerToken', fallback: d.enemySpecialPerToken),
      enemySpecialSentenceBase: JsonRead.number(json, 'enemySpecialSentenceBase', fallback: d.enemySpecialSentenceBase),
      runeSeconds: JsonRead.number(json, 'runeSeconds', fallback: d.runeSeconds),
    );
  }
}

/// Mechanics unlock gradually by number of battles won in the save.
class MechanicGates {
  final int critical;
  final int special;
  final int protection;
  final int enemySpecials;

  const MechanicGates({this.critical = 1, this.special = 2, this.protection = 3, this.enemySpecials = 5});

  factory MechanicGates.fromJson(Map<String, dynamic> json) {
    const d = MechanicGates();
    return MechanicGates(
      critical: JsonRead.integer(json, 'critical', fallback: d.critical),
      special: JsonRead.integer(json, 'special', fallback: d.special),
      protection: JsonRead.integer(json, 'protection', fallback: d.protection),
      enemySpecials: JsonRead.integer(json, 'enemySpecials', fallback: d.enemySpecials),
    );
  }

  MechanicAccess forWins(int wins) => MechanicAccess(
        critical: wins >= critical,
        special: wins >= special,
        protection: wins >= protection,
        enemySpecials: wins >= enemySpecials,
      );
}

class MechanicAccess {
  final bool critical;
  final bool special;
  final bool protection;
  final bool enemySpecials;

  const MechanicAccess({this.critical = true, this.special = true, this.protection = true, this.enemySpecials = true});

  static const all = MechanicAccess();
  static const none = MechanicAccess(critical: false, special: false, protection: false, enemySpecials: false);
}

/// Hold durations (seconds) that pace the battle choreography.
class PacingHolds {
  final double intro;
  final double playerTurnBanner;
  final double enemyTurnBanner;
  final double telegraph;
  final double normalAttack;
  final double defence;
  final double criticalDefence;
  final double criticalOpportunity;
  final double criticalAttack;
  final double special;
  final double shieldRaise;
  final double taskStep;
  final double skippedTurn;
  final double stageTransition;
  final double defeatEnemy;
  final double poisonTick;

  const PacingHolds({
    this.intro = 1.6,
    this.playerTurnBanner = 0.7,
    this.enemyTurnBanner = 0.75,
    this.telegraph = 1.4,
    this.normalAttack = 1.25,
    this.defence = 1.35,
    this.criticalDefence = 1.6,
    this.criticalOpportunity = 1.1,
    this.criticalAttack = 1.5,
    this.special = 3.2,
    this.shieldRaise = 1.5,
    this.taskStep = 0.6,
    this.skippedTurn = 1.2,
    this.stageTransition = 2.2,
    this.defeatEnemy = 1.4,
    this.poisonTick = 1.0,
  });
}

/// All combat tuning in one object, loaded from `combat.json`.
class CombatConfig {
  final BalanceConfig balance;
  final SpecialMeterConfig meter;
  final PacingConfig pacing;
  final TimerConfigSet timers;
  final MechanicGates gates;
  final PacingHolds holds;
  final Map<String, EnemyBehaviour> archetypes;
  final Map<String, MoveDefinition> moves;
  final List<String> playerCriticals;

  /// The spell every apprentice starts with.
  final String playerSpecial;

  /// Spells that map nodes can teach (`teaches` in regions.json), in the
  /// order the spellbook shows them.
  final List<String> learnableSpecials;

  const CombatConfig({
    this.balance = const BalanceConfig(),
    this.meter = const SpecialMeterConfig(),
    this.pacing = const PacingConfig(),
    this.timers = const TimerConfigSet(),
    this.gates = const MechanicGates(),
    this.holds = const PacingHolds(),
    this.archetypes = const {},
    this.moves = defaultMoves,
    this.playerCriticals = const ['word_match', 'sentence_strike', 'rapid_words'],
    this.playerSpecial = 'apprentice_incantation',
    this.learnableSpecials = const ['guardian_ward', 'thorn_blight', 'rune_bind'],
  });

  MoveDefinition? move(String id) => moves[id];

  /// Every player Special in display order: starter first, then learnable.
  List<String> get allSpecials => [playerSpecial, ...learnableSpecials.where((id) => id != playerSpecial)];

  EnemyBehaviour behaviourFor(String archetype) => archetypes[archetype] ?? const EnemyBehaviour();

  factory CombatConfig.fromJson(Map<String, dynamic> json) {
    final moves = <String, MoveDefinition>{...defaultMoves};
    for (final item in JsonRead.objects(json, 'moves')) {
      final move = MoveDefinition.fromJson(item);
      moves[move.id] = move;
    }
    final archetypes = <String, EnemyBehaviour>{};
    final rawArchetypes = JsonRead.object(json, 'archetypes');
    for (final entry in rawArchetypes.entries) {
      if (entry.value is Map) {
        archetypes[entry.key] = const EnemyBehaviour().merge(Map<String, dynamic>.from(entry.value as Map));
      }
    }
    final criticals = JsonRead.strings(json, 'playerCriticals');
    return CombatConfig(
      balance: BalanceConfig.fromJson(JsonRead.object(json, 'balance')),
      meter: SpecialMeterConfig.fromJson(JsonRead.object(json, 'specialMeter')),
      pacing: PacingConfig.fromJson(JsonRead.object(json, 'pacing')),
      timers: TimerConfigSet.fromJson(JsonRead.object(json, 'timers')),
      gates: MechanicGates.fromJson(JsonRead.object(json, 'gates')),
      archetypes: archetypes,
      moves: moves,
      playerCriticals: criticals.isEmpty ? const ['word_match', 'sentence_strike', 'rapid_words'] : criticals,
      playerSpecial: JsonRead.optString(json, 'playerSpecial') ?? 'apprentice_incantation',
      learnableSpecials: json.containsKey('learnableSpecials')
          ? JsonRead.strings(json, 'learnableSpecials')
          : const ['guardian_ward', 'thorn_blight', 'rune_bind'],
    );
  }

  /// Built-in moves, so the game works even if combat.json is missing a move.
  static const Map<String, MoveDefinition> defaultMoves = {
    'word_match': MoveDefinition(
      id: 'word_match',
      label: 'Word Match',
      kind: MoveKind.critical,
      tasks: [TaskSpec([ChallengeType.wordMatch], preferFamiliar: true)],
      timer: TimerUse.playerCritical,
      tutorial: 'criticalAttack',
    ),
    'sentence_strike': MoveDefinition(
      id: 'sentence_strike',
      label: 'Sentence Strike',
      kind: MoveKind.critical,
      tasks: [TaskSpec([ChallengeType.incantation], degreeOffset: -1)],
      timer: TimerUse.playerCritical,
      tutorial: 'criticalAttack',
    ),
    'rapid_words': MoveDefinition(
      id: 'rapid_words',
      label: 'Rapid Words',
      kind: MoveKind.critical,
      tasks: [
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
        TaskSpec([ChallengeType.synonym], preferFamiliar: true),
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
      ],
      timer: TimerUse.playerCritical,
      tutorial: 'criticalAttack',
    ),
    // Starter spell: direct damage, splashes a second enemy.
    'apprentice_incantation': MoveDefinition(
      id: 'apprentice_incantation',
      label: 'Apprentice Incantation',
      kind: MoveKind.special,
      tasks: [
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
        TaskSpec([ChallengeType.synonym]),
        TaskSpec([ChallengeType.missingRune, ChallengeType.incantation]),
      ],
      manaCost: 35,
      cooldown: 2,
      tutorial: 'special',
    ),
    // Witnessed at the Keeper of the Gate: absorbs the next enemy hits and
    // throws part of each back.
    'guardian_ward': MoveDefinition(
      id: 'guardian_ward',
      label: 'Guardian Ward',
      kind: MoveKind.special,
      effect: MoveEffect.ward,
      tasks: [
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
        TaskSpec([ChallengeType.missingRune]),
      ],
      charges: 2,
      reflect: 10,
      manaCost: 30,
      cooldown: 3,
      tutorial: 'guardianWard',
    ),
    // Witnessed at the Thornmother: poison that ticks through stone skin
    // and shields. Ethereal enemies are immune.
    'thorn_blight': MoveDefinition(
      id: 'thorn_blight',
      label: 'Thorn Blight',
      kind: MoveKind.special,
      effect: MoveEffect.poison,
      tasks: [
        TaskSpec([ChallengeType.synonym]),
        TaskSpec([ChallengeType.incantation, ChallengeType.missingRune], degreeOffset: -1),
      ],
      amount: 14,
      duration: 3,
      manaCost: 35,
      cooldown: 3,
      tutorial: 'thornBlight',
    ),
    // Witnessed at the Ruin Scribes: the enemy loses its next turn.
    'rune_bind': MoveDefinition(
      id: 'rune_bind',
      label: 'Rune Bind',
      kind: MoveKind.special,
      effect: MoveEffect.bind,
      tasks: [
        TaskSpec([ChallengeType.missingRune]),
        TaskSpec([ChallengeType.synonym]),
      ],
      amount: 28,
      manaCost: 35,
      cooldown: 3,
      tutorial: 'runeBind',
    ),
    // Kept for content that still references it (v2 candidate): three quick
    // words, one hit each.
    'word_storm_spell': MoveDefinition(
      id: 'word_storm_spell',
      label: 'Word Storm',
      kind: MoveKind.special,
      effect: MoveEffect.multiHit,
      tasks: [
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
        TaskSpec([ChallengeType.synonym], preferFamiliar: true),
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
      ],
      timer: TimerUse.playerCritical,
      amount: 22,
      manaCost: 35,
      cooldown: 3,
      tutorial: 'wordStorm',
    ),
    // Thornmother signature: a failed defence leaves the player poisoned.
    'thorn_curse': MoveDefinition(
      id: 'thorn_curse',
      label: 'Thorn Curse',
      effect: MoveEffect.poison,
      tasks: [TaskSpec([ChallengeType.synonym])],
      timer: TimerUse.enemySpecial,
      damagePerFailure: 0.5,
      amount: 7,
      duration: 3,
      tutorial: 'thornCurse',
    ),
    'heavy_spell': MoveDefinition(
      id: 'heavy_spell',
      label: 'Heavy Spell',
      tasks: [TaskSpec([ChallengeType.antonym], degreeOffset: 1, style: DistractorStyle.semantic)],
      damagePerFailure: 1.8,
    ),
    'protection': MoveDefinition(
      id: 'protection',
      label: 'Protection Spell',
      effect: MoveEffect.shield,
      tutorial: 'shield',
    ),
    'rune_lock': MoveDefinition(
      id: 'rune_lock',
      label: 'Rune Lock',
      effect: MoveEffect.lock,
      tasks: [TaskSpec([ChallengeType.missingRune])],
      timer: TimerUse.enemySpecial,
      damagePerFailure: 0.3,
      tutorial: 'runeLock',
    ),
    'double_threat': MoveDefinition(
      id: 'double_threat',
      label: 'Double Threat',
      tasks: [TaskSpec([ChallengeType.antonym]), TaskSpec([ChallengeType.antonym])],
      timer: TimerUse.enemySpecial,
      damagePerFailure: 0.65,
    ),
    'sentence_curse': MoveDefinition(
      id: 'sentence_curse',
      label: 'Sentence Curse',
      tasks: [TaskSpec([ChallengeType.incantation], degreeOffset: -1)],
      timer: TimerUse.enemySpecial,
      damagePerFailure: 1.3,
    ),
    'broken_incantation': MoveDefinition(
      id: 'broken_incantation',
      label: 'Broken Incantation',
      tasks: [TaskSpec([ChallengeType.incantation])],
      timer: TimerUse.enemySpecial,
      timerScale: 1.15,
      damagePerFailure: 1.5,
    ),
    'mirror_spell': MoveDefinition(
      id: 'mirror_spell',
      label: 'Mirror Spell',
      tasks: [TaskSpec([ChallengeType.synonym]), TaskSpec([ChallengeType.antonym], samePrompt: true)],
      timer: TimerUse.enemySpecial,
      damagePerFailure: 0.8,
    ),
    'rune_seal': MoveDefinition(
      id: 'rune_seal',
      label: 'Rune Seal',
      tasks: [
        TaskSpec([ChallengeType.missingRune]),
        TaskSpec([ChallengeType.missingRune]),
        TaskSpec([ChallengeType.missingRune]),
      ],
      timer: TimerUse.enemySpecial,
      damagePerFailure: 0.55,
    ),
    'wisp_storm': MoveDefinition(
      id: 'wisp_storm',
      label: 'Wisp Storm',
      tasks: [
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
        TaskSpec([ChallengeType.synonym], preferFamiliar: true),
      ],
      timer: TimerUse.enemySpecial,
      timerScale: 0.85,
      damagePerFailure: 0.6,
    ),
    'word_storm': MoveDefinition(
      id: 'word_storm',
      label: 'Word Storm',
      tasks: [
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
        TaskSpec([ChallengeType.synonym], preferFamiliar: true),
        TaskSpec([ChallengeType.antonym], preferFamiliar: true),
      ],
      timer: TimerUse.enemySpecial,
      timerScale: 0.85,
      damagePerFailure: 0.55,
    ),
  };
}
