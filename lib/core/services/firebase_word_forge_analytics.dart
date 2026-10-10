import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:ustadia_user_app/features/word_forge/word_forge.dart';

/// Bridges Word Forge's analytics port to Firebase Analytics.
class FirebaseWordForgeAnalytics implements WordForgeAnalytics {
  final FirebaseAnalytics? _analytics;

  FirebaseWordForgeAnalytics({FirebaseAnalytics? analytics}) : _analytics = analytics;

  FirebaseAnalytics? get _instance {
    try {
      return _analytics ?? FirebaseAnalytics.instance;
    } on Object {
      return null;
    }
  }

  @override
  void log(String event, [Map<String, Object> parameters = const {}]) {
    final analytics = _instance;
    if (analytics == null) return;
    analytics.logEvent(name: event, parameters: parameters).catchError((Object error) {
      if (kDebugMode) debugPrint('[WordForge analytics] $event failed: $error');
    });
  }
}
