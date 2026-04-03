import 'package:flutter/widgets.dart';

class SettingsItemModel {
  final String title;
  final String? iconAsset;
  final IconData? iconData;
  final bool isDestructive;

  const SettingsItemModel({
    required this.title,
    this.iconAsset,
    this.iconData,
    this.isDestructive = false,
  }) : assert(iconAsset != null || iconData != null, 'Settings item must have an icon');
}
