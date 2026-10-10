import 'package:equatable/equatable.dart';

/// Silent support after repeated failure. The player is never told the game
/// got easier; they simply get a little more room to succeed.
class BattleAssist extends Equatable {
  final double timeMultiplier;
  final int freeHints;
  final bool reducedOptions;

  /// Start the battle with a one-hit ward armed.
  final bool freeWard;

  const BattleAssist({this.timeMultiplier = 1, this.freeHints = 0, this.reducedOptions = false, this.freeWard = false});

  static const none = BattleAssist();

  @override
  List<Object?> get props => [timeMultiplier, freeHints, reducedOptions, freeWard];
}

/// Maps consecutive losses on a node to an assist level:
/// 1st try normal · 2nd more time · 3rd a free hint · 4th+ one option fewer
/// and a free ward.
class AssistPolicy {
  const AssistPolicy();

  BattleAssist forFailures(int consecutiveFailures) {
    if (consecutiveFailures <= 0) return BattleAssist.none;
    if (consecutiveFailures == 1) return const BattleAssist(timeMultiplier: 1.25);
    if (consecutiveFailures == 2) return const BattleAssist(timeMultiplier: 1.35, freeHints: 1);
    return const BattleAssist(timeMultiplier: 1.5, freeHints: 2, reducedOptions: true, freeWard: true);
  }
}
