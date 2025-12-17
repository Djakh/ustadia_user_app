import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

enum InputFieldType { primary, phone, email, password }

class InputField extends StatelessWidget {
  final InputFieldType type;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const InputField.primary({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
  }) : type = InputFieldType.primary;

  const InputField.phone({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
  }) : type = InputFieldType.phone;

  const InputField.email({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
  }) : type = InputFieldType.email;

  const InputField.password({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
  }) : type = InputFieldType.password;

  /// --- Methods ---

  TextInputType get keyboardType => switch (type) {
        InputFieldType.phone => TextInputType.phone,
        InputFieldType.email => TextInputType.emailAddress,
        _ => TextInputType.text
      };

  bool get obscureText => type == InputFieldType.password;

  bool get hasError => errorText != null && errorText!.isNotEmpty;

  List<TextInputFormatter> get formatters => switch (type) {
        InputFieldType.phone => [
            FilteringTextInputFormatter.digitsOnly,
            _PhoneFormatter(),
          ],
        _ => const []
      };

  String get phoneHint => hint ?? '(--) --- -- --';

  InputBorder border(BuildContext context, Color color) => OutlineInputBorder(
      borderRadius: Style.border12, borderSide: BorderSide(color: color, width: 1.4));

  InputDecoration decoration(BuildContext context) {
    final baseColor = context.cs.onTertiary.withOpacity(0.4);
    final borderColor = hasError ? context.cs.error : baseColor;
    final focusColor = hasError ? context.cs.error : context.cs.onTertiary;
    return InputDecoration(
        hintText: type == InputFieldType.phone ? phoneHint : hint,
        hintStyle: Style.small3w4(context, color: TextColorRole.greyColor),
        prefixIcon: type == InputFieldType.phone
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 2),
                child: Text('+998', style: Style.small3w4(context)))
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixStyle: Style.small3w4(context),
        filled: true,
        fillColor: context.cs.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: border(context, borderColor),
        focusedBorder: border(context, focusColor),
        errorBorder: border(context, context.cs.error),
        focusedErrorBorder: border(context, context.cs.error));
  }

  /// --- Widgets ---

  Widget error(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Icon(Icons.error_outline, color: context.cs.error, size: 18),
        const SizedBox(width: 6),
        Text(errorText ?? '',
            style: Style.small3w4(context, color: TextColorRole.greyColor)
                .copyWith(color: context.cs.error))
      ]));

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Style.small3w4(context)),
        const SizedBox(height: 6),
        TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            cursorColor: AppColors.green36,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            inputFormatters: formatters,
            style: Style.small3w4(context),
            decoration: decoration(context),
            onChanged: onChanged),
        if (hasError) error(context)
      ]);
}

class _PhoneFormatter extends TextInputFormatter {
  static const maxLength = 9;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > maxLength ? digits.substring(0, maxLength) : digits;
    final formatted = _format(trimmed);
    return TextEditingValue(
        text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }

  String _format(String digits) {
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();
    var index = 0;

    buffer.write('(');
    final first = digits.length >= 2 ? digits.substring(0, 2) : digits;
    buffer.write(first);
    index += first.length;
    if (index >= 2) buffer.write(') ');

    if (index < digits.length) {
      final end = index + 3 > digits.length ? digits.length : index + 3;
      final mid = digits.substring(index, end);
      buffer.write(mid);
      index += mid.length;
      if (mid.length == 3 && index < digits.length) buffer.write(' ');
    }

    if (index < digits.length) {
      final end = index + 2 > digits.length ? digits.length : index + 2;
      final part = digits.substring(index, end);
      buffer.write(part);
      index += part.length;
      if (part.length == 2 && index < digits.length) buffer.write(' ');
    }

    if (index < digits.length) {
      final end = index + 2 > digits.length ? digits.length : index + 2;
      buffer.write(digits.substring(index, end));
    }

    return buffer.toString();
  }
}
