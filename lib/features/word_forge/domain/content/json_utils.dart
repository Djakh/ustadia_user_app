/// Small helpers for defensive JSON parsing of content and save files.
///
/// Content comes from bundled assets today and may come from a backend later,
/// so every reader tolerates missing optional fields and reports malformed
/// required fields with a [FormatException] that names the field.
class JsonRead {
  JsonRead._();

  static String string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Missing or empty "$key"');
  }

  static String? optString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  static int integer(Map<String, dynamic> json, String key, {int? fallback}) {
    final value = json[key];
    if (value is num) return value.toInt();
    if (fallback != null) return fallback;
    throw FormatException('Missing number "$key"');
  }

  static double number(Map<String, dynamic> json, String key, {double? fallback}) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (fallback != null) return fallback;
    throw FormatException('Missing number "$key"');
  }

  static bool boolean(Map<String, dynamic> json, String key, {bool fallback = false}) {
    final value = json[key];
    return value is bool ? value : fallback;
  }

  static List<String> strings(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return value.whereType<String>().where((item) => item.trim().isNotEmpty).toList();
  }

  static List<Map<String, dynamic>> objects(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Map<String, dynamic> object(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  static Map<String, int> intMap(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.value is num) entry.key.toString(): (entry.value as num).toInt(),
    };
  }
}
