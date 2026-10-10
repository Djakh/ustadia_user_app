import '../battle/combat_config.dart';
import '../language/text_normalizer.dart';
import 'battle_definition.dart';
import 'enemy_definition.dart';
import 'region_definition.dart';
import 'sentence_content.dart';
import 'word_entry.dart';

enum ContentIssueSeverity { warning, error }

/// A problem found while loading or validating content. Errors cause the item
/// to be dropped; warnings are informational (shown in debug builds).
class ContentIssue {
  final ContentIssueSeverity severity;
  final String source;
  final String message;

  const ContentIssue.error(this.source, this.message) : severity = ContentIssueSeverity.error;
  const ContentIssue.warning(this.source, this.message) : severity = ContentIssueSeverity.warning;

  bool get isError => severity == ContentIssueSeverity.error;

  @override
  String toString() => '[${severity.name}] $source: $message';
}

/// Immutable, validated catalog of everything Word Forge can show.
class WordForgeContent {
  final Map<String, WordEntry> words;
  final List<RuneTemplate> runes;
  final List<IncantationEntry> incantations;
  final Map<String, EnemyDefinition> enemies;
  final Map<String, BattleDefinition> battles;
  final List<RegionDefinition> regions;
  final CombatConfig combat;
  final List<ContentIssue> issues;

  WordForgeContent({
    required this.words,
    required this.runes,
    required this.incantations,
    required this.enemies,
    required this.battles,
    required List<RegionDefinition> regions,
    this.combat = const CombatConfig(),
    this.issues = const [],
  }) : regions = List.unmodifiable([...regions]..sort((a, b) => a.order.compareTo(b.order)));

  late final Map<String, WordEntry> _wordsByText = {
    for (final word in words.values) word.normalized: word,
  };

  late final Map<String, RegionDefinition> _regionByNodeId = {
    for (final region in regions)
      for (final node in region.nodes) node.id: region,
  };

  late final List<WordEntry> wordList = words.values.toList()
    ..sort((a, b) => a.degree != b.degree ? a.degree.compareTo(b.degree) : a.text.compareTo(b.text));

  WordEntry? wordByText(String text) => _wordsByText[TextNormalizer.normalize(text)];

  RegionDefinition? region(String id) {
    for (final region in regions) {
      if (region.id == id) return region;
    }
    return null;
  }

  RegionDefinition? regionOfNode(String nodeId) => _regionByNodeId[nodeId];

  MapNodeDefinition? node(String nodeId) => _regionByNodeId[nodeId]?.node(nodeId);

  List<ContentIssue> get errors => issues.where((issue) => issue.isError).toList();
}
