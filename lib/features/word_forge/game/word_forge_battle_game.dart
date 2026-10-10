import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../domain/battle/battle_events.dart';
import '../domain/battle/battle_models.dart';
import '../domain/battle/combat_config.dart';
import '../domain/characters/player_character.dart';
import '../domain/content/enemy_definition.dart';
import '../domain/content/region_definition.dart';
import '../presentation/art/region_backdrop_painter.dart';
import '../presentation/theme/wf_theme.dart';
import '../word_forge_assets.dart';
import 'battle_choreographer.dart';
import 'entities/entity.dart';
import 'entities/skins.dart';
import 'entities/sprite_skin.dart';
import 'vfx/vfx.dart';

/// One enemy on stage with its own barrier, telegraph and target ring.
class EnemySlot {
  final int index;
  final EntityComponent entity;
  final ShieldBubble shield;
  final TargetRing ring;
  final AuraComponent charge;
  final PoisonAura poison;
  IntentMarker? intent;

  EnemySlot({
    required this.index,
    required this.entity,
    required this.shield,
    required this.ring,
    required this.charge,
    required this.poison,
  });
}

/// Tappable enemy (tap = choose target in two-enemy fights).
class _TappableEntity extends EntityComponent with TapCallbacks {
  final void Function()? onTap;

  _TappableEntity({
    required super.skin,
    required super.palette,
    required super.animator,
    required super.facing,
    this.onTap,
  });

  @override
  void onTapDown(TapDownEvent event) => onTap?.call();
}

/// Flame runtime for a battle. Purely presentational: it listens to engine
/// events and animates; input is only forwarded (enemy taps).
class WordForgeBattleGame extends FlameGame {
  final Stream<BattleEvent> events;

  /// Snapshots keep telegraphs (intents) and the target ring in sync.
  final Stream<BattleSnapshot>? snapshots;
  final List<EnemyDefinition> enemies;

  /// Magic family per enemy (see `EnemyBehaviour.element`), same order as [enemies].
  final List<ElementStyle> elements;
  final PlayerCharacterDefinition character;
  final int characterTier;
  final RegionTheme theme;
  final VfxConfig vfx;
  final int Function(String? wordId) masteryOf;
  final void Function(int index)? onEnemyTapped;

  WordForgeBattleGame({
    required this.events,
    this.snapshots,
    required this.enemies,
    this.elements = const [],
    required this.character,
    required this.characterTier,
    required this.theme,
    required this.vfx,
    required this.masteryOf,
    this.onEnemyTapped,
  });

  /// Shake layer > zoom layer > everything on stage.
  late final PositionComponent sceneRoot;
  late final PositionComponent stage;
  late final EntityComponent player;
  late final List<EnemySlot> slots;
  late final AuraComponent flowAura;
  late final AuraComponent wardAura;
  late final PoisonAura playerPoison;
  late final WardRing wardRing;
  late final Sequencer sequencer;
  late final Shaker shaker;
  late final Zoomer zoomer;
  late final ArenaDim dim;
  late final BattleChoreographer choreographer;
  late final _BackdropComponent _backdrop;
  StreamSubscription<BattleEvent>? _subscription;
  StreamSubscription<BattleSnapshot>? _snapshotSubscription;
  double _timeScale = 1;
  final Map<int, int> _shieldStrength = {};

  /// Latest barrier strength from the engine snapshot (for the raise effect).
  int shieldStrengthOf(int index) => _shieldStrength[index] ?? 1;

  ElementStyle elementOf(int index) => index >= 0 && index < elements.length ? elements[index] : ElementStyle.arcane;

  /// Enemy accent colour, used for its projectiles.
  Color accentOf(int index) =>
      index >= 0 && index < enemies.length ? Color(enemies[index].visual.accentColor) : WfColors.ember;
  double _slowRemaining = 0;

  @override
  Color backgroundColor() => WfColors.night;

  @override
  Future<void> onLoad() async {
    sceneRoot = PositionComponent();
    stage = PositionComponent();
    await add(sceneRoot);
    sceneRoot.add(stage);
    _backdrop = _BackdropComponent(theme);
    dim = ArenaDim();
    stage.addAll([_backdrop, dim]);

    player = EntityComponent(
      skin: ApprenticeSkin(character: character, tier: characterTier, magic: WfColors.brand),
      palette: const EntityPalette(primary: WfColors.brand, secondary: WfColors.gold, accent: WfColors.brand),
      animator: EntityAnimator(),
      facing: 1,
    )..priority = 10;

    slots = [];
    for (var i = 0; i < enemies.length; i++) {
      final definition = enemies[i];
      final visual = definition.visual;
      final entity = _TappableEntity(
        skin: await _enemySkin(definition),
        palette: EntityPalette(
          primary: Color(visual.primaryColor),
          secondary: Color(visual.secondaryColor),
          accent: Color(visual.accentColor),
        ),
        animator: EntityAnimator(tempo: definition.tempo),
        facing: -1,
        onTap: enemies.length > 1 ? () => onEnemyTapped?.call(i) : null,
      )..priority = 10 - i;
      final slot = EnemySlot(
        index: i,
        entity: entity,
        shield: ShieldBubble(color: WfColors.resonance, radius: 80, vfx: vfx),
        ring: TargetRing(color: WfColors.brand, ringWidth: 90),
        charge: AuraComponent(color: WfColors.danger, radius: 100),
        poison: PoisonAura(color: WfColors.life, radius: 60),
      );
      slots.add(slot);
      stage.addAll([slot.ring, slot.charge, slot.poison, entity, slot.shield]);
    }

    flowAura = AuraComponent(color: WfColors.gold, radius: 110);
    wardAura = AuraComponent(color: const Color(0xFFFFB86B), radius: 90);
    wardRing = WardRing(color: WfColors.sky, radius: 70);
    playerPoison = PoisonAura(color: WfColors.life, radius: 55);
    sequencer = Sequencer();
    shaker = Shaker(sceneRoot, scale: vfx.shakeScale);
    zoomer = Zoomer(stage);
    stage.addAll([flowAura, wardAura, wardRing, playerPoison, player]);
    addAll([sequencer, shaker, zoomer]);
    choreographer = BattleChoreographer(this);
    _layout(size);
    _subscription = events.listen(choreographer.handle);
    _snapshotSubscription = snapshots?.listen(_sync);
  }

