import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../domain/battle/battle_events.dart';
import '../domain/battle/battle_models.dart';
import '../domain/battle/combat_config.dart';
import '../domain/language/challenge_type.dart';
import '../domain/language/language_challenge.dart';
import '../domain/progression/buffs.dart';
import '../presentation/theme/wf_theme.dart';
import 'entities/entity.dart';
import 'vfx/vfx.dart';
import 'word_forge_battle_game.dart';

/// Turns battle events into choreography: anticipation → cast → travel →
/// impact → reaction → recovery. All timings fit inside the engine's hold
/// windows (`PacingHolds`), so visuals finish before the next challenge.
/// Never validates English and never changes battle state.
///
/// Visual hierarchy (also mirrored in audio):
/// * Normal: one projectile, small burst, light shake; a Weak Cast is dim and
///   quiet.
/// * Critical: golden volley, brief slow motion, heavier shake, CRITICAL tag.
/// * Special: lights down, camera in, rune circles, build-up, major impact.
/// Enemy attacks use the look of their magic family (`ElementStyle`).
class BattleChoreographer {
  final WordForgeBattleGame game;
  SpellOrb? _enemyCharge;
  RuneCircle? _circle;
  int _turnActor = 0;

  BattleChoreographer(this.game) {
    game.enemy(0).entity.play(EntityState.enraged, duration: 0.8);
    game.player.play(EntityState.cast, duration: 0.6);
  }

  VfxConfig get vfx => game.vfx;
  PositionComponent get root => game.stage;
  EntityComponent get player => game.player;

  void handle(BattleEvent event) {
    switch (event) {
      case BattleStarted():
        break;
      case TurnStarted(:final turn, :final kind, :final move, :final actor):
        _turnStarted(turn, kind, move, actor);
      case TaskPresented(:final turn, :final kind, :final challenge):
        _taskPresented(turn, kind, challenge);
      case TaskResolved(:final success):
        _taskStep(success);
      case ActionResolved(:final outcome, :final lastChallenge):
        _resolved(outcome, lastChallenge);
      case CriticalOpportunity():
        break;
      case SpecialReady():
        root.add(Shockwave(position: player.corePoint, color: WfColors.gold, maxRadius: 140, duration: 0.7));
        root.add(burst(at: player.castPoint, color: WfColors.gold, count: vfx.particles(18), speed: 120, size: 2.5));
      case SpecialActivated():
        break;
      case TurnSkipped(:final reason, :final actor):
        if (reason == 'staggered') {
          final enemy = game.enemy(actor).entity;
          enemy.play(EntityState.hit, duration: 0.6);
          root.add(StaggerStars(position: enemy.position - Vector2(0, enemy.size.y * 1.02), life: 1.2));
        } else {
          player.play(EntityState.hit, duration: 0.5);
          root.add(Shockwave(position: player.corePoint, color: WfColors.resonance, maxRadius: 90));
        }
      case EnemyDefeated(:final index):
        final enemy = game.enemy(index).entity;
        enemy.play(EntityState.defeated);
        game.enemy(index).shield.lower();
        root.add(burst(at: enemy.corePoint, color: WfColors.gold, count: vfx.particles(30), speed: 260, lifespan: 0.9));
        root.add(Shockwave(position: enemy.corePoint, color: WfColors.gold, maxRadius: 170, duration: 0.7));
        game.slowMotion(seconds: 0.3, scale: 0.45);
      case TargetChanged(:final index):
        game.setTarget(index);
      case MatchMade():
        root.add(burst(at: player.castPoint, color: WfColors.brand, count: vfx.particles(6), speed: 80, size: 2));
      case MatchMissed():
        break;
      case WordEaten():
        for (final slot in game.slots) {
          slot.entity.play(EntityState.chomp);
        }
      case IncantationUnstable():
        game.shaker.shake(3, duration: 0.2);
        _circle?.charge = 0.4;
      case AnswerForgiven():
        root.add(burst(at: player.corePoint, color: WfColors.life, count: vfx.particles(12), speed: 120));
      case WardTriggered():
        game.wardRing.absorb();
        game.wardAura.active = false;
        root.add(Shockwave(position: player.corePoint, color: const Color(0xFFFFB86B), maxRadius: 110));
        root.add(debris(at: player.corePoint, color: const Color(0xFFB9B2A6), count: vfx.particles(8)));
      case WardRaised(:final charges):
        game.wardRing.set(charges);
        game.wardAura.active = charges == 1;
      case BuffUsed(:final buff):
        root.add(burst(at: player.castPoint, color: WfColors.gold, count: vfx.particles(10), speed: 100, size: 2));
        if (buff == BuffType.shield) game.wardAura.active = true;
      case PoisonApplied(:final target):
        if (target < 0) {
          root.add(ThornVines(position: player.position.clone(), color: const Color(0xFF6FBF4A), reach: player.size.y * 0.9));
          root.add(Shockwave(position: player.corePoint, color: WfColors.life, maxRadius: 100, duration: 0.6));
        } else {
          final enemy = game.enemy(target).entity;
          game.sequencer.after(0.75, () {
            root.add(ThornVines(position: enemy.position.clone(), color: const Color(0xFF6FBF4A), reach: enemy.size.y * 0.9));
            root.add(Shockwave(position: enemy.corePoint, color: WfColors.life, maxRadius: 120, duration: 0.6));
          });
        }
      case PoisonTick(:final target, :final damage):
        if (damage <= 0) break;
        final victim = target < 0 ? player : game.enemy(target).entity;
        victim.play(EntityState.hit, duration: 0.3);
        root.add(rise(at: victim.corePoint + Vector2(0, 20), color: WfColors.life, count: vfx.particles(10), spread: 50, speed: 90, size: 3));
        root.add(FloatingText(
            text: '-$damage', position: victim.corePoint - Vector2(0, 60), color: WfColors.life, fontSize: target < 0 ? 20 : 18));
        root.add(FloatingText(text: 'POISON', position: victim.corePoint - Vector2(0, 84), color: WfColors.life, fontSize: 12));
      case WordFlowChanged(:final active):
        game.flowAura.active = active;
        if (active) root.add(Shockwave(position: player.corePoint, color: WfColors.gold, maxRadius: 160, duration: 0.6));
      case StageChanged(:final enraged):
        _stageChange(enraged: enraged);
      case TimerRanOut():
        break;
      case BattleEnded(:final result):
        _end(result);
    }
  }

