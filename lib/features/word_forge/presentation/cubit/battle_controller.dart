import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/battle/battle_engine.dart';
import '../../domain/battle/battle_events.dart';
import '../../domain/battle/battle_models.dart';
import '../../domain/battle/combat_config.dart';
import '../../domain/content/word_forge_content.dart';
import '../../domain/language/language_challenge.dart';
import '../../domain/progression/buffs.dart';
import '../../domain/services/word_forge_analytics.dart';
import '../../domain/services/word_forge_audio.dart';
import '../../word_forge_assets.dart';

enum BattleNoticeKind { discovery, info, success, warning }

/// Short, non-blocking message shown over the scene.
class BattleNotice {
  final int id;
  final BattleNoticeKind kind;
  final String title;
  final String? subtitle;
  final String? word;

  const BattleNotice({required this.id, required this.kind, required this.title, this.subtitle, this.word});
}

/// Presentation adapter around [BattleEngine]: exposes snapshots to widgets,
/// forwards input, and turns events into sound, analytics and notices.
/// It holds no combat rules.
class BattleController extends Cubit<BattleSnapshot> {
  final BattleEngine engine;
  final WordForgeContent content;
  final WordForgeAudio audio;
  final WordForgeAnalytics analytics;
  final Map<String, Object> analyticsContext;
  final Set<String> _known;

  /// Localised strings supplied by the page (keeps this class testable).
  final String Function(String key) describe;

  final ValueNotifier<double> timerFraction = ValueNotifier(0);
  final ValueNotifier<BattleNotice?> notice = ValueNotifier(null);
  late final StreamSubscription<BattleSnapshot> _snapshotSubscription;
  late final StreamSubscription<BattleEvent> _eventSubscription;
  int _noticeId = 0;

  BattleController({
    required this.engine,
    required this.content,
    required this.audio,
    required this.analytics,
    required this.analyticsContext,
    required Set<String> knownWordIds,
    required this.describe,
  })  : _known = {...knownWordIds},
        super(engine.snapshot) {
    _snapshotSubscription = engine.snapshots.listen((snapshot) {
      if (!isClosed) emit(snapshot);
    });
    _eventSubscription = engine.events.listen(_onEvent);
  }

  Stream<BattleEvent> get events => engine.events;

  void start() => engine.start();

  void tick(double dt) {
    engine.tick(dt);
    final fraction = engine.timerFraction;
    if ((timerFraction.value - fraction).abs() > 0.002) timerFraction.value = fraction;
  }

  void pause() {
    engine.pause();
    audio.pauseAll();
  }

  void resume() {
    engine.resume();
    audio.resumeAll();
  }

  // --- input -----------------------------------------------------------------

  void submitChoice(String optionId) {
    if (!state.acceptsInput) return;
    audio.play(WordForgeSfx.tap, volume: 0.6);
    engine.submitChoice(optionId);
  }

  void placeToken(String optionId) {
    if (!state.acceptsInput) return;
    audio.play(WordForgeSfx.tap, volume: 0.5);
    engine.placeToken(optionId);
  }

  void removeToken(String optionId) {
    audio.play(WordForgeSfx.tap, volume: 0.4);
    engine.removeToken(optionId);
  }

  void undoToken() {
    final placed = state.placedOptionIds;
    if (placed.isNotEmpty) removeToken(placed.last);
  }

  void clearTokens() => engine.clearTokens();

  void selectMatch(String optionId) {
    if (!state.acceptsInput) return;
    audio.play(WordForgeSfx.tap, volume: 0.5);
    engine.selectMatch(optionId);
  }

  void selectTarget(int index) {
    if (engine.selectTarget(index)) audio.play(WordForgeSfx.tap, volume: 0.6);
  }

  bool get canActivateSpecial => engine.canActivateSpecial;

  /// Casts [spellId] (default: the starter spell).
  void activateSpecial([String? spellId]) {
    if (engine.activateSpecial(spellId)) {
      audio.play(WordForgeSfx.spellSelect, volume: 0.8);
      analytics.log(WordForgeEvents.specialUsed, {...analyticsContext, 'spell': spellId ?? engine.knownSpells.first});
    }
  }

  bool canUseBuff(BuffType buff) => engine.canUseBuff(buff);

  void useBuff(BuffType buff) {
    final type = state.challenge?.type;
    if (engine.useBuff(buff)) {
      analytics.log(WordForgeEvents.buffUsed, {
        ...analyticsContext,
        'buff': buff.name,
        if (type != null) 'challenge_type': type.name,
        if (state.moveKind != null) 'move_kind': state.moveKind!.name,
      });
    }
  }

  BattleResult abandon() => engine.abandon();

  // --- feedback --------------------------------------------------------------

