import '../content/region_definition.dart';
import '../content/word_forge_content.dart';
import '../save/word_forge_save.dart';

enum NodeState { locked, available, completed }

/// Unlock rules, derived from completed nodes plus any node that was ever
/// unlocked. Deriving (instead of trusting a stored list only) keeps saves
/// valid when regions or nodes are added in later versions.
class MapRules {
  const MapRules();

  bool isRegionUnlocked(WordForgeContent content, WordForgeSave save, RegionDefinition region) {
    final index = content.regions.indexOf(region);
    if (index <= 0) return true;
    if (region.nodes.any((node) => save.isCompleted(node.id))) return true;
    final previous = content.regions[index - 1];
    return save.isCompleted(previous.bossNodeId);
  }

  bool isRegionCompleted(WordForgeSave save, RegionDefinition region) =>
      save.isCompleted(region.bossNodeId);

  NodeState nodeState(
      WordForgeContent content, WordForgeSave save, RegionDefinition region, MapNodeDefinition node) {
    if (save.isCompleted(node.id)) return NodeState.completed;
    if (!isRegionUnlocked(content, save, region)) return NodeState.locked;
    if (node.id == region.startNodeId) return NodeState.available;
    if (save.unlockedNodeIds.contains(node.id)) return NodeState.available;
    final predecessors = region.predecessors[node.id] ?? const [];
    return predecessors.any(save.isCompleted) ? NodeState.available : NodeState.locked;
  }

  /// Nodes that become reachable once [nodeId] is completed.
  List<String> unlockedBy(RegionDefinition region, String nodeId) =>
      region.node(nodeId)?.next ?? const [];

  /// The node the map should focus on: the lowest available main-path node,
  /// otherwise any available node, otherwise the boss.
  MapNodeDefinition focusNode(WordForgeContent content, WordForgeSave save, RegionDefinition region) {
    final available = region.nodes
        .where((node) => nodeState(content, save, region, node) == NodeState.available)
        .toList()
      ..sort((a, b) => a.row.compareTo(b.row));
    final main = available.where((node) => !node.optional);
    if (main.isNotEmpty) return main.first;
    if (available.isNotEmpty) return available.first;
    return region.node(region.bossNodeId) ?? region.nodes.first;
  }

  /// The furthest unlocked region (where "Continue" should take the player).
  RegionDefinition currentRegion(WordForgeContent content, WordForgeSave save) {
    final preferred = save.currentRegionId == null ? null : content.region(save.currentRegionId!);
    if (preferred != null && isRegionUnlocked(content, save, preferred)) return preferred;
    return content.regions.lastWhere((region) => isRegionUnlocked(content, save, region),
        orElse: () => content.regions.first);
  }

  ({int completed, int total}) regionProgress(WordForgeSave save, RegionDefinition region) => (
        completed: region.nodes.where((node) => save.isCompleted(node.id)).length,
        total: region.nodes.length,
      );
}
