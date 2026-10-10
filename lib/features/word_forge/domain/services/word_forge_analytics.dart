/// Analytics port. The host app plugs in its own implementation (Firebase in
/// Ustadia); Word Forge only reports coarse, non-sensitive gameplay events.
abstract class WordForgeAnalytics {
  void log(String event, [Map<String, Object> parameters = const {}]);
}

class NoopWordForgeAnalytics implements WordForgeAnalytics {
  const NoopWordForgeAnalytics();

  @override
  void log(String event, [Map<String, Object> parameters = const {}]) {}
}

/// Event names in one place so dashboards stay consistent.
abstract final class WordForgeEvents {
  static const opened = 'word_forge_opened';
  static const regionStarted = 'sandbox_region_started';
  static const nodeStarted = 'sandbox_node_started';
  static const nodeCompleted = 'sandbox_node_completed';
  static const battleWon = 'battle_won';
  static const battleLost = 'battle_lost';
  static const battleAbandoned = 'battle_abandoned';
  static const bossStarted = 'boss_started';
  static const bossCompleted = 'boss_completed';
  static const challengeAnswered = 'challenge_answered';
  static const buffUsed = 'buff_used';
  static const wordDiscovered = 'word_discovered';
  static const wordMasteryChanged = 'word_mastery_changed';
  static const upgradePurchased = 'upgrade_purchased';
  static const spellbookOpened = 'spellbook_opened';
  static const newGame = 'word_forge_new_game';
  static const saveLoaded = 'word_forge_save_loaded';
  static const criticalTriggered = 'critical_triggered';
  static const specialUsed = 'special_used';
  static const spellLearned = 'spell_learned';
  static const enemySpecial = 'enemy_special';
}
