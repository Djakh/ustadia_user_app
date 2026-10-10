import 'package:equatable/equatable.dart';

import '../content/json_utils.dart';
import '../progression/buffs.dart';
import '../progression/upgrades.dart';
import '../progression/word_mastery.dart';

/// Per-node progress. Stored by node id so unknown ids from older/newer
/// content versions are simply ignored.
class NodeProgress extends Equatable {
  final bool completed;
  final int bestStars;
  final int bestScore;
  final int attempts;
  final int wins;

  /// Consecutive losses since the last win; drives silent assistance.
  final int failureStreak;

  /// Resolved mystery outcome index, fixed once revealed.
  final int? mysteryOutcome;

  const NodeProgress({
    this.completed = false,
    this.bestStars = 0,
    this.bestScore = 0,
    this.attempts = 0,
    this.wins = 0,
    this.failureStreak = 0,
    this.mysteryOutcome,
  });

  NodeProgress copyWith({
    bool? completed,
    int? bestStars,
    int? bestScore,
    int? attempts,
    int? wins,
    int? failureStreak,
    int? mysteryOutcome,
  }) =>
      NodeProgress(
        completed: completed ?? this.completed,
        bestStars: bestStars ?? this.bestStars,
        bestScore: bestScore ?? this.bestScore,
        attempts: attempts ?? this.attempts,
        wins: wins ?? this.wins,
        failureStreak: failureStreak ?? this.failureStreak,
        mysteryOutcome: mysteryOutcome ?? this.mysteryOutcome,
      );

  Map<String, dynamic> toJson() => {
        'c': completed,
        'st': bestStars,
        'sc': bestScore,
        'a': attempts,
        'w': wins,
        'f': failureStreak,
        if (mysteryOutcome != null) 'm': mysteryOutcome,
      };

