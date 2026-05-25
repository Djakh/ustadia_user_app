import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/services/word_translation_service.dart';

class TranslatableSectionContent extends StatefulWidget {
  final String data;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  const TranslatableSectionContent({
    super.key,
    required this.data,
    this.textStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  State<TranslatableSectionContent> createState() => _TranslatableSectionContentState();
}

class _TranslatableSectionContentState extends State<TranslatableSectionContent> {
  final WordTranslationService translationService = WordTranslationService();
  WordTranslationLanguage language = WordTranslationLanguage.uzbek;
  OverlayEntry? translationOverlay;
  Offset tooltipPosition = Offset.zero;
  String tooltipWord = '';
  String tooltipText = '';
  String? selectedTokenKey;
  bool isTooltipLoading = false;
  bool didSetInitialLanguage = false;
  int translationRequestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (didSetInitialLanguage) return;
    language = Localizations.localeOf(context).languageCode == 'ru'
        ? WordTranslationLanguage.russian
        : WordTranslationLanguage.uzbek;
    didSetInitialLanguage = true;
  }

  @override
  void dispose() {
    translationOverlay?.remove();
    translationOverlay = null;
    super.dispose();
  }

  String get plainText => normalizeText(widget.data);

  List<String> get paragraphs => plainText
      .split(RegExp(r'\n{2,}'))
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList();

  String get languageLabel => switch (language) {
        WordTranslationLanguage.uzbek => 'Uzbek',
        WordTranslationLanguage.russian => 'Russian',
      };

  void setLanguage(WordTranslationLanguage value) {
    if (language == value) return;
    removeTranslationOverlay();
    setState(() {
      language = value;
      selectedTokenKey = null;
    });
  }

  Future<void> translateWord(String rawWord, Offset position, String tokenKey) async {
    final word = normalizedWord(rawWord);
    if (word.isEmpty) return;
    final requestId = ++translationRequestId;
    tooltipPosition = position;
    tooltipWord = rawWord;
    tooltipText = 'Translating...'.tr();
    setState(() => selectedTokenKey = tokenKey);
    isTooltipLoading = true;
    showTranslation();

    try {
      final translated = await translationService.translateWord(word, language);
      if (!mounted || requestId != translationRequestId) return;
      tooltipText = translated;
      isTooltipLoading = false;
      translationOverlay?.markNeedsBuild();
    } catch (_) {
      if (!mounted || requestId != translationRequestId) return;
      tooltipText = 'Unable to translate'.tr();
      isTooltipLoading = false;
      translationOverlay?.markNeedsBuild();
    }
  }

  void showTranslation() {
    translationOverlay ??= OverlayEntry(builder: translationTooltip);
    if (!translationOverlay!.mounted) {
      Overlay.of(context, rootOverlay: true).insert(translationOverlay!);
    }
    translationOverlay?.markNeedsBuild();
  }

  void removeTranslationOverlay() {
    translationRequestId++;
    translationOverlay?.remove();
    translationOverlay = null;
  }

  void hideTranslation() {
    removeTranslationOverlay();
    if (selectedTokenKey == null || !mounted) return;
    setState(() => selectedTokenKey = null);
  }

  String normalizedWord(String value) {
    final match = RegExp(r"[A-Za-z]+(?:[-'][A-Za-z]+)?").firstMatch(value);
    return match?.group(0) ?? '';
  }

  Widget translationTooltip(BuildContext context) {
    final media = MediaQuery.of(context);
    const maxWidth = 220.0;
    final left = math.max(
        12.0, math.min(tooltipPosition.dx - maxWidth / 2, media.size.width - maxWidth - 12));
    final top = math.max(media.padding.top + 8, tooltipPosition.dy - 76);
    return Positioned(
        left: left,
        top: top,
        width: maxWidth,
        child: Material(
            color: Colors.transparent,
            child: GestureDetector(
                onTap: hideTranslation,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: AppColors.gray900,
                        borderRadius: Style.border16,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 6))
                        ]),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(tooltipWord,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Style.small3w4(context).copyWith(color: AppColors.gray300)),
                          const SizedBox(height: 3),
                          Text(tooltipText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Style.bodyw6(context).copyWith(color: AppColors.white)),
                          if (isTooltipLoading) ...[
                            const SizedBox(height: 8),
                            const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2))
                          ]
                        ]))))));
  }

  Widget get languageButton => PopupMenuButton<WordTranslationLanguage>(
      onSelected: setLanguage,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
            PopupMenuItem(
                value: WordTranslationLanguage.uzbek,
                child: Text('Uzbek'.tr(), style: Style.bodyw4(context))),
            PopupMenuItem(
                value: WordTranslationLanguage.russian,
                child: Text('Russian'.tr(), style: Style.bodyw4(context))),
          ],
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: Style.border16,
              border: Border.all(color: AppColors.gray300)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.settings_rounded, size: 18, color: AppColors.gray700),
            const SizedBox(width: 6),
            Text(languageLabel.tr(), style: Style.small2w5(context))
          ])));

  Widget tokenText(BuildContext context, String token, String tokenKey) {
    final style = widget.textStyle ?? Style.bodyw4(context);
    final isWord = normalizedWord(token).isNotEmpty;
    final isSelected = selectedTokenKey == tokenKey;
    if (!isWord) return Text('$token ', style: style, textAlign: widget.textAlign);
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (details) => translateWord(token, details.globalPosition, tokenKey),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
                color: isSelected ? AppColors.greenE7 : AppColors.transparent,
                borderRadius: Style.border8,
                border: Border.all(color: isSelected ? AppColors.greenC6 : AppColors.transparent)),
            child: Text('$token ',
                style: isSelected
                    ? style.copyWith(color: AppColors.green36, fontWeight: FontWeight.w700)
                    : style,
                textAlign: widget.textAlign)));
  }

  Widget paragraphText(BuildContext context, String paragraph, int paragraphIndex) {
    final tokens = paragraph.split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
    return Wrap(
        alignment: switch (widget.textAlign) {
          TextAlign.center => WrapAlignment.center,
          TextAlign.right || TextAlign.end => WrapAlignment.end,
          _ => WrapAlignment.start,
        },
        crossAxisAlignment: WrapCrossAlignment.center,
        children: tokens
            .asMap()
            .entries
            .map((entry) => tokenText(context, entry.value, '$paragraphIndex:${entry.key}'))
            .toList());
  }

  Widget get content => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(alignment: Alignment.centerRight, child: languageButton),
        const SizedBox(height: 14),
        ...paragraphs.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Builder(builder: (context) => paragraphText(context, entry.value, entry.key))))
      ]);

  @override
  Widget build(BuildContext context) => GestureDetector(
      behavior: HitTestBehavior.translucent, onTap: hideTranslation, child: content);
}

String normalizeText(String value) {
  var text = value
      .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</\s*div\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
  text = text.replaceAll(RegExp(r' *\n *'), '\n');
  return text.trim();
}