  void _sync(BattleSnapshot snapshot) {
    setTarget(snapshot.targetIndex);
    playerPoison.active = snapshot.playerPoisoned;
    for (final enemy in snapshot.enemies) {
      if (enemy.index >= slots.length) continue;
      final slot = slots[enemy.index];
      slot.poison.active = enemy.alive && enemy.poisoned;
      _shieldStrength[enemy.index] = enemy.shield?.strength ?? _shieldStrength[enemy.index] ?? 1;
      final kind = enemy.alive ? enemy.intent : null;
      final wanted = kind == MoveKind.critical || kind == MoveKind.special;
      final critical = kind == MoveKind.critical;
      if (!wanted) {
        slot.intent?.removeFromParent();
        slot.intent = null;
      } else if (slot.intent == null || slot.intent!.critical != critical) {
        slot.intent?.removeFromParent();
        final marker = IntentMarker(color: critical ? WfColors.danger : WfColors.resonance, critical: critical);
        slot.intent = marker;
        stage.add(marker);
      }
    }
  }

  Future<EntitySkin> _enemySkin(EnemyDefinition definition) async {
    final fallback = skinFor(definition.visual.skin);
    final sprite = definition.visual.sprite;
    if (sprite == null) return fallback;
    try {
      images.prefix = '';
      final image = await images.load('${WordForgeAssets.enemySprites}/$sprite');
      return SpriteEntitySkin(sprite: Sprite(image), fallback: fallback);
    } on Object {
      return fallback;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout(size);
  }

  void _layout(Vector2 size) {
    _backdrop.size = size.clone();
    dim.size = size.clone();
    final landscape = size.x > size.y * 1.25;
    final byHeight = landscape ? size.y * 0.5 : size.y * 0.38;
    final unit = byHeight.clamp(90.0, size.x * 0.4).clamp(90.0, 320.0);
    final ground = size.y * (landscape ? 0.9 : 0.88);
    player
      ..size = Vector2(unit * 0.8, unit)
      ..position = Vector2(size.x * 0.22, ground);
    final multi = slots.length > 1;
    for (final slot in slots) {
      final definition = enemies[slot.index];
      final back = multi && slot.index == 1;
      final scale = definition.visual.scale * (definition.isBoss ? 1.08 : 1) * (multi ? 0.86 : 1) * (back ? 0.92 : 1);
      final enemyUnit = unit * scale;
      final x = multi ? (slot.index == 0 ? 0.66 : 0.87) : 0.76;
      slot.entity
        ..size = Vector2(enemyUnit * 0.9, enemyUnit)
        ..position = Vector2(size.x * x, ground - size.y * (back ? 0.06 : 0.02));
      slot.shield
        ..radius = enemyUnit * 0.6
        ..position = slot.entity.corePoint;
      slot.ring
        ..ringWidth = enemyUnit * 0.75
        ..position = slot.entity.position.clone();
      slot.charge.position = slot.entity.corePoint;
      slot.poison
        ..radius = enemyUnit * 0.5
        ..position = slot.entity.corePoint;
    }
    flowAura.position = player.corePoint;
    wardAura.position = player.corePoint;
    playerPoison
      ..radius = unit * 0.45
      ..position = player.corePoint;
    wardRing
      ..radius = unit * 0.55
      ..position = player.position - Vector2(0, 6);
  }

  EnemySlot enemy(int index) => slots[index.clamp(0, slots.length - 1)];

  void setTarget(int index) {
    for (final slot in slots) {
      slot.ring.visible = slots.length > 1 && slot.index == index;
    }
  }

  /// Brief slow motion for impactful moments (visual only; the battle clock
  /// is driven separately and never slows down).
  void slowMotion({double seconds = 0.35, double scale = 0.35}) {
    _slowRemaining = seconds;
    _timeScale = scale;
  }

  @override
  void update(double dt) {
    if (_slowRemaining > 0) {
      _slowRemaining -= dt;
      if (_slowRemaining <= 0) _timeScale = 1;
    }
    super.update(dt * _timeScale);
    for (final slot in slots) {
      slot.shield.position = slot.entity.corePoint;
      slot.charge.position = slot.entity.corePoint;
      slot.intent?.position = slot.entity.position - Vector2(0, slot.entity.size.y * 1.08);
      slot.poison.position = slot.entity.corePoint;
    }
    flowAura.position = player.corePoint;
    wardAura.position = player.corePoint;
    playerPoison.position = player.corePoint;
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    _subscription = null;
    _snapshotSubscription?.cancel();
    _snapshotSubscription = null;
    super.onRemove();
  }
}

class _BackdropComponent extends PositionComponent {
  final RegionBackdropPainter painter;
  double _time = 0;

  _BackdropComponent(RegionTheme theme)
      : painter = RegionBackdropPainter(theme: theme, horizon: 0.7),
        super(priority: -10);

  @override
  void update(double dt) => _time += dt;

  @override
  void render(Canvas canvas) {
    painter.time = _time;
    painter.paint(canvas, Size(size.x, size.y));
  }
}