  // --- turn starts (anticipation / telegraph) --------------------------------

  void _turnStarted(BattleTurn turn, MoveKind kind, MoveDefinition? move, int actor) {
    _cleanupPending();
    if (actor >= 0) _turnActor = actor;
    if (turn == BattleTurn.player) {
      switch (kind) {
        case MoveKind.normal:
          break;
        case MoveKind.critical:
          player.play(EntityState.channel);
          _circle = RuneCircle(color: WfColors.gold, radius: 70, position: player.position - Vector2(0, 4));
          root.add(_circle!);
          root.add(Shockwave(position: player.corePoint, color: WfColors.gold, maxRadius: 130));
          game.dim.dim(0.25);
        case MoveKind.special:
          // Dedicated Special sequence: lights down, camera in, big runes in
          // the spell's own colour.
          final color = _spellColor(move?.effect);
          player.play(EntityState.channel);
          game.dim.dim(0.55);
          game.zoomer.zoomTo(1.08, player.position);
          _circle = RuneCircle(color: color, radius: 110, position: player.position - Vector2(0, 4));
          root.add(_circle!);
          root.add(RuneCircle(color: WfColors.gold, radius: 80, position: player.position - Vector2(0, 4)));
          root.add(burst(at: player.corePoint, color: color, count: vfx.particles(26), speed: 90, lifespan: 1.2, size: 2));
      }
      return;
    }
    final enemy = game.enemy(actor);
    final element = game.elementOf(actor);
    switch (kind) {
      case MoveKind.normal:
        enemy.entity.play(EntityState.cast, duration: 0.6);
        if (element.heavy) game.shaker.shake(2, duration: 0.3);
      case MoveKind.critical:
        enemy.entity.play(EntityState.enraged, duration: 1.0);
        enemy.charge.active = true;
        game.shaker.shake(3, duration: 0.5);
        game.dim.dim(0.3, color: const Color(0xFF2A0508));
        if (vfx.flashes) root.add(ScreenFlash(size: game.size.clone(), color: WfColors.danger.withValues(alpha: 0.22)));
      case MoveKind.special:
        // Readable wind-up in the enemy's own magic: a golem gathers dust and
        // shakes the ground, a mage spins runes, a treant grows thorns at
        // the player's feet, a lich frosts the floor.
        enemy.entity.play(element.heavy ? EntityState.enraged : EntityState.shield, duration: element.heavy ? 1.2 : null);
        enemy.charge.active = true;
        game.dim.dim(0.3, color: element == ElementStyle.thorn ? const Color(0xFF071A08) : const Color(0xFF12082A));
        final accent = game.accentOf(actor);
        final at = element == ElementStyle.thorn ? player.corePoint : enemy.entity.corePoint;
        final feet = element == ElementStyle.thorn ? player.position.clone() : enemy.entity.position.clone();
        root.addAll(elementTelegraph(style: element, at: at, feet: feet, color: accent, vfx: vfx));
        if (element.heavy) game.shaker.shake(4, duration: 0.8);
        game.sequencer.after(0.6, () {
          if (enemy.charge.active) root.addAll(elementTelegraph(style: element, at: at, feet: feet, color: accent, vfx: vfx));
        });
    }
  }

