import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/battle/combat_config.dart';
import '../../domain/content/region_definition.dart';

/// Theme bridge: Word Forge's fantasy palette is derived from the host app's
/// design DNA so both feel like one product family.
///
/// Ustadia → Word Forge
/// * brand green #00C950 (AppColors.primary)  → [brand] rune glow, primary
///   actions, player magic, selected answers, active map nodes
/// * Ubuntu typeface                            → [WfText.family]
/// * pill buttons, 52 px tall (Button)          → [WfShape.pill], [WfShape.buttonHeight]
/// * 20 px card radius (PrimaryBox)             → [WfShape.card]
/// * icon + title + grey subtitle dialogs       → `showWfConfirm`
///
/// To re-brand (e.g. a standalone build) change [WordForgeBrand] only.
abstract final class WordForgeBrand {
  static const Color primary = Color(0xFF00C950);
  static const Color primaryDeep = Color(0xFF00A341);
  static const String fontFamily = 'Ubuntu';
}

abstract final class WfShape {
  static const double pill = 32;
  static const double card = 20;
  static const double tile = 16;
  static const double buttonHeight = 52;
}

/// Word Forge palette: dark fantasy neutrals plus brand-derived accents.
abstract final class WfColors {
  static const night = Color(0xFF0A0D1E);
  static const deep = Color(0xFF12163A);
  static const panel = Color(0xFF1A1F47);
  static const panelHigh = Color(0xFF252B5E);
  static const stroke = Color(0x2EFFFFFF);
  static const strokeStrong = Color(0x55FFFFFF);

  static const gold = Color(0xFFF2C86B);
  static const goldDeep = Color(0xFFB8862F);
  /// Brand green translated for dark arenas (brighter, glowing).
  static const brand = Color(0xFF34E089);
  static const brandDeep = WordForgeBrand.primaryDeep;
  static const brandSoft = Color(0xFF9DF5C4);

  /// The player's magic is the brand colour.
  static const arcane = brand;
  static const arcaneDeep = brandDeep;
  static const sky = Color(0xFF5FE1FF);
  static const ember = Color(0xFFFF7A45);
  static const emberDeep = Color(0xFFD13E2A);
  static const resonance = Color(0xFFB28CFF);
  static const resonanceDeep = Color(0xFF6D4BD8);
  static const life = Color(0xFF5BE38D);
  static const danger = Color(0xFFFF5470);

  static const text = Color(0xFFF6F2E6);
  static const textDim = Color(0xFFC0BCD6);
  static const textMute = Color(0xFF8A87A8);

  /// Accent for a move: player = brand, enemy = ember, criticals red,
  /// specials gold (player) or violet (enemy).
  static Color forMove(BattleTurn turn, MoveKind? kind) => switch ((turn, kind)) {
        (BattleTurn.player, MoveKind.critical) => gold,
        (BattleTurn.player, MoveKind.special) => gold,
        (BattleTurn.player, _) => brand,
        (BattleTurn.enemy, MoveKind.critical) => danger,
        (BattleTurn.enemy, MoveKind.special) => resonance,
        (BattleTurn.enemy, _) => ember,
      };

  static Color forNode(MapNodeType type) => switch (type) {
        MapNodeType.battle => const Color(0xFFE6A15A),
        MapNodeType.elite => const Color(0xFFFF6B8B),
        MapNodeType.challenge => sky,
        MapNodeType.bonus => gold,
        MapNodeType.recovery => life,
        MapNodeType.miniBoss => const Color(0xFFFF8F4A),
        MapNodeType.boss => danger,
        MapNodeType.mystery => resonance,
      };
}

abstract final class WfText {
  static const family = WordForgeBrand.fontFamily;

  static TextStyle display(double size, {Color color = WfColors.text, double spacing = 2}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: spacing,
        color: color,
        height: 1.1,
      );

  static TextStyle title(double size, {Color color = WfColors.text, FontWeight weight = FontWeight.w700}) =>
      TextStyle(fontFamily: family, fontSize: size, fontWeight: weight, color: color, height: 1.2);

