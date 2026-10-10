import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/battle/battle_models.dart';
import '../../domain/content/region_definition.dart';
import '../../domain/content/word_forge_content.dart';
import '../../domain/progression/map_rules.dart';
import '../../domain/progression/player_level.dart';
import '../../domain/progression/upgrades.dart';
import '../../domain/repositories/word_forge_repositories.dart';
import '../../domain/sandbox/sandbox_progression.dart';
import '../../domain/save/word_forge_save.dart';
import '../../domain/services/word_forge_analytics.dart';
import '../../word_forge_module.dart';

enum WordForgeStatus { loading, ready, failure }

class WordForgeState extends Equatable {
  final WordForgeStatus status;
  final WordForgeContent? content;
  final List<SaveSlotState> slots;
  final int? lastSlot;

  /// The save being played, or null while on the start screen.
  final WordForgeSave? save;

  const WordForgeState({
    this.status = WordForgeStatus.loading,
    this.content,
    this.slots = const [],
    this.lastSlot,
    this.save,
  });

  bool get isReady => status == WordForgeStatus.ready && content != null;
  bool get isPlaying => isReady && save != null;
  bool get hasAnySave => slots.any((slot) => slot.save != null);

  SaveSlotState? get continueSlot {
    final withSaves = slots.where((slot) => slot.save != null).toList();
    if (withSaves.isEmpty) return null;
    final preferred = withSaves.where((slot) => slot.index == lastSlot);
    if (preferred.isNotEmpty) return preferred.first;
    withSaves.sort((a, b) => b.save!.lastPlayedAtMs.compareTo(a.save!.lastPlayedAtMs));
    return withSaves.first;
  }

  WordForgeState copyWith({
    WordForgeStatus? status,
    WordForgeContent? content,
    List<SaveSlotState>? slots,
    int? lastSlot,
    WordForgeSave? save,
    bool clearSave = false,
  }) =>
      WordForgeState(
        status: status ?? this.status,
        content: content ?? this.content,
        slots: slots ?? this.slots,
        lastSlot: lastSlot ?? this.lastSlot,
        save: clearSave ? null : (save ?? this.save),
      );

  @override
  List<Object?> get props => [status, content, slots, lastSlot, save];
}

/// Session state for the whole module: content, the three save slots and
/// the active save. Every progression change is persisted immediately (one
/// checkpoint per meaningful event) and stamped with `lastPlayedAtMs`.
class WordForgeCubit extends Cubit<WordForgeState> {
  final WordForgeDependencies dependencies;
  final String playerId;
  final int Function() _clock;
  final Random _random;

  WordForgeCubit({
    required this.dependencies,
    required this.playerId,
    int Function()? clock,
    Random? random,
  })  : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
        _random = random ?? Random.secure(),
        super(const WordForgeState());

  SandboxProgression get _progression => dependencies.progression;
  WordForgeAnalytics get _analytics => dependencies.analytics;
  WordForgeSaveRepository get _saves => dependencies.saveRepository;
  MapRules get mapRules => _progression.mapRules;

  Future<void> load() async {
    emit(state.copyWith(status: WordForgeStatus.loading));
    try {
      final results = await Future.wait<Object?>([
        dependencies.contentRepository.load(),
        _saves.listSlots(playerId),
        _saves.lastPlayedSlot(playerId),
      ]);
      final content = results[0] as WordForgeContent;
      if (content.regions.isEmpty) throw StateError('No playable regions');
      emit(WordForgeState(
        status: WordForgeStatus.ready,
        content: content,
        slots: results[1] as List<SaveSlotState>,
        lastSlot: results[2] as int?,
      ));
      _analytics.log(WordForgeEvents.opened, {
        'saves': state.slots.where((slot) => slot.save != null).length,
      });
    } on Object catch (error, stack) {
      debugPrint('[WordForge] load failed: $error\n$stack');
      emit(state.copyWith(status: WordForgeStatus.failure));
    }
  }

  // --- slots -----------------------------------------------------------------

