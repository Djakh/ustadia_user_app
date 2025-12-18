import 'package:flutter/material.dart';

class IntroSurveyTopicModel {
  final String label;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color textColor;
  final Color selectedTextColor;

  const IntroSurveyTopicModel({
    required this.label,
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.textColor,
    required this.selectedTextColor,
  });
}

class IntroSurveyOptionModel {
  final String title;
  final String description;

  const IntroSurveyOptionModel({required this.title, required this.description});
}