  Color _spellColor(MoveEffect? effect) => switch (effect) {
        MoveEffect.ward => WfColors.sky,
        MoveEffect.bind => WfColors.resonance,
        MoveEffect.multiHit => WfColors.ember,
        _ => WfColors.brand,
      };

  void _taskPresented(BattleTurn turn, MoveKind kind, LanguageChallenge challenge) {
    if (turn == BattleTurn.player) {
      // Anticipation: the apprentice raises the staff and gathers a glint
      // while the word is being chosen.
      if (kind == MoveKind.normal) {
        player.play(EntityState.cast, duration: 0.5);
        root.add(burst(at: player.castPoint, color: WfColors.brand, count: vfx.particles(5), speed: 40, lifespan: 0.6, size: 2));
      }
      return;
    }
    final relation = challenge.type == ChallengeType.antonym || challenge.type == ChallengeType.synonym;
    final source = game.enemy(_turnActor).entity;
    _enemyCharge?.removeFromParent();
    final element = game.elementOf(_turnActor);
    final orb = ElementBolt(
      style: element,
      color: kind == MoveKind.critical ? WfColors.danger : (kind == MoveKind.special ? WfColors.resonance : game.accentOf(_turnActor)),
      radius: kind == MoveKind.normal ? 13 : 17,
      label: relation ? challenge.prompt.toUpperCase() : null,
      position: source.castPoint - Vector2(20, 10),
    );
    _enemyCharge = orb;
    root.add(orb);
  }

  void _taskStep(bool success) {
    if (success) {
      root.add(burst(at: player.castPoint, color: WfColors.brand, count: vfx.particles(10), speed: 110, size: 2));
      _circle?.charge = math.min(1, (_circle?.charge ?? 0) + 0.3);
    } else {
      root.add(fizzle(at: player.castPoint, count: vfx.particles(8)));
    }
  }

  void _cleanupPending() {
    _enemyCharge?.removeFromParent();
    _enemyCharge = null;
    _circle?.collapse();
    _circle = null;
    for (final slot in game.slots) {
      slot.charge.active = false;
    }
  }

  void _endMoment() {
    game.dim.dim(0);
    game.zoomer.reset();
    for (final slot in game.slots) {
      slot.charge.active = false;
    }
  }

  double _boost(LanguageChallenge? challenge) => 1 + game.masteryOf(challenge?.focusWordId) * 0.08;

  String? _picked(LanguageChallenge? challenge, ActionOutcome outcome) {
    if (challenge == null) return null;
    final id = outcome.success ? outcome.correctOptionId ?? outcome.pickedOptionId : outcome.pickedOptionId;
    return id == null ? null : challenge.option(id)?.text.toUpperCase();
  }

  // --- resolution ------------------------------------------------------------

  void _resolved(ActionOutcome outcome, LanguageChallenge? challenge) {
    switch ((outcome.turn, outcome.kind)) {
      case (BattleTurn.player, MoveKind.normal):
        _playerNormal(outcome, challenge);
      case (BattleTurn.player, MoveKind.critical):
        _playerCritical(outcome);
      case (BattleTurn.player, MoveKind.special):
        _playerSpecial(outcome);
      case (BattleTurn.enemy, MoveKind.normal):
      case (BattleTurn.enemy, MoveKind.critical):
        _enemyAttack(outcome, challenge);
      case (BattleTurn.enemy, MoveKind.special):
        _enemySpecial(outcome, challenge);
    }
  }

