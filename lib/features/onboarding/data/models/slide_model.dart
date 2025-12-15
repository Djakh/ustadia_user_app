import 'package:flutter/material.dart';

class SlideModel {
  const SlideModel({
    required this.title,
    required this.description,
    required this.asset,
    required this.background,
    required this.accent,
  });

  final String title;
  final String description;
  final String asset;
  final Color background;
  final Color accent;
}