  factory NodeProgress.fromJson(Map<String, dynamic> json) => NodeProgress(
        completed: JsonRead.boolean(json, 'c'),
        bestStars: JsonRead.integer(json, 'st', fallback: 0).clamp(0, 3),
        bestScore: JsonRead.integer(json, 'sc', fallback: 0),
        attempts: JsonRead.integer(json, 'a', fallback: 0),
        wins: JsonRead.integer(json, 'w', fallback: 0),
        failureStreak: JsonRead.integer(json, 'f', fallback: 0),
        mysteryOutcome: (json['m'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props =>
      [completed, bestStars, bestScore, attempts, wins, failureStreak, mysteryOutcome];
}

class WordForgeSettings extends Equatable {
  final bool muted;
  final bool reducedEffects;

  const WordForgeSettings({this.muted = false, this.reducedEffects = false});

  WordForgeSettings copyWith({bool? muted, bool? reducedEffects}) => WordForgeSettings(
      muted: muted ?? this.muted, reducedEffects: reducedEffects ?? this.reducedEffects);

  Map<String, dynamic> toJson() => {'muted': muted, 'reducedEffects': reducedEffects};

  factory WordForgeSettings.fromJson(Map<String, dynamic> json) => WordForgeSettings(
      muted: JsonRead.boolean(json, 'muted'), reducedEffects: JsonRead.boolean(json, 'reducedEffects'));

  @override
  List<Object?> get props => [muted, reducedEffects];
}

/// The complete persistent state of one save slot. Versioned; see
/// `SaveCodec` for migrations. Saved at meaningful checkpoints only (battle
/// end, node claim, purchases, settings, character creation), never per frame.
class WordForgeSave extends Equatable {
  static const int currentVersion = 4;
  static const int recentContentLimit = 24;

  final int version;

  /// Owner (signed-in profile). Slots are isolated per profile.
  final String playerId;
  final int slotIndex;
  final String saveId;
  final int createdAtMs;
  final int lastPlayedAtMs;

  /// Cosmetic apprentice choice (null for saves created before characters).
  final String? characterId;
  final int xp;
  final UpgradeLevels upgrades;
  final Map<BuffType, int> buffs;
  final String? currentRegionId;
  final String? lastNodeId;
  final Map<String, NodeProgress> nodes;
  final Set<String> unlockedNodeIds;
  final Map<String, WordStats> words;
  final int battleCount;
  final int battleWins;
  final int battlesSinceWard;

  /// One-time coaching lines already shown (per save).
  final Set<String> tutorialFlags;
  final List<String> recentContentKeys;
  final WordForgeSettings settings;

  /// Special spells learned with skill points (move ids), in learning order.
  /// Which spells *can* be learned follows from cleared teaching nodes.
  final List<String> spells;

  const WordForgeSave({
    this.version = currentVersion,
    required this.playerId,
    this.slotIndex = 1,
    this.saveId = '',
    this.createdAtMs = 0,
    this.lastPlayedAtMs = 0,
    this.characterId,
    this.xp = 0,
    this.upgrades = const UpgradeLevels(),
    this.buffs = const {},
    this.currentRegionId,
    this.lastNodeId,
    this.nodes = const {},
    this.unlockedNodeIds = const {},
    this.words = const {},
    this.battleCount = 0,
    this.battleWins = 0,
    this.battlesSinceWard = 0,
    this.tutorialFlags = const {},
    this.recentContentKeys = const [],
    this.settings = const WordForgeSettings(),
    this.spells = const [],
  });

  factory WordForgeSave.fresh(
    String playerId, {
    int slotIndex = 1,
    String? characterId,
    String saveId = '',
    int nowMs = 0,
  }) =>
      WordForgeSave(
        playerId: playerId,
        slotIndex: slotIndex,
        saveId: saveId,
        createdAtMs: nowMs,
        lastPlayedAtMs: nowMs,
        characterId: characterId,
        buffs: Map.of(starterBuffs),
      );

  bool isCompleted(String nodeId) => nodes[nodeId]?.completed ?? false;

  NodeProgress progressOf(String nodeId) => nodes[nodeId] ?? const NodeProgress();

  int get discoveredWordCount => words.values.where((stats) => stats.seen > 0).length;

  int get totalStars => nodes.values.fold(0, (sum, node) => sum + node.bestStars);

  WordForgeSave copyWith({
    int? slotIndex,
    String? saveId,
    int? lastPlayedAtMs,
    String? characterId,
    int? xp,
    UpgradeLevels? upgrades,
    Map<BuffType, int>? buffs,
    String? currentRegionId,
    String? lastNodeId,
    Map<String, NodeProgress>? nodes,
    Set<String>? unlockedNodeIds,
    Map<String, WordStats>? words,
    int? battleCount,
    int? battleWins,
    int? battlesSinceWard,
    Set<String>? tutorialFlags,
    List<String>? recentContentKeys,
    WordForgeSettings? settings,
    List<String>? spells,
  }) =>
      WordForgeSave(
        version: version,
        playerId: playerId,
        slotIndex: slotIndex ?? this.slotIndex,
        saveId: saveId ?? this.saveId,
        createdAtMs: createdAtMs,
        lastPlayedAtMs: lastPlayedAtMs ?? this.lastPlayedAtMs,
        characterId: characterId ?? this.characterId,
        xp: xp ?? this.xp,
        upgrades: upgrades ?? this.upgrades,
        buffs: buffs ?? this.buffs,
        currentRegionId: currentRegionId ?? this.currentRegionId,
        lastNodeId: lastNodeId ?? this.lastNodeId,
        nodes: nodes ?? this.nodes,
        unlockedNodeIds: unlockedNodeIds ?? this.unlockedNodeIds,
        words: words ?? this.words,
        battleCount: battleCount ?? this.battleCount,
        battleWins: battleWins ?? this.battleWins,
        battlesSinceWard: battlesSinceWard ?? this.battlesSinceWard,
        tutorialFlags: tutorialFlags ?? this.tutorialFlags,
        recentContentKeys: recentContentKeys ?? this.recentContentKeys,
        settings: settings ?? this.settings,
        spells: spells ?? this.spells,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'playerId': playerId,
        'slot': slotIndex,
        'saveId': saveId,
        'createdAt': createdAtMs,
        'lastPlayedAt': lastPlayedAtMs,
        if (characterId != null) 'character': characterId,
        'xp': xp,
        'upgrades': upgrades.toJson(),
        'buffs': BuffType.encodeMap(buffs),
        if (currentRegionId != null) 'currentRegionId': currentRegionId,
        if (lastNodeId != null) 'lastNodeId': lastNodeId,
        'nodes': {for (final entry in nodes.entries) entry.key: entry.value.toJson()},
        'unlocked': unlockedNodeIds.toList()..sort(),
        'words': {for (final entry in words.entries) entry.key: entry.value.toJson()},
        'battleCount': battleCount,
        'battleWins': battleWins,
        'battlesSinceWard': battlesSinceWard,
        'tutorials': tutorialFlags.toList()..sort(),
        'recent': recentContentKeys,
        'settings': settings.toJson(),
        'spells': spells,
      };

  factory WordForgeSave.fromJson(Map<String, dynamic> json) {
    Map<String, T> readMap<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = JsonRead.object(json, key);
      final result = <String, T>{};
      for (final entry in raw.entries) {
        if (entry.value is Map) {
          try {
            result[entry.key] = parse(Map<String, dynamic>.from(entry.value as Map));
          } on Object {
            // Skip a single corrupt entry instead of losing the whole save.
          }
        }
      }
      return result;
    }

    return WordForgeSave(
      version: JsonRead.integer(json, 'version', fallback: currentVersion),
      playerId: JsonRead.optString(json, 'playerId') ?? 'guest',
      slotIndex: JsonRead.integer(json, 'slot', fallback: 1).clamp(1, 3),
      saveId: JsonRead.optString(json, 'saveId') ?? '',
      createdAtMs: JsonRead.integer(json, 'createdAt', fallback: 0),
      lastPlayedAtMs: JsonRead.integer(json, 'lastPlayedAt', fallback: 0),
      characterId: JsonRead.optString(json, 'character'),
      xp: JsonRead.integer(json, 'xp', fallback: 0).clamp(0, 1 << 30),
      upgrades: UpgradeLevels.fromJson(JsonRead.intMap(json, 'upgrades')),
      buffs: BuffType.parseMap(json['buffs']),
      currentRegionId: JsonRead.optString(json, 'currentRegionId'),
      lastNodeId: JsonRead.optString(json, 'lastNodeId'),
      nodes: readMap('nodes', NodeProgress.fromJson),
      unlockedNodeIds: JsonRead.strings(json, 'unlocked').toSet(),
      words: readMap('words', WordStats.fromJson),
      battleCount: JsonRead.integer(json, 'battleCount', fallback: 0),
      battleWins: JsonRead.integer(json, 'battleWins', fallback: 0),
      battlesSinceWard: JsonRead.integer(json, 'battlesSinceWard', fallback: 0),
      tutorialFlags: JsonRead.strings(json, 'tutorials').toSet(),
      recentContentKeys: JsonRead.strings(json, 'recent'),
      settings: WordForgeSettings.fromJson(JsonRead.object(json, 'settings')),
      spells: JsonRead.strings(json, 'spells'),
    );
  }

  @override
  List<Object?> get props => [
        version,
        playerId,
        slotIndex,
        saveId,
        createdAtMs,
        lastPlayedAtMs,
        characterId,
        xp,
        upgrades.toJson(),
        buffs,
        currentRegionId,
        lastNodeId,
        nodes,
        unlockedNodeIds,
        words,
        battleCount,
        battleWins,
        battlesSinceWard,
        tutorialFlags,
        recentContentKeys,
        settings,
        spells,
      ];
}