  void _playerNormal(ActionOutcome outcome, LanguageChallenge? challenge) {
    final target = game.enemy(outcome.target);
    final weak = outcome.weakCast;
    player.play(weak ? EntityState.cast : EntityState.attack);
    final boost = weak ? 0.75 : _boost(challenge);
    final color = weak ? const Color(0xFF8B8AA6) : WfColors.brand;
    final orb = SpellOrb(color: color, radius: 13 * boost, label: weak ? null : _picked(challenge, outcome), position: player.castPoint);
    root.add(orb);
    final destination = target.shield.isActive || outcome.shieldCracked ? target.shield.position : target.entity.corePoint;
    orb.launch(destination, duration: weak ? 0.55 : 0.45, arc: weak ? 18 : 34, onArrive: () {
      if (outcome.shieldShattered) {
        _shatter(target);
      } else if (outcome.shieldCracked) {
        target.shield.hit();
        root.add(Shockwave(position: target.shield.position, color: WfColors.resonance, maxRadius: 120, duration: 0.45));
        game.shaker.shake(4);
      } else if (weak) {
        // Weak Cast: a puff and a quiet grey number, no shake.
        root.add(fizzle(at: target.entity.corePoint, count: vfx.particles(8)));
        _hitEnemy(outcome.target, outcome.damageToEnemies[outcome.target] ?? 0, color: color, small: true, weak: true);
        if (outcome.damageToPlayer > 0 || outcome.blockedByWard) {
          // A wrong word left an opening: the enemy flicks a quick counter back.
          final actor = game.slots.indexWhere((slot) => slot.index == outcome.target);
          final element = game.elementOf(actor);
          final bolt = ElementBolt(style: element, color: game.accentOf(actor), radius: 9, position: target.entity.castPoint);
          root.add(bolt);
          target.entity.play(EntityState.attack, duration: 0.4);
          bolt.launch(player.corePoint, duration: 0.35, arc: 12,
              onArrive: () => _hitPlayer(outcome, element: element, accent: game.accentOf(actor), reflectTo: actor));
        }
      } else {
        _hitEnemy(outcome.target, outcome.damageToEnemies[outcome.target] ?? 0, color: WfColors.brand);
      }
    });
  }

  void _shatter(EnemySlot target) {
    target.shield.shatter();
    target.entity.play(EntityState.hit, duration: 0.7);
    game.slowMotion(seconds: 0.3, scale: 0.4);
    game.shaker.shake(9, duration: 0.4);
    if (vfx.flashes) root.add(ScreenFlash(size: game.size.clone(), color: WfColors.resonance.withValues(alpha: 0.3)));
    root.add(StaggerStars(position: target.entity.position - Vector2(0, target.entity.size.y * 1.02)));
  }

  void _playerCritical(ActionOutcome outcome) {
    final circle = _circle;
    _circle = null;
    game.sequencer.after(0.9, _endMoment);
    if (!outcome.success) {
      circle?.collapse();
      root.add(fizzle(at: player.castPoint, count: vfx.particles(12)));
      return;
    }
    circle?.release();
    player.play(EntityState.attack, duration: 0.6);
    final target = game.enemy(outcome.target);
    // Volley of three golden spells.
    for (var i = 0; i < 3; i++) {
      game.sequencer.after(i * 0.12, () {
        final orb = SpellOrb(color: WfColors.gold, radius: 11, position: player.castPoint + Vector2(0, (i - 1) * 14));
        root.add(orb);
        orb.launch(target.entity.corePoint + Vector2(0, (i - 1) * 10), duration: 0.32, arc: 20 + i * 12, onArrive: () {
          root.add(burst(at: target.entity.corePoint, color: WfColors.gold, count: vfx.particles(10), speed: 220));
        });
      });
    }
    game.sequencer.after(0.5, () {
      game.slowMotion(seconds: 0.25, scale: 0.4);
      if (outcome.shieldShattered) {
        _shatter(target);
      } else if (outcome.shieldCracked) {
        target.shield.hit();
      } else {
        _hitEnemy(outcome.target, outcome.damageToEnemies[outcome.target] ?? 0, color: WfColors.gold, heavy: true, tag: 'CRITICAL');
      }
    });
  }

