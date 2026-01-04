import 'package:flutter/material.dart';

enum TextColorRole { onSurface, whiteColor, primaryColor, greyColor }

class Style {
  Style._();

  // =============================================================
  //  FIGMA CONFIG
  // =============================================================

  /// Global letter spacing from Figma: -2%
  static const double figmaLetterSpacingPercent = -2;

  static double _letterSpacing(double fontSize) {
    return fontSize * (figmaLetterSpacingPercent / 100);
  }

  // =============================================================
  //  BORDER RADIUS
  // =============================================================

  static BorderRadius get borderVerBottom95 =>
      const BorderRadius.vertical(bottom: Radius.circular(95));

  static BorderRadius get border95 => const BorderRadius.all(Radius.circular(95));
  static BorderRadius get border32 => const BorderRadius.all(Radius.circular(32));
  static BorderRadius get borderVer24 => const BorderRadius.vertical(top: Radius.circular(24));
  static BorderRadius get border24 => const BorderRadius.all(Radius.circular(24));
  static BorderRadius get borderVer36 => const BorderRadius.vertical(top: Radius.circular(36));
  static BorderRadius get border20 => const BorderRadius.all(Radius.circular(20));
  static BorderRadius get borderVer20 => const BorderRadius.vertical(top: Radius.circular(20));

  static BorderRadius get borderTop20 =>
      const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20));

  static BorderRadius get border16 => const BorderRadius.all(Radius.circular(16));

  static BorderRadius get borderOnlyTop16 =>
      const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16));

  static BorderRadius get border14 => const BorderRadius.all(Radius.circular(14));
  static BorderRadius get border12 => const BorderRadius.all(Radius.circular(12));
  static BorderRadius get border10 => const BorderRadius.all(Radius.circular(10));

  static BorderRadius get borderOnlyRight8 =>
      const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8));

  static BorderRadius get borderOnlyLeft8 =>
      const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8));

  static BorderRadius get borderOnlyTopLeft8 =>
      const BorderRadius.only(topLeft: Radius.circular(8));

  static BorderRadius get border8 => const BorderRadius.all(Radius.circular(8));
  static BorderRadius get border6 => const BorderRadius.all(Radius.circular(6));
  static BorderRadius get border4 => const BorderRadius.all(Radius.circular(4));
  static BorderRadius get border2 => const BorderRadius.all(Radius.circular(2));

  // =============================================================
  //  PADDING
  // =============================================================

  static const EdgeInsets paddingAll2 = EdgeInsets.all(2);
  static const EdgeInsets paddingAll4 = EdgeInsets.all(4);
  static const EdgeInsets paddingAll6 = EdgeInsets.all(6);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8);
  static const EdgeInsets paddingAll10 = EdgeInsets.all(10);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12);
  static const EdgeInsets paddingAll14 = EdgeInsets.all(14);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);

  static const EdgeInsets paddingH5 = EdgeInsets.symmetric(horizontal: 5);
  static const EdgeInsets paddingH8 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets paddingH10 = EdgeInsets.symmetric(horizontal: 10);
  static const EdgeInsets paddingH12 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingH20 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(horizontal: 24);

  static const EdgeInsets paddingV4 = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets paddingV6 = EdgeInsets.symmetric(vertical: 6);
  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets paddingV20 = EdgeInsets.symmetric(vertical: 20);
  static const EdgeInsets paddingV24 = EdgeInsets.symmetric(vertical: 24);

  static const EdgeInsets paddingZero = EdgeInsets.zero;

  // =============================================================
  //  TYPOGRAPHY
  // =============================================================

  static String get fontFamily => 'Ubuntu';

  static Color _textColor(BuildContext context, TextColorRole? role) {
    final cs = Theme.of(context).colorScheme;

    switch (role) {
      case TextColorRole.onSurface:
        return cs.onSurface;
      case TextColorRole.whiteColor:
        return cs.onPrimary;
      case TextColorRole.primaryColor:
        return cs.primary;
      case TextColorRole.greyColor:
        return cs.onTertiary;
      case null:
        return cs.onSurface;
    }
  }

  static TextStyle _text(
    BuildContext context, {
    required double size,
    required FontWeight weight,
    TextColorRole? color,
    double height = 1.4,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: _letterSpacing(size), // ✅ FIGMA -2%
      color: _textColor(context, color),
    );
  }

  // ---------- Headline (24) ----------

  static TextStyle headline9w7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 40, weight: FontWeight.w700, color: color);

  static TextStyle headline7w7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 36, weight: FontWeight.w700, color: color);

  static TextStyle headline5w7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 32, weight: FontWeight.w700, color: color);

  static TextStyle headline3w7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 28, weight: FontWeight.w700, color: color);

  static TextStyle headline2w7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 26, weight: FontWeight.w700, color: color);

  static TextStyle headlinew7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 24, weight: FontWeight.w700, color: color);

  static TextStyle headlinew6(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 24, weight: FontWeight.w600, color: color);

  // ---------- Body (20) ----------

  static TextStyle body3w7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 20, weight: FontWeight.w700, color: color);

  static TextStyle body3w4(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 20, weight: FontWeight.w400, color: color);

  // ---------- Body (18) ----------
  static TextStyle body2w7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 18, weight: FontWeight.w700, color: color);

  static TextStyle body2w6(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 18, weight: FontWeight.w600, color: color);

  static TextStyle body2w5(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 18, weight: FontWeight.w500, color: color);

  static TextStyle body2w4(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 18, weight: FontWeight.w400, color: color);

  static TextStyle body2w3(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 18, weight: FontWeight.w300, color: color);

  // ---------- Body (16) ----------
  static TextStyle bodyw7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 16, weight: FontWeight.w700, color: color);

  static TextStyle bodyw6(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 16, weight: FontWeight.w600, color: color);

  static TextStyle bodyw5(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 16, weight: FontWeight.w500, color: color);

  static TextStyle bodyw4(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 16, weight: FontWeight.w400, color: color);

  static TextStyle bodyw3(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 16, weight: FontWeight.w300, color: color);

  // ---------- Small ----------
  static TextStyle small3w7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 14, weight: FontWeight.w700, color: color ?? TextColorRole.onSurface);

  static TextStyle small3w5(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 14, weight: FontWeight.w500, color: color ?? TextColorRole.onSurface);

  static TextStyle small3w4(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 14, weight: FontWeight.w400, color: color ?? TextColorRole.onSurface);

  static TextStyle small3w3(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 14, weight: FontWeight.w300, color: color ?? TextColorRole.onSurface);

  static TextStyle small2w5(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 12, weight: FontWeight.w500, color: color ?? TextColorRole.onSurface);

  static TextStyle small2w4(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 12, weight: FontWeight.w400, color: color ?? TextColorRole.onSurface);

  static TextStyle small2w3(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 12, weight: FontWeight.w300, color: color ?? TextColorRole.onSurface);
  static TextStyle smallw7(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 10, weight: FontWeight.w700, color: color ?? TextColorRole.onSurface);
  static TextStyle smallw6(BuildContext context, {TextColorRole? color}) =>
      _text(context, size: 10, weight: FontWeight.w600, color: color ?? TextColorRole.onSurface);
}
