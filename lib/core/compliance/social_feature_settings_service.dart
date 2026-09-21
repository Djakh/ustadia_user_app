import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-level family controls used until the account API exposes parent
/// permissions. The backend must still enforce these permissions server-side.
class SocialFeatureSettingsService extends ChangeNotifier {
  final SharedPreferences preferences;

  SocialFeatureSettingsService({required this.preferences});

  static const commentsKey = 'family_social_comments_enabled';
  static const likesKey = 'family_social_likes_enabled';
  static const publicProfilesKey = 'family_social_public_profiles_enabled';
  static const adultPinHashKey = 'family_social_adult_pin_hash';

  // Social features are opt-in until an adult explicitly enables them.
  bool get commentsEnabled => preferences.getBool(commentsKey) ?? false;
  bool get likesEnabled => preferences.getBool(likesKey) ?? false;
  bool get publicProfilesEnabled => preferences.getBool(publicProfilesKey) ?? false;
  bool get hasAdultPin => (preferences.getString(adultPinHashKey) ?? '').isNotEmpty;

  Future<void> setCommentsEnabled(bool value) async {
    await preferences.setBool(commentsKey, value);
    notifyListeners();
  }

  Future<void> setLikesEnabled(bool value) async {
    await preferences.setBool(likesKey, value);
    notifyListeners();
  }

  Future<void> setPublicProfilesEnabled(bool value) async {
    await preferences.setBool(publicProfilesKey, value);
    notifyListeners();
  }

  Future<void> setAdultPin(String pin) async {
    await preferences.setString(adultPinHashKey, _hash(pin));
    notifyListeners();
  }

  bool verifyAdultPin(String pin) => _hash(pin) == preferences.getString(adultPinHashKey);

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
}