  Future<void> refreshSlots() async {
    final slots = await _saves.listSlots(playerId);
    final last = await _saves.lastPlayedSlot(playerId);
    emit(state.copyWith(slots: slots, lastSlot: last));
  }

  /// Opens a slot for play. Returns false when it is empty or unreadable.
  Future<bool> openSlot(int slot) async {
    final save = await _saves.loadSlot(playerId, slot);
    if (save == null) return false;
    await _persist(save);
    _analytics.log(WordForgeEvents.saveLoaded, {'slot': slot, 'level': PlayerLevel.fromXp(save.xp).level});
    return true;
  }

  /// Creates a brand-new save in [slot] (overwriting it) for [characterId].
  Future<void> createNewGame(int slot, String characterId) async {
    final now = _clock();
    final save = WordForgeSave.fresh(
      playerId,
      slotIndex: slot,
      characterId: characterId,
      saveId: _newSaveId(),
      nowMs: now,
    );
    await _persist(save);
    _analytics.log(WordForgeEvents.newGame, {'slot': slot, 'character': characterId});
  }

  /// Saves created before characters existed pick one once.
  Future<void> chooseCharacter(String characterId) async {
    final save = state.save;
    if (save == null) return;
    await _persist(save.copyWith(characterId: characterId));
  }

  Future<void> closeSave() async {
    emit(state.copyWith(clearSave: true));
    await refreshSlots();
  }

  String _newSaveId() =>
      List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join();

  Future<void> _persist(WordForgeSave save) async {
    final stamped = save.copyWith(lastPlayedAtMs: _clock());
    final slots = [
      for (final slot in state.slots)
        if (slot.index == stamped.slotIndex) SaveSlotState(index: slot.index, save: stamped) else slot,
      if (!state.slots.any((slot) => slot.index == stamped.slotIndex)) SaveSlotState(index: stamped.slotIndex, save: stamped),
    ]..sort((a, b) => a.index.compareTo(b.index));
    emit(state.copyWith(save: stamped, slots: slots, lastSlot: stamped.slotIndex));
    try {
      await _saves.save(stamped);
    } on Object catch (error) {
      debugPrint('[WordForge] save failed: $error');
    }
  }

  /// Share of map nodes completed across all regions (for slot summaries).
  double completionOf(WordForgeSave save) {
    final content = state.content;
    if (content == null) return 0;
    final total = content.regions.fold<int>(0, (sum, region) => sum + region.nodes.length);
    if (total == 0) return 0;
    final done = content.regions.fold<int>(
        0, (sum, region) => sum + region.nodes.where((node) => save.isCompleted(node.id)).length);
    return done / total;
  }

  RegionDefinition? regionOf(WordForgeSave save) {
    final content = state.content;
    return content == null ? null : mapRules.currentRegion(content, save);
  }

  // --- gameplay --------------------------------------------------------------

  Future<void> selectRegion(RegionDefinition region) async {
    final save = state.save;
    if (save == null || save.currentRegionId == region.id) return;
    await _persist(save.copyWith(currentRegionId: region.id));
    _analytics.log(WordForgeEvents.regionStarted, {'region_id': region.id});
  }

  BattleSetup? setupFor(MapNodeDefinition node) {
    final content = state.content;
    final save = state.save;
    if (content == null || save == null) return null;
    return _progression.buildSetup(content: content, save: save, node: node);
  }

  void logNodeStarted(MapNodeDefinition node) {
    final region = state.content?.regionOfNode(node.id);
    _analytics.log(WordForgeEvents.nodeStarted, {
      'node_id': node.id,
      'node_type': node.type.name,
      if (region != null) 'region_id': region.id,
    });
    if (node.type == MapNodeType.boss) {
      _analytics.log(WordForgeEvents.bossStarted, {'node_id': node.id, if (region != null) 'region_id': region.id});
    }
  }