  void _playerSpecial(ActionOutcome outcome) {
    final circle = _circle;
    _circle = null;
    if (outcome.spellFizzled) {
      // Fizzle: the circle folds, a grey sputter, nothing else. Quieter and
      // shorter than a failed Critical on purpose.
      circle?.collapse();
      player.play(EntityState.hit, duration: 0.4);
      root.add(fizzle(at: player.castPoint, count: vfx.particles(14)));
      root.add(FloatingText(text: 'FIZZLE', position: player.corePoint - Vector2(0, 90), color: const Color(0xFF9A98B0), fontSize: 15));
      game.sequencer.after(0.9, _endMoment);
      return;
    }
    final share = outcome.total == 0 ? 1.0 : outcome.successes / outcome.total;
    player.play(EntityState.victory, duration: 1.2);
    circle?.release();
    switch (outcome.effect) {
      case MoveEffect.ward:
        _castWard(outcome);
      case MoveEffect.bind:
        _castBind(outcome, share);
      case MoveEffect.multiHit:
        _castStorm(outcome);
      case MoveEffect.poison:
        _castBlight(outcome);
      case MoveEffect.damage:
      case MoveEffect.shield:
      case MoveEffect.lock:
        _castIncantation(outcome, share);
    }
    game.sequencer.after(2.2, _endMoment);
  }

  /// Thorn Blight: a bubbling cloud rolls over to the enemy and bursts into
  /// drops; brambles curl up around it (see PoisonApplied) and the poison
  /// aura stays until the last tick.
  void _castBlight(ActionOutcome outcome) {
    final target = game.enemy(outcome.target);
    game.sequencer.after(0.25, () {
      root.add(rise(at: player.castPoint, color: WfColors.life, count: vfx.particles(12), spread: 30, speed: 60, size: 3));
      final cloud = PoisonCloud(color: WfColors.life, radius: 22, position: player.castPoint);
      root.add(cloud);
      cloud.launch(target.entity.corePoint, duration: 0.75, onArrive: () {
        if (outcome.shieldShattered) _shatter(target);
        if (outcome.poisonApplied == 0) {
          root.add(fizzle(at: target.entity.corePoint, count: vfx.particles(10)));
          return;
        }
        target.entity.play(EntityState.hit, duration: 0.5);
        root.add(splash(at: target.entity.corePoint, color: const Color(0xFF3F8A3A), count: vfx.particles(18)));
        root.add(burst(at: target.entity.corePoint, color: WfColors.life, count: vfx.particles(16), speed: 150, lifespan: 0.8, size: 2.5));
        root.add(FloatingText(text: 'POISONED', position: target.entity.corePoint - Vector2(0, 90), color: WfColors.life, fontSize: 15));
        game.shaker.shake(3, duration: 0.3);
        game.slowMotion(seconds: 0.25, scale: 0.5);
      });
    });
  }

  void _castIncantation(ActionOutcome outcome, double share) {
    final beams = 1 + (share * 2).round();
    game.sequencer.after(0.35, () {
      for (var i = 0; i < beams; i++) {
        game.sequencer.after(i * 0.16, () {
          for (final entry in outcome.damageToEnemies.entries) {
            final target = game.enemy(entry.key).entity;
            root.add(BeamStrike(
              from: player.castPoint,
              to: target.corePoint + Vector2(0, (i - 1) * 12.0),
              color: i.isEven ? WfColors.brand : WfColors.gold,
              width: (18 + share * 18) * (entry.key == outcome.target ? 1 : 0.6),
              duration: 0.75,
            ));
          }
        });
      }
      game.shaker.shake(6 + share * 8, duration: 0.6);
    });
    game.sequencer.after(0.8, () {
      game.slowMotion(seconds: 0.45, scale: 0.35);
      if (vfx.flashes) {
        root.add(ScreenFlash(size: game.size.clone(), color: const Color(0xFFFFF4C8).withValues(alpha: 0.35 + share * 0.3)));
      }
      if (outcome.shieldShattered) _shatter(game.enemy(outcome.target));
      for (final entry in outcome.damageToEnemies.entries) {
        _hitEnemy(entry.key, entry.value, color: WfColors.gold, heavy: true);
        root.add(burst(
            at: game.enemy(entry.key).entity.corePoint,
            color: WfColors.brand,
            count: vfx.particles((20 + share * 30).round()),
            speed: 340,
            lifespan: 1));
      }
    });
  }