  void _show(BattleNoticeKind kind, String title, {String? subtitle, String? word}) {
    notice.value = BattleNotice(id: _noticeId++, kind: kind, title: title, subtitle: subtitle, word: word);
  }

  void _onEvent(BattleEvent event) {
    switch (event) {
      case TurnStarted(:final turn, :final kind, :final move, :final actor):
        // Enemy Specials get a warning cue in the voice of their magic family.
        final element = actor >= 0 && actor < engine.setup.enemies.length ? engine.setup.behaviourOf(actor).element : 'arcane';
        audio.play(switch ((turn, kind)) {
          (BattleTurn.player, MoveKind.normal) => WordForgeSfx.turnChime,
          (BattleTurn.player, MoveKind.critical) => WordForgeSfx.combo,
          (BattleTurn.player, MoveKind.special) => WordForgeSfx.specialCast,
          (BattleTurn.enemy, MoveKind.normal) => WordForgeSfx.cast,
          (BattleTurn.enemy, MoveKind.critical) => WordForgeSfx.criticalWarning,
          (BattleTurn.enemy, MoveKind.special) => WordForgeAssets.telegraphFor(element),
        }, volume: kind == MoveKind.normal ? 0.45 : 0.9);
        if (turn == BattleTurn.enemy && kind == MoveKind.special) audio.play(WordForgeSfx.enemySpecial, volume: 0.5);
        if (turn == BattleTurn.enemy && kind == MoveKind.special && move != null) {
          analytics.log(WordForgeEvents.enemySpecial, {...analyticsContext, 'move': move.id});
        }
      case TurnSkipped(:final reason):
        audio.play(reason == 'locked' ? WordForgeSfx.fizzle : WordForgeSfx.reward, volume: 0.7);
        _show(reason == 'locked' ? BattleNoticeKind.warning : BattleNoticeKind.success,
            describe(reason == 'locked' ? 'locked' : 'staggered'));
      case CriticalOpportunity(:final move):
        analytics.log(WordForgeEvents.criticalTriggered, {...analyticsContext, 'game': move.id});
      case SpecialReady():
        audio.play(WordForgeSfx.specialReady);
        _show(BattleNoticeKind.success, describe('specialReady'));
      case SpecialActivated():
        break;
      case TaskPresented():
        break;
      case TaskResolved(:final challenge, :final success, :final record):
        audio.play(success ? WordForgeSfx.runeComplete : WordForgeSfx.fizzle, volume: 0.55);
        _logAnswer(challenge, record);
        _announceDiscovery(challenge);
      case ActionResolved(:final outcome, :final lastChallenge):
        _playResolution(outcome);
        if (lastChallenge != null && outcome.total > 0 && engine.records.isNotEmpty) {
          _logAnswer(lastChallenge, engine.records.last);
          _announceDiscovery(lastChallenge);
        }
      case EnemyDefeated():
        audio.play(WordForgeSfx.criticalHit, volume: 0.6);
      case TargetChanged():
        break;
      case MatchMade():
        audio.play(WordForgeSfx.runeComplete, volume: 0.45);
      case MatchMissed():
        audio.play(WordForgeSfx.shieldReject, volume: 0.5);
      case AnswerForgiven():
        audio.play(WordForgeSfx.reward, volume: 0.6);
        _show(BattleNoticeKind.success, describe('secondChance'));
      case IncantationUnstable():
        audio.play(WordForgeSfx.fizzle, volume: 0.6);
        _show(BattleNoticeKind.warning, describe('unstable'));
      case WordEaten():
        audio.play(WordForgeSfx.hit, volume: 0.5);
        _show(BattleNoticeKind.warning, describe('wordEaten'));
      case TimerRanOut():
        _show(BattleNoticeKind.warning, describe('timeUp'));
      case BuffUsed():
        audio.play(WordForgeSfx.reward, volume: 0.5);
      case WardTriggered():
        audio.play(WordForgeSfx.shieldBreak, volume: 0.6);
        _show(BattleNoticeKind.success, describe('ward'));
      case WardRaised(:final charges):
        audio.play(WordForgeSfx.wardRaise, volume: 0.8);
        if (charges > 1) _show(BattleNoticeKind.success, describe('wardRaised'));
      case PoisonApplied(:final target):
        audio.play(WordForgeSfx.poisonCast, volume: 0.9);
        _show(target < 0 ? BattleNoticeKind.warning : BattleNoticeKind.success,
            describe(target < 0 ? 'poisoned' : 'enemyPoisoned'));
      case PoisonTick(:final damage):
        if (damage > 0) audio.play(WordForgeSfx.poisonTick, volume: 0.7);
      case WordFlowChanged(:final active):
        if (active) {
          audio.play(WordForgeSfx.wordFlow);
          _show(BattleNoticeKind.success, describe('flow'));
        }
      case StageChanged():
        audio.play(WordForgeSfx.bossPhase);
      case BattleStarted():
        break;
      case BattleEnded(:final result):
        if (!result.abandoned) audio.play(result.victory ? WordForgeSfx.victory : WordForgeSfx.defeat);
    }
  }