  static TextStyle body(double size, {Color color = WfColors.textDim, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: family, fontSize: size, fontWeight: weight, color: color, height: 1.35);

  static TextStyle label(double size, {Color color = WfColors.textMute, double spacing = 1.6}) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: spacing,
        color: color,
      );

  /// Readable English runes: uppercase, bold, generous tracking.
  static TextStyle rune(double size, {Color color = WfColors.text}) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * 0.06,
        color: color,
        height: 1.15,
      );
}

/// Region backdrop palettes used by both the map and the battle scene.
class RegionPalette {
  final Color skyTop;
  final Color skyBottom;
  final Color far;
  final Color mid;
  final Color near;
  final Color ground;
  final Color accent;
  final Color glow;

  const RegionPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.far,
    required this.mid,
    required this.near,
    required this.ground,
    required this.accent,
    required this.glow,
  });

  static RegionPalette of(RegionTheme theme) => switch (theme) {
        RegionTheme.road => const RegionPalette(
            skyTop: Color(0xFF1B1F4B),
            skyBottom: Color(0xFFC77A5B),
            far: Color(0xFF3A3466),
            mid: Color(0xFF4B3A5E),
            near: Color(0xFF2D2440),
            ground: Color(0xFF5A4636),
            accent: Color(0xFFF2C86B),
            glow: Color(0xFFFFB27A),
          ),
        RegionTheme.forest => const RegionPalette(
            skyTop: Color(0xFF071A24),
            skyBottom: Color(0xFF1F5A55),
            far: Color(0xFF12383B),
            mid: Color(0xFF0E2C2C),
            near: Color(0xFF081C1D),
            ground: Color(0xFF1D3B2A),
            accent: Color(0xFF9CFFB0),
            glow: Color(0xFF7BF1D8),
          ),
        RegionTheme.ruins => const RegionPalette(
            skyTop: Color(0xFF140E26),
            skyBottom: Color(0xFF5B3F7A),
            far: Color(0xFF2E2448),
            mid: Color(0xFF3A2F55),
            near: Color(0xFF1E1832),
            ground: Color(0xFF3B3350),
            accent: Color(0xFFB28CFF),
            glow: Color(0xFFFFD166),
          ),
      };
}


/// Shadows and glows for Word Forge UI.
///
/// Blurred shadows are re-rendered on every frame while the battle scene
/// animates, and on many Android GPUs (Mali, Adreno mid-range) that alone
/// cost ~19 ms per frame on a 1080p phone. On Android the same shapes are
/// drawn without blur (soft semi-transparent rings for glows, flat offset
/// shapes for drop shadows); iOS keeps real blurs.
abstract final class WfFx {
  static final bool cheap = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// One shadow, as a list so callers can spread it into `boxShadow`.
  static List<BoxShadow> shadow(Color color, {double blurRadius = 0, Offset offset = Offset.zero, double spreadRadius = 0}) {
    if (!cheap || blurRadius <= 0) {
      return [BoxShadow(color: color, blurRadius: blurRadius, offset: offset, spreadRadius: spreadRadius)];
    }
    if (offset != Offset.zero) {
      // Drop shadow: a flat, lighter copy of the shape, offset.
      return [BoxShadow(color: color.withValues(alpha: color.a * 0.6), offset: offset * 0.6, spreadRadius: spreadRadius)];
    }
    // Glow: two soft rings that fade outwards.
    return [
      BoxShadow(color: color.withValues(alpha: color.a * 0.22), spreadRadius: spreadRadius + blurRadius * 0.4),
      BoxShadow(color: color.withValues(alpha: color.a * 0.35), spreadRadius: spreadRadius + blurRadius * 0.15),
    ];
  }

  /// Text glow: blurred on iOS, none on Android (the text stays readable).
  static List<Shadow> textGlow(Color color, double blurRadius) =>
      cheap ? const [] : [Shadow(color: color, blurRadius: blurRadius)];

  /// Dark outline that keeps HUD text readable over the scene.
  static List<Shadow> textOutline() => cheap
      ? const [Shadow(color: Color(0xCC000000), offset: Offset(0, 1))]
      : const [Shadow(color: Colors.black, blurRadius: 4)];
}