  /// Guardian Ward: stones rise from the ground and lock into a ring.
  void _castWard(ActionOutcome outcome) {
    if (outcome.wardCharges == 0) {
      game.sequencer.after(0.3, () => root.add(fizzle(at: player.castPoint, count: vfx.particles(12))));
      return;
    }
    game.sequencer.after(0.3, () {
      root.add(debris(at: player.position - Vector2(0, 10), color: const Color(0xFFB9B2A6), count: vfx.particles(16)));
      game.shaker.shake(4, duration: 0.3);
    });
    game.sequencer.after(0.8, () {
      root.add(Shockwave(position: player.corePoint, color: WfColors.sky, maxRadius: 150, duration: 0.7));
      root.add(burst(at: player.corePoint, color: WfColors.sky, count: vfx.particles(22), speed: 140, size: 2.5));
      if (vfx.flashes) root.add(ScreenFlash(size: game.size.clone(), color: WfColors.sky.withValues(alpha: 0.2)));
      game.slowMotion(seconds: 0.3, scale: 0.45);
    });
  }

  /// Rune Bind: a violet beam, then chains snap shut around the enemy.
  void _castBind(ActionOutcome outcome, double share) {
    final target = game.enemy(outcome.target);
    game.sequencer.after(0.35, () {
      root.add(BeamStrike(from: player.castPoint, to: target.entity.corePoint, color: WfColors.resonance, width: 16 + share * 10, duration: 0.6));
      game.shaker.shake(5, duration: 0.4);
    });
    game.sequencer.after(0.8, () {
      if (outcome.shieldShattered) _shatter(target);
      _hitEnemy(outcome.target, outcome.damageToEnemies[outcome.target] ?? 0, color: WfColors.resonance, heavy: true);
      if (outcome.staggerApplied) {
        root.add(BindChains(position: target.entity.corePoint, color: WfColors.resonance, radius: target.entity.size.x * 0.5));
        root.add(StaggerStars(position: target.entity.position - Vector2(0, target.entity.size.y * 1.02), life: 1.6));
        game.slowMotion(seconds: 0.4, scale: 0.35);
        if (vfx.flashes) root.add(ScreenFlash(size: game.size.clone(), color: WfColors.resonance.withValues(alpha: 0.3)));
      }
    });
  }

  /// Word Storm: one ember bolt per solved word, rapid fire.
  void _castStorm(ActionOutcome outcome) {
    final target = game.enemy(outcome.target);
    final hits = outcome.successes;
    if (hits == 0) {
      game.sequencer.after(0.3, () => root.add(fizzle(at: player.castPoint, count: vfx.particles(12))));
      return;
    }
    final perHit = ((outcome.damageToEnemies[outcome.target] ?? 0) / hits).round();
    for (var i = 0; i < hits; i++) {
      game.sequencer.after(0.3 + i * 0.22, () {
        final bolt = ElementBolt(style: ElementStyle.spark, color: WfColors.ember, radius: 12, position: player.castPoint + Vector2(0, (i - 1) * 10));
        root.add(bolt);
        bolt.launch(target.entity.corePoint + Vector2((i - 1) * 8.0, (i - 1) * 6.0), duration: 0.28, arc: 14 + i * 6, onArrive: () {
          if (outcome.shieldShattered && i == 0) _shatter(target);
          _hitEnemy(outcome.target, perHit, color: WfColors.ember, heavy: i == hits - 1);
          root.add(burst(at: target.entity.corePoint, color: WfColors.ember, count: vfx.particles(12), speed: 260, lifespan: 0.4, size: 2));
        });
      });
    }
    game.sequencer.after(0.3 + hits * 0.22 + 0.1, () {
      game.slowMotion(seconds: 0.3, scale: 0.4);
      if (vfx.flashes) root.add(ScreenFlash(size: game.size.clone(), color: WfColors.ember.withValues(alpha: 0.25)));
    });
  }