  /// Results for a practice fight (debug QA arena): computed like a real
  /// battle but never saved.
  BattleOutcomeSummary? previewBattle(MapNodeDefinition node, BattleResult result) {
    final content = state.content;
    final save = state.save;
    if (content == null || save == null) return null;
    return _progression.applyBattle(content: content, save: save, node: node, result: result).summary;
  }

  Future<BattleOutcomeSummary?> completeBattle(MapNodeDefinition node, BattleResult result) async {
    final content = state.content;
    final save = state.save;
    if (content == null || save == null) return null;
    final applied = _progression.applyBattle(content: content, save: save, node: node, result: result);
    await _persist(applied.save);

    final summary = applied.summary;
    final region = content.regionOfNode(node.id);
    final params = <String, Object>{
      'node_id': node.id,
      'node_type': node.type.name,
      if (region != null) 'region_id': region.id,
      'stars': summary.stars,
      'accuracy': (result.accuracy * 100).round(),
      'duration_s': result.durationSeconds.round(),
      'specials': result.specialsUsed,
      'criticals': result.criticalsLanded,
    };
    _analytics.log(
        result.abandoned
            ? WordForgeEvents.battleAbandoned
            : (result.victory ? WordForgeEvents.battleWon : WordForgeEvents.battleLost),
        params);
    if (result.victory) {
      _analytics.log(WordForgeEvents.nodeCompleted, params);
      if (node.type == MapNodeType.boss) _analytics.log(WordForgeEvents.bossCompleted, params);
    }
    for (final wordId in summary.discoveredWordIds.take(20)) {
      _analytics.log(WordForgeEvents.wordDiscovered, {'word_id': wordId});
    }
    for (final change in summary.masteryChanges.take(20)) {
      _analytics.log(WordForgeEvents.wordMasteryChanged,
          {'word_id': change.wordId, 'from': change.from, 'to': change.to});
    }
    return summary;
  }

  Future<NodeClaimSummary?> claimNode(MapNodeDefinition node) async {
    final content = state.content;
    final save = state.save;
    if (content == null || save == null) return null;
    final applied = _progression.claimNode(content: content, save: save, node: node);
    if (!applied.summary.alreadyClaimed) {
      await _persist(applied.save);
      _analytics.log(WordForgeEvents.nodeCompleted, {'node_id': node.id, 'node_type': node.type.name});
    }
    return applied.summary;
  }

  /// Fixes the mystery outcome before the player sees it.
  Future<void> revealMystery(MapNodeDefinition node) async {
    final save = state.save;
    if (save == null || save.progressOf(node.id).mysteryOutcome != null) return;
    await _persist(_progression.revealMystery(save, node));
  }

  Future<bool> purchaseUpgrade(UpgradeType type) async {
    final save = state.save;
    if (save == null) return false;
    final next = _progression.purchaseUpgrade(save, type);
    if (next == null) return false;
    await _persist(next);
    _analytics.log(WordForgeEvents.upgradePurchased, {'upgrade': type.name, 'level': next.upgrades[type]});
    return true;
  }

  /// Spends a skill point on a witnessed Special.
  Future<bool> learnSpell(String spellId) async {
    final save = state.save;
    final content = state.content;
    if (save == null || content == null) return false;
    final next = _progression.learnSpell(content, save, spellId);
    if (next == null) return false;
    await _persist(next);
    _analytics.log(WordForgeEvents.spellLearned, {'spell': spellId, 'spells': next.spells.length});
    return true;
  }

  Future<void> setMuted(bool muted) async {
    final save = state.save;
    if (save == null) return;
    await _persist(save.copyWith(settings: save.settings.copyWith(muted: muted)));
  }

  Future<void> setReducedEffects(bool reduced) async {
    final save = state.save;
    if (save == null) return;
    await _persist(save.copyWith(settings: save.settings.copyWith(reducedEffects: reduced)));
  }

  void logSpellbookOpened() => _analytics.log(WordForgeEvents.spellbookOpened,
      {'words_discovered': state.save?.discoveredWordCount ?? 0});
}
