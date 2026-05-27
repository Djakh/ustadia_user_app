import 'package:flutter/material.dart';

enum TutorialMascotMood {
  happy,
  smart,
  strong,
  confused,
  tired,
}

class TutorialStepModel {
  final String title;
  final String message;
  final IconData icon;
  final TutorialMascotMood? mascotMood;
  final Color? accentColor;
  final Color? accentBackgroundColor;
  final GlobalKey? targetKey;

  const TutorialStepModel({
    required this.title,
    required this.message,
    required this.icon,
    this.mascotMood,
    this.accentColor,
    this.accentBackgroundColor,
    this.targetKey,
  });
}

class TutorialPageIds {
  const TutorialPageIds._();

  static const dashboard = 'dashboard';
  static const practice = 'practice';
  static const practiceSets = 'practice_sets';
  static const practiceSession = 'practice_session';
  static const lessons = 'lessons';
  static const lessonUnits = 'lesson_units';
  static const lessonSections = 'lesson_sections';
  static const section = 'section';
  static const sectionQuiz = 'section_quiz';
  static const assignments = 'assignments';
  static const assignmentSections = 'assignment_sections';
  static const assignmentDetails = 'assignment_details';
  static const askAi = 'ask_ai';
  static const voiceAgent = 'voice_agent';
  static const profile = 'profile';
  static const settings = 'settings';
  static const language = 'language';
  static const teacherPicker = 'teacher_picker';
  static const editAccount = 'edit_account';
  static const leaderboard = 'leaderboard';
  static const notifications = 'notifications';
  static const meets = 'meets';
  static const reels = 'reels';
}
