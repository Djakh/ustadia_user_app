/// Sound effect categories. Each maps to one asset in `WordForgeAssets.sfx`.
enum WordForgeSfx {
  tap,
  cast,
  clash,
  shieldBreak,
  shieldReject,
  runeComplete,
  incantation,
  fizzle,
  hit,
  combo,
  wordFlow,
  bossPhase,
  victory,
  defeat,
  reward,
  discover,
  turnChime,
  enemyImpact,
  criticalWarning,
  criticalSuccess,
  criticalHit,
  specialReady,
  specialCast,
  shieldHit,
  enemySpecial,
  weakCast,
  wardRaise,
  bind,
  spellSelect,
  spellLearned,
  impactSlash,
  impactRock,
  impactArcane,
  impactInk,
  impactSpark,
  impactSmash,
  impactThorn,
  impactFrost,
  poisonCast,
  poisonTick,
  reflect,
  spellFizzle,
  telegraphHeavy,
  telegraphArcane,
  telegraphSharp,
}

/// Audio port so gameplay never depends on a specific audio package.
abstract class WordForgeAudio {
  Future<void> preload();

  void play(WordForgeSfx sfx, {double volume = 1});

  bool get muted;
  set muted(bool value);

  /// Called when the app goes to the background.
  void pauseAll();

  void resumeAll();

  Future<void> dispose();
}

class SilentWordForgeAudio implements WordForgeAudio {
  @override
  bool muted = true;

  @override
  Future<void> preload() async {}

  @override
  void play(WordForgeSfx sfx, {double volume = 1}) {}

  @override
  void pauseAll() {}

  @override
  void resumeAll() {}

  @override
  Future<void> dispose() async {}
}
