import 'package:equatable/equatable.dart';

import '../progression/buffs.dart';
import 'difficulty.dart';
import 'json_utils.dart';

enum MapNodeType {
  battle,
  elite,
  challenge,
  bonus,
  recovery,
  miniBoss,
  boss,
  mystery;

  /// Node types resolved by fighting (mystery may resolve either way).
  bool get isCombat => switch (this) {
        MapNodeType.bonus || MapNodeType.recovery || MapNodeType.mystery => false,
        _ => true,
      };

  static MapNodeType parse(Object? raw) =>
      MapNodeType.values.firstWhere((value) => value.name == raw, orElse: () => MapNodeType.battle);
}

enum MysteryOutcomeKind { treasure, battle }

class MysteryOutcome extends Equatable {
  final MysteryOutcomeKind kind;
  final Map<BuffType, int> buffs;
  final String? battleId;

  const MysteryOutcome({required this.kind, this.buffs = const {}, this.battleId});

  factory MysteryOutcome.fromJson(Map<String, dynamic> json) {
    final isBattle = json['kind'] == 'battle';
    return MysteryOutcome(
      kind: isBattle ? MysteryOutcomeKind.battle : MysteryOutcomeKind.treasure,
      buffs: BuffType.parseMap(json['buffs']),
      battleId: isBattle ? JsonRead.string(json, 'battleId') : null,
    );
  }

  @override
  List<Object?> get props => [kind, buffs, battleId];
}

class MapNodeDefinition extends Equatable {
  final String id;
  final MapNodeType type;
  final String title;
  final String? battleId;
  final List<String> next;
  final bool optional;

  /// Vertical position on the map (0 = start, grows towards the boss).
  final double row;

  /// Horizontal offset from -1 (left) to 1 (right).
  final double lane;
  final Map<BuffType, int> rewards;
  final List<MysteryOutcome> outcomes;

  /// Special spell (move id) learned when this node is first cleared.
  final String? teaches;

  const MapNodeDefinition({
    required this.id,
    required this.type,
    required this.title,
    this.battleId,
    this.next = const [],
    this.optional = false,
    required this.row,
    required this.lane,
    this.rewards = const {},
    this.outcomes = const [],
    this.teaches,
  });

  factory MapNodeDefinition.fromJson(Map<String, dynamic> json) => MapNodeDefinition(
        id: JsonRead.string(json, 'id'),
        type: MapNodeType.parse(json['type']),
        title: JsonRead.string(json, 'title'),
        battleId: JsonRead.optString(json, 'battleId'),
        next: JsonRead.strings(json, 'next'),
        optional: JsonRead.boolean(json, 'optional'),
        row: JsonRead.number(json, 'row', fallback: 0),
        lane: JsonRead.number(json, 'lane', fallback: 0).clamp(-1.0, 1.0),
        rewards: BuffType.parseMap(json['rewards']),
        outcomes: JsonRead.objects(json, 'outcomes').map(MysteryOutcome.fromJson).toList(),
        teaches: JsonRead.optString(json, 'teaches'),
      );

  @override
  List<Object?> get props => [id];
}

/// Visual theme keys understood by the renderer. Unknown themes fall back to
/// [RegionTheme.road], so new regions can ship before bespoke art exists.
enum RegionTheme {
  road,
  forest,
  ruins;

  static RegionTheme parse(Object? raw) =>
      RegionTheme.values.firstWhere((value) => value.name == raw, orElse: () => RegionTheme.road);
}

class RegionDefinition extends Equatable {
  final String id;
  final int order;
  final String name;
  final String subtitle;
  final RegionTheme theme;
  final DegreeRange degrees;
  final String startNodeId;
  final String bossNodeId;
  final List<MapNodeDefinition> nodes;

  RegionDefinition({
    required this.id,
    required this.order,
    required this.name,
    required this.subtitle,
    required this.theme,
    required this.degrees,
    required this.startNodeId,
    required this.bossNodeId,
    required this.nodes,
  });

  late final Map<String, MapNodeDefinition> nodesById = {for (final node in nodes) node.id: node};

  /// Reverse edges: node id -> ids of nodes that lead to it.
  late final Map<String, List<String>> predecessors = () {
    final map = <String, List<String>>{};
    for (final node in nodes) {
      for (final target in node.next) {
        map.putIfAbsent(target, () => []).add(node.id);
      }
    }
    return map;
  }();

  MapNodeDefinition? node(String id) => nodesById[id];

  factory RegionDefinition.fromJson(Map<String, dynamic> json) => RegionDefinition(
        id: JsonRead.string(json, 'id'),
        order: JsonRead.integer(json, 'order'),
        name: JsonRead.string(json, 'name'),
        subtitle: JsonRead.optString(json, 'subtitle') ?? '',
        theme: RegionTheme.parse(json['theme']),
        degrees: DegreeRange.fromJson(json['degree'] ?? 1),
        startNodeId: JsonRead.string(json, 'startNodeId'),
        bossNodeId: JsonRead.string(json, 'bossNodeId'),
        nodes: JsonRead.objects(json, 'nodes').map(MapNodeDefinition.fromJson).toList(),
      );

  @override
  List<Object?> get props => [id];
}
