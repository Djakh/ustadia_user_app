import '../language/language_challenge.dart';
import '../progression/buffs.dart';
import 'battle_models.dart';
import 'combat_config.dart';

/// Discrete things that happened in a battle. The renderer, audio and
/// analytics subscribe to these; none of them can change battle state.
sealed class BattleEvent {
  const BattleEvent();
}

class BattleStarted extends BattleEvent {
  final BattleSnapshot snapshot;
  const BattleStarted(this.snapshot);
}

/// "YOUR TURN" / "ENEMY TURN", with the kind of move about to happen.
/// Enemy Criticals and Specials arrive here first so they can be telegraphed.
class TurnStarted extends BattleEvent {
  final BattleTurn turn;
  final MoveKind kind;
  final MoveDefinition? move;
  final int actor;
  final int target;
  const TurnStarted({required this.turn, required this.kind, this.move, required this.actor, required this.target});
}

class TurnSkipped extends BattleEvent {
  final BattleTurn turn;

  /// `locked` (player hit by Rune Lock) or `staggered` (enemy shield broken).
  final String reason;
  final int actor;
  const TurnSkipped({required this.turn, required this.reason, this.actor = -1});
}

class CriticalOpportunity extends BattleEvent {
  final MoveDefinition move;
  const CriticalOpportunity(this.move);
}

class SpecialReady extends BattleEvent {
  const SpecialReady();
}

class SpecialActivated extends BattleEvent {
  final MoveDefinition move;
  const SpecialActivated(this.move);
}

class TaskPresented extends BattleEvent {
  final BattleTurn turn;
  final MoveKind kind;
  final LanguageChallenge challenge;
  final int index;
  final int count;
  const TaskPresented({
    required this.turn,
    required this.kind,
    required this.challenge,
    required this.index,
    required this.count,
  });
}

/// One task of a multi-task move was answered.
class TaskResolved extends BattleEvent {
  final LanguageChallenge challenge;
  final bool success;
  final ChallengeRecord record;
  final int index;
  final int count;
  const TaskResolved({
    required this.challenge,
    required this.success,
    required this.record,
    required this.index,
    required this.count,
  });
}

class ActionResolved extends BattleEvent {
  final ActionOutcome outcome;
  final LanguageChallenge? lastChallenge;
  const ActionResolved(this.outcome, this.lastChallenge);
}

class EnemyDefeated extends BattleEvent {
  final int index;
  const EnemyDefeated(this.index);
}

class TargetChanged extends BattleEvent {
  final int index;
  const TargetChanged(this.index);
}

class MatchMade extends BattleEvent {
  final String first;
  final String second;
  const MatchMade(this.first, this.second);
}

class MatchMissed extends BattleEvent {
  const MatchMissed();
}

/// A wrong answer was absorbed by Second Chance; the task stays open.
class AnswerForgiven extends BattleEvent {
  final String optionId;
  const AnswerForgiven(this.optionId);
}

/// A wrong incantation that can still be fixed; correct words stay in place.
class IncantationUnstable extends BattleEvent {
  final int keptTokens;
  const IncantationUnstable(this.keptTokens);
}

/// A Word Eater swallowed a placed word and spat it back into the pool.
class WordEaten extends BattleEvent {
  final String optionId;
  const WordEaten(this.optionId);
}

class TimerRanOut extends BattleEvent {
  const TimerRanOut();
}

class BuffUsed extends BattleEvent {
  final BuffType buff;
  const BuffUsed(this.buff);
}

class WardTriggered extends BattleEvent {
  const WardTriggered();
}

/// A ward now protects the player (Guardian Ward spell or Ward buff).
class WardRaised extends BattleEvent {
  final int charges;
  const WardRaised(this.charges);
}

/// Poison started ticking on an enemy ([target] >= 0) or on the player (-1).
class PoisonApplied extends BattleEvent {
  final int target;
  final int ticks;
  const PoisonApplied({required this.target, required this.ticks});
}

/// One poison tick landed on an enemy ([target] >= 0) or on the player (-1).
class PoisonTick extends BattleEvent {
  final int target;
  final int damage;
  final int ticksLeft;
  const PoisonTick({required this.target, required this.damage, required this.ticksLeft});
}

class WordFlowChanged extends BattleEvent {
  final bool active;
  const WordFlowChanged({required this.active});
}

class StageChanged extends BattleEvent {
  final int stageIndex;
  final String? name;
  final bool enraged;
  const StageChanged({required this.stageIndex, this.name, required this.enraged});
}

class BattleEnded extends BattleEvent {
  final BattleResult result;
  const BattleEnded(this.result);
}
