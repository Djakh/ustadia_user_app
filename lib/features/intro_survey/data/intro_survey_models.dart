import 'package:flutter/material.dart';

class IntroSurveyTopicModel {
  final String label;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color textColor;

  const IntroSurveyTopicModel({
    required this.label,
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.textColor,
  });
}

class IntroSurveyOptionModel {
  final String title;
  final String description;

  const IntroSurveyOptionModel({required this.title, required this.description});
}
