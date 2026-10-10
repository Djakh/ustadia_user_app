import 'domain/services/word_forge_audio.dart';

/// Every Word Forge asset path lives here — gameplay code never spells out a
/// path. Folders listed under "art" are reserved for professional assets; the
/// renderer falls back to procedural drawing until they exist.
abstract final class WordForgeAssets {
  static const root = 'assets/word_forge';

  // Content (data-driven; see assets/word_forge/content/README.md).
  static const words = '$root/content/words.json';
  static const runes = '$root/content/runes.json';
  static const incantations = '$root/content/incantations.json';
  static const enemies = '$root/content/enemies.json';
  static const battles = '$root/content/battles.json';
  static const regions = '$root/content/regions.json';
  static const combat = '$root/content/combat.json';

  // Art (reserved).
  static const backgrounds = '$root/backgrounds';
  static const characters = '$root/characters';
  static const enemySprites = '$root/enemies';
  static const effects = '$root/effects';
  static const ui = '$root/ui';
  static const icons = '$root/icons';

  /// Audio paths are relative to `assets/` because audioplayers' cache adds
  /// that prefix itself.
  static String sfx(WordForgeSfx sfx) => 'word_forge/audio/${_sfxFile[sfx]}.wav';

  static const Map<WordForgeSfx, String> _sfxFile = {
    WordForgeSfx.tap: 'tap',
    WordForgeSfx.cast: 'cast',
    WordForgeSfx.clash: 'clash',
    WordForgeSfx.shieldBreak: 'shield_break',
    WordForgeSfx.shieldReject: 'shield_reject',
    WordForgeSfx.runeComplete: 'rune_complete',
    WordForgeSfx.incantation: 'incantation',
    WordForgeSfx.fizzle: 'fizzle',
    WordForgeSfx.hit: 'hit',
    WordForgeSfx.combo: 'combo',
    WordForgeSfx.wordFlow: 'word_flow',
    WordForgeSfx.bossPhase: 'boss_phase',
    WordForgeSfx.victory: 'victory',
    WordForgeSfx.defeat: 'defeat',
    WordForgeSfx.reward: 'reward',
    WordForgeSfx.discover: 'discover',
    WordForgeSfx.turnChime: 'turn_chime',
    WordForgeSfx.enemyImpact: 'enemy_impact',
    WordForgeSfx.criticalWarning: 'critical_warning',
    WordForgeSfx.criticalSuccess: 'critical_success',
    WordForgeSfx.criticalHit: 'critical_hit',
    WordForgeSfx.specialReady: 'special_ready',
    WordForgeSfx.specialCast: 'special_cast',
    WordForgeSfx.shieldHit: 'shield_hit',
    WordForgeSfx.enemySpecial: 'enemy_special',
    WordForgeSfx.weakCast: 'weak_cast',
    WordForgeSfx.wardRaise: 'ward_raise',
    WordForgeSfx.bind: 'bind',
    WordForgeSfx.spellSelect: 'spell_select',
    WordForgeSfx.spellLearned: 'spell_learned',
    WordForgeSfx.impactSlash: 'impact_slash',
    WordForgeSfx.impactRock: 'impact_rock',
    WordForgeSfx.impactArcane: 'impact_arcane',
    WordForgeSfx.impactInk: 'impact_ink',
    WordForgeSfx.impactSpark: 'impact_spark',
    WordForgeSfx.impactSmash: 'impact_smash',
    WordForgeSfx.impactThorn: 'impact_thorn',
    WordForgeSfx.impactFrost: 'impact_frost',
    WordForgeSfx.poisonCast: 'poison_cast',
    WordForgeSfx.poisonTick: 'poison_tick',
    WordForgeSfx.reflect: 'reflect',
    WordForgeSfx.spellFizzle: 'spell_fizzle',
    WordForgeSfx.telegraphHeavy: 'telegraph_heavy',
    WordForgeSfx.telegraphArcane: 'telegraph_arcane',
    WordForgeSfx.telegraphSharp: 'telegraph_sharp',
  };

  /// Impact sound for an enemy's magic family (see `EnemyBehaviour.element`).
  static WordForgeSfx impactFor(String element) => switch (element) {
        'slash' || 'steel' => WordForgeSfx.impactSlash,
        'rock' => WordForgeSfx.impactRock,
        'ink' => WordForgeSfx.impactInk,
        'spark' || 'glint' => WordForgeSfx.impactSpark,
        'smash' => WordForgeSfx.impactSmash,
        'thorn' => WordForgeSfx.impactThorn,
        'frost' => WordForgeSfx.impactFrost,
        _ => WordForgeSfx.impactArcane,
      };

  /// Warning cue before an enemy Special: heavy things rumble, sharp things
  /// ring, magic hums.
  static WordForgeSfx telegraphFor(String element) => switch (element) {
        'rock' || 'smash' || 'thorn' => WordForgeSfx.telegraphHeavy,
        'slash' || 'steel' || 'spark' || 'glint' || 'frost' => WordForgeSfx.telegraphSharp,
        _ => WordForgeSfx.telegraphArcane,
      };
}