  void _enemyAttack(ActionOutcome outcome, LanguageChallenge? challenge) {
    final enemy = game.enemy(outcome.actor);
    final critical = outcome.kind == MoveKind.critical;
    final element = game.elementOf(outcome.actor);
    final accent = critical ? WfColors.danger : game.accentOf(outcome.actor);
    final enemyOrb = _enemyCharge ??
        ElementBolt(style: element, color: accent, radius: critical ? 17 : 13, position: enemy.entity.castPoint);
    _enemyCharge = null;
    if (enemyOrb.parent == null) root.add(enemyOrb);
    enemy.entity.play(EntityState.attack);
    player.play(EntityState.cast);
    final meet = (player.castPoint + enemy.entity.corePoint) / 2;

    if (outcome.success) {
      final counter = SpellOrb(
          color: WfColors.brand, radius: 13 * _boost(challenge), label: _picked(challenge, outcome), position: player.castPoint);
      root.add(counter);
      counter.launch(meet + Vector2(8, 0), duration: 0.42, arc: 18);
      enemyOrb.launch(meet - Vector2(8, 0), duration: 0.42, arc: 12, onArrive: () {
        root
          ..addAll(elementImpact(style: element, at: meet, color: accent, vfx: vfx))
          ..add(burst(at: meet, color: WfColors.brand, count: vfx.particles(16)))
          ..add(Shockwave(position: meet, color: critical ? WfColors.gold : const Color(0xFFFFFFFF), maxRadius: critical ? 150 : 90));
        if (challenge != null && challenge.prompt.isNotEmpty) {
          root.add(LetterBurst(word: challenge.prompt, color: accent, position: meet));
        }
        if (critical) {
          // Parry: time slows, a golden ring flares.
          game.slowMotion(seconds: 0.35, scale: 0.35);
          root.add(Shockwave(position: player.corePoint, color: WfColors.gold, maxRadius: 120, duration: 0.6));
        }
        game.shaker.shake(critical ? 7 : 4);
        final spark = SpellOrb(color: critical ? WfColors.gold : WfColors.brand, radius: critical ? 10 : 7, position: meet);
        root.add(spark);
        spark.launch(enemy.entity.corePoint, duration: 0.3,
            onArrive: () => _hitEnemy(outcome.actor, outcome.damageToEnemies[outcome.actor] ?? 0, color: WfColors.brand, small: true));
      });
    } else {
      final failing = SpellOrb(color: const Color(0xFF8B8AA6), radius: 10, label: _picked(challenge, outcome), position: player.castPoint);
      root.add(failing);
      failing.launch(player.castPoint + Vector2(60, -10), duration: 0.3,
          onArrive: () => root.add(fizzle(at: player.castPoint + Vector2(60, -10), count: vfx.particles(10))));
      enemyOrb.launch(player.corePoint, duration: critical ? element.flightSeconds * 0.85 : element.flightSeconds, arc: element.arc,
          onArrive: () => _hitPlayer(outcome, element: element, accent: accent, critical: critical, reflectTo: outcome.actor));
    }
    game.sequencer.after(1.0, _endMoment);
  }

  void _enemySpecial(ActionOutcome outcome, LanguageChallenge? challenge) {
    final enemy = game.enemy(outcome.actor);
    if (outcome.shieldRaised) {
      final target = game.enemy(outcome.target);
      enemy.entity.play(EntityState.cast, duration: 0.8);
      root.add(ResonanceBeam(
          from: () => enemy.entity.castPoint, to: () => target.entity.corePoint, color: WfColors.resonance, duration: 0.6));
      game.sequencer.after(0.35, () {
        target.shield.raise(strength: game.shieldStrengthOf(outcome.target));
        root.add(Shockwave(position: target.entity.corePoint, color: WfColors.resonance, maxRadius: 160, duration: 0.7));
        game.shaker.shake(3);
      });
      game.sequencer.after(1.1, _endMoment);
      return;
    }
    _enemyAttack(outcome, challenge);
    if (outcome.poisonApplied > 0 && outcome.damageToPlayer > 0) {
      game.sequencer.after(0.9, () {
        root.add(splash(at: player.corePoint, color: const Color(0xFF3F8A3A), count: vfx.particles(14)));
        root.add(FloatingText(text: 'POISONED', position: player.corePoint - Vector2(0, 92), color: WfColors.life, fontSize: 15));
      });
    }
    if (outcome.lockApplied) {
      game.sequencer.after(0.7, () {
        root.add(RuneCircle(color: WfColors.resonance, radius: 50, position: player.position - Vector2(0, 4))..charge = 1);
      });
    }
  }

  // --- reactions -------------------------------------------------------------

