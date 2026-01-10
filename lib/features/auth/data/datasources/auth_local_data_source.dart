import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  final SharedPreferences prefs;

  AuthLocalDataSource({required this.prefs});

  static const String accessTokenKey = 'access_token';
  static const String introSeenKey = 'intro_seen';

  String getAccessToken() => prefs.getString(accessTokenKey) ?? '';

  bool hasAccessToken() => getAccessToken().isNotEmpty;

  Future<void> setAccessToken(String token) => prefs.setString(accessTokenKey, token);

  Future<void> clearAccessToken() => prefs.remove(accessTokenKey);

  bool isIntroSeen() => prefs.getBool(introSeenKey) ?? false;

  Future<void> setIntroSeen(bool value) => prefs.setBool(introSeenKey, value);
}
