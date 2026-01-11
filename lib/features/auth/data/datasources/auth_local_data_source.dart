import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  final SharedPreferences prefs;

  AuthLocalDataSource({required this.prefs});

  static const String accessTokenKey = 'access_token';
  static const String introSeenKey = 'intro_seen';
  static const String rememberMeKey = 'remember_me';
  static const String lastLoginMethodKey = 'last_login_method';
  static const String lastEmailKey = 'last_email';
  static const String lastPhoneKey = 'last_phone';
  static const String lastPasswordKey = 'last_password';

  String getAccessToken() => prefs.getString(accessTokenKey) ?? '';

  bool hasAccessToken() => getAccessToken().isNotEmpty;

  Future<void> setAccessToken(String token) => prefs.setString(accessTokenKey, token);

  Future<void> clearAccessToken() => prefs.remove(accessTokenKey);

  bool isIntroSeen() => prefs.getBool(introSeenKey) ?? false;

  Future<void> setIntroSeen(bool value) => prefs.setBool(introSeenKey, value);

  bool isRememberMeEnabled() => prefs.getBool(rememberMeKey) ?? false;

  Future<void> setRememberMeEnabled(bool value) => prefs.setBool(rememberMeKey, value);

  String getLastLoginMethod() => prefs.getString(lastLoginMethodKey) ?? '';

  Future<void> setLastLoginMethod(String value) => prefs.setString(lastLoginMethodKey, value);

  String getLastEmail() => prefs.getString(lastEmailKey) ?? '';

  Future<void> setLastEmail(String value) => prefs.setString(lastEmailKey, value);

  String getLastPhone() => prefs.getString(lastPhoneKey) ?? '';

  Future<void> setLastPhone(String value) => prefs.setString(lastPhoneKey, value);

  String getLastPassword() => prefs.getString(lastPasswordKey) ?? '';

  Future<void> setLastPassword(String value) => prefs.setString(lastPasswordKey, value);

  Future<void> clearRememberedCredentials() async {
    await prefs.remove(rememberMeKey);
    await prefs.remove(lastLoginMethodKey);
    await prefs.remove(lastEmailKey);
    await prefs.remove(lastPhoneKey);
    await prefs.remove(lastPasswordKey);
  }
}