  /// Audio hierarchy: Normal = one impact · Critical = heavier impact plus a
  /// cue · Special = cast build-up (on activation) plus a major impact.
  /// Enemy hits use the sound of their magic family.
  void _playResolution(ActionOutcome outcome) {
    final element = outcome.actor >= 0 && outcome.actor < engine.setup.enemies.length
        ? engine.setup.behaviourOf(outcome.actor).element
        : 'arcane';
    final sfx = switch ((outcome.turn, outcome.kind)) {
      (BattleTurn.player, MoveKind.normal) => outcome.weakCast
          ? (outcome.shieldCracked ? WordForgeSfx.shieldReject : WordForgeSfx.weakCast)
          : (outcome.shieldShattered
              ? WordForgeSfx.shieldBreak
              : (outcome.shieldCracked ? WordForgeSfx.shieldHit : WordForgeSfx.enemyImpact)),
      (BattleTurn.player, MoveKind.critical) => outcome.success ? WordForgeSfx.criticalHit : WordForgeSfx.fizzle,
      (BattleTurn.player, MoveKind.special) => outcome.spellFizzled
          ? WordForgeSfx.spellFizzle
          : switch (outcome.effect) {
              MoveEffect.ward => WordForgeSfx.wardRaise,
              MoveEffect.bind => outcome.staggerApplied ? WordForgeSfx.bind : WordForgeSfx.incantation,
              MoveEffect.poison => WordForgeSfx.poisonCast,
              _ => WordForgeSfx.incantation,
            },
      (BattleTurn.enemy, MoveKind.normal) => outcome.success ? WordForgeSfx.clash : WordForgeAssets.impactFor(element),
      (BattleTurn.enemy, MoveKind.critical) =>
        outcome.success ? WordForgeSfx.criticalSuccess : WordForgeAssets.impactFor(element),
      (BattleTurn.enemy, MoveKind.special) => outcome.shieldRaised
          ? WordForgeSfx.shieldReject
          : (outcome.success ? WordForgeSfx.criticalSuccess : WordForgeAssets.impactFor(element)),
    };
    audio.play(sfx);
    if (outcome.turn == BattleTurn.enemy && !outcome.success && outcome.kind != MoveKind.normal && !outcome.shieldRaised) {
      audio.play(WordForgeSfx.criticalHit, volume: 0.7);
    }
    if (outcome.weakCast) _show(BattleNoticeKind.warning, describe(outcome.damageToPlayer > 0 ? 'weakCastCounter' : 'weakCast'));
    if (outcome.weakCast && outcome.damageToPlayer > 0) audio.play(WordForgeSfx.hit, volume: 0.6);
    if (outcome.staggerApplied) _show(BattleNoticeKind.success, describe('bound'));
    if (outcome.spellFizzled) _show(BattleNoticeKind.warning, describe('fizzled'));
    if (outcome.reflected > 0) {
      audio.play(WordForgeSfx.reflect, volume: 0.8);
      _show(BattleNoticeKind.success, describe('reflected'));
    }
    if (outcome.success && state.combo >= 3 && outcome.turn == BattleTurn.player) {
      audio.play(WordForgeSfx.combo, volume: 0.5);
    }
    if (outcome.success && outcome.turn == BattleTurn.enemy && outcome.kind != MoveKind.normal && !outcome.shieldRaised) {
      _show(BattleNoticeKind.success, describe('parried'));
    }
  }

  void _logAnswer(LanguageChallenge challenge, ChallengeRecord record) {
    analytics.log(WordForgeEvents.challengeAnswered, {
      ...analyticsContext,
      'challenge_type': challenge.type.name,
      'turn': record.turn.name,
      'move_kind': record.kind.name,
      'degree': challenge.degree,
      'result': record.success ? (record.firstTry ? 'correct' : 'correct_retry') : (record.timedOut ? 'timeout' : 'wrong'),
      'response_ms': (record.responseSeconds * 1000).round(),
    });
  }

  void _announceDiscovery(LanguageChallenge challenge) {
    final wordId = challenge.focusWordId ?? (challenge.wordIds.isEmpty ? null : challenge.wordIds.first);
    if (wordId == null || _known.contains(wordId)) return;
    final word = content.words[wordId];
    if (word == null) return;
    _known.add(wordId);
    audio.play(WordForgeSfx.discover, volume: 0.7);
    _show(BattleNoticeKind.discovery, describe('newWord'), word: word.text, subtitle: word.definition);
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription.cancel();
    await _eventSubscription.cancel();
    timerFraction.dispose();
    notice.dispose();
    engine.dispose();
    return super.close();
  }
}
