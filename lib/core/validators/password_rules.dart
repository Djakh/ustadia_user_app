class PasswordRules {
  static const int minLength = 11;

  static bool hasMinLength(String value) => value.length >= minLength;

  static bool hasUpper(String value) => RegExp(r'[A-Z]').hasMatch(value);

  static bool hasLower(String value) => RegExp(r'[a-z]').hasMatch(value);

  static bool hasNumber(String value) => RegExp(r'[0-9]').hasMatch(value);

  static bool hasSymbol(String value) => RegExp(r'[^A-Za-z0-9]').hasMatch(value);

  static bool isStrong(String value) =>
      hasMinLength(value) && hasUpper(value) && hasLower(value) && hasNumber(value) && hasSymbol(value);

  static List<String> issues(String value) {
    final issues = <String>[];
    if (!hasMinLength(value)) issues.add('Use at least $minLength characters.');
    if (!hasUpper(value)) issues.add('Add at least one uppercase letter.');
    if (!hasLower(value)) issues.add('Add at least one lowercase letter.');
    if (!hasNumber(value)) issues.add('Add at least one number.');
    if (!hasSymbol(value)) issues.add('Add at least one symbol.');
    return issues;
  }
}