  void _hitEnemy(int index, int damage, {required Color color, bool small = false, bool heavy = false, bool weak = false, String? tag}) {
    if (damage <= 0) return;
    final enemy = game.enemy(index).entity;
    if (enemy.animator.state != EntityState.defeated) enemy.play(EntityState.hit, duration: weak ? 0.25 : null);
    if (!weak) {
      root.add(burst(at: enemy.corePoint, color: color, count: vfx.particles(heavy ? 30 : (small ? 8 : 18)), speed: heavy ? 320 : 220));
    }
    if (tag != null) {
      root.add(FloatingText(text: tag, position: enemy.corePoint - Vector2(0, 96), color: WfColors.gold, fontSize: 15));
    }
    root.add(FloatingText(
        text: '-$damage',
        position: enemy.corePoint - Vector2(0, 70),
        color: weak ? const Color(0xFF9A98B0) : (heavy ? WfColors.gold : const Color(0xFFFFFFFF)),
        fontSize: weak ? 17 : (heavy ? 26 : 20)));
    if (!small && !weak) game.shaker.shake(heavy ? 9 : 4);
  }

  void _hitPlayer(ActionOutcome outcome, {required ElementStyle element, required Color accent, bool critical = false, int reflectTo = -1}) {
    if (outcome.blockedByWard) {
      root.add(Shockwave(position: player.corePoint, color: const Color(0xFFFFB86B), maxRadius: 100));
      root.add(debris(at: player.corePoint, color: const Color(0xFFB9B2A6), count: vfx.particles(6)));
      if (outcome.reflected > 0 && reflectTo >= 0) {
        // Guardian Ward: the absorbed blow is flung straight back.
        final attacker = game.enemy(reflectTo).entity;
        final bolt = SpellOrb(color: WfColors.sky, radius: 11, position: player.corePoint);
        root.add(bolt);
        game.slowMotion(seconds: 0.2, scale: 0.5);
        bolt.launch(attacker.corePoint, duration: 0.3, arc: 20, onArrive: () {
          _hitEnemy(reflectTo, outcome.reflected, color: WfColors.sky, small: true, tag: 'REFLECT');
          root.add(Shockwave(position: attacker.corePoint, color: WfColors.sky, maxRadius: 90, duration: 0.4));
        });
      }
      return;
    }
    if (outcome.damageToPlayer <= 0) return;
    player.play(EntityState.hit);
    root
      ..addAll(elementImpact(style: element, at: player.corePoint, color: accent, vfx: vfx, heavy: critical))
      ..add(FloatingText(text: '-${outcome.damageToPlayer}', position: player.corePoint - Vector2(0, 70), color: WfColors.danger));
    game.shaker.shake(element.shake * (critical ? 1.6 : 1), duration: critical || element.heavy ? 0.5 : 0.3);
    if (vfx.flashes) {
      root.add(ScreenFlash(size: game.size.clone(), color: WfColors.danger.withValues(alpha: critical ? 0.35 : 0.2)));
    }
  }

  void _stageChange({required bool enraged}) {
    _cleanupPending();
    final boss = game.enemy(0);
    boss.shield.lower();
    boss.entity.animator.setEnraged(enraged);
    boss.entity.play(EntityState.enraged);
    game.shaker.shake(12, duration: 0.6);
    root.add(Shockwave(position: boss.entity.corePoint, color: enraged ? WfColors.danger : WfColors.gold, maxRadius: 220, duration: 0.8));
    if (vfx.flashes) {
      root.add(ScreenFlash(
          size: game.size.clone(), color: (enraged ? WfColors.danger : WfColors.gold).withValues(alpha: 0.3), duration: 0.6));
    }
  }

  void _end(BattleResult result) {
    _cleanupPending();
    _endMoment();
    game.wardRing.set(0);
    if (result.victory) {
      player.play(EntityState.victory);
      for (final slot in game.slots) {
        if (slot.entity.animator.state != EntityState.defeated) slot.entity.play(EntityState.defeated);
      }
      root.add(burst(at: player.castPoint, color: WfColors.gold, count: vfx.particles(24), speed: 160, size: 2.5));
    } else if (!result.abandoned) {
      player.play(EntityState.defeated);
      for (final slot in game.slots) {
        slot.entity.play(EntityState.enraged);
      }
    }
  }
}
