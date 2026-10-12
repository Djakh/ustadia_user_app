import 'package:easy_localization/easy_localization.dart';

/// Money comes from the backend as a whole-sum string; it is only regrouped
/// for display, never turned into a double.
class BillingAmount {
  BillingAmount._();

  static const _groupSeparator = ' ';

  /// `"36000"` -> `"36 000"`, `"1500000.50"` -> `"1 500 000.50"`.
  static String group(String raw) {
    final value = raw.trim();
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$').firstMatch(value);
    if (match == null) return value;
    final sign = match.group(1) ?? '';
    final digits = match.group(2)!.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final fraction = match.group(3);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_groupSeparator);
      buffer.write(digits[i]);
    }
    final hasFraction = fraction != null && fraction.replaceAll('0', '').isNotEmpty;
    return '$sign$buffer${hasFraction ? '.$fraction' : ''}';
  }

  static String format(String raw, {String currency = 'UZS'}) {
    final amount = group(raw);
    if (currency.toUpperCase() == 'UZS') return '{amount} UZS'.tr(namedArgs: {'amount': amount});
    return '$amount $currency';
  }
}
