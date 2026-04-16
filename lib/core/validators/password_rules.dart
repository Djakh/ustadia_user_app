import 'package:easy_localization/easy_localization.dart';

class PasswordRules {
  static const int minLength = 8;

  static bool hasMinLength(String value) => value.length >= minLength;

  static bool hasUpper(String value) => RegExp(r'[A-Z]').hasMatch(value);

  static bool hasLower(String value) => RegExp(r'[a-z]').hasMatch(value);

  static bool hasNumber(String value) => RegExp(r'[0-9]').hasMatch(value);

  static bool hasSymbol(String value) => RegExp(r'[^A-Za-z0-9]').hasMatch(value);

  static bool isStrong(String value) =>
      hasMinLength(value) &&
      hasUpper(value) &&
      hasLower(value) &&
      hasNumber(value) &&
      hasSymbol(value);

  static List<String> issues(String value) {
    final issues = <String>[];
    if (!hasMinLength(value)) {
      issues.add('Use at least {count} characters.'.tr(namedArgs: {'count': '$minLength'}));
    }
    if (!hasUpper(value)) issues.add('Add at least one uppercase letter.'.tr());
    if (!hasLower(value)) issues.add('Add at least one lowercase letter.'.tr());
    if (!hasNumber(value)) issues.add('Add at least one number.'.tr());
    if (!hasSymbol(value)) issues.add('Add at least one symbol.'.tr());
    return issues;
  }
}
