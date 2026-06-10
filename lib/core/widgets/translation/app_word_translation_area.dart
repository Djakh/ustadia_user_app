import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/services/word_translation_service.dart';

class AppWordTranslationArea extends StatefulWidget {
  final Widget child;

  const AppWordTranslationArea({super.key, required this.child});

  @override
  State<AppWordTranslationArea> createState() => _AppWordTranslationAreaState();
}

class _AppWordTranslationAreaState extends State<AppWordTranslationArea> {
  final WordTranslationService translationService = WordTranslationService();
  OverlayEntry? translationOverlay;
  Offset tooltipPosition = Offset.zero;
  String tooltipWord = '';
  String tooltipText = '';
  String selectedText = '';
  bool isTooltipLoading = false;
  bool didSetInitialLanguage = false;
  int translationRequestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (didSetInitialLanguage) return;
    WordTranslationPreferences.language.value =
        WordTranslationLanguage.fromLocale(Localizations.localeOf(context).languageCode);
    didSetInitialLanguage = true;
  }

  @override
  void dispose() {
    removeTranslationOverlay();
    super.dispose();
  }

  String normalizedSelection(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!RegExp(r'[A-Za-z]').hasMatch(normalized)) return '';
    return normalized.characters.take(WordTranslationService.maxTextLength).join();
  }

  Future<void> translateText(String rawText, Offset position) async {
    final text = normalizedSelection(rawText);
    if (text.isEmpty) return;
    final requestId = ++translationRequestId;
    tooltipPosition = position;
    tooltipWord = text;
    tooltipText = 'Translating...'.tr();
    isTooltipLoading = true;
    showTranslation();

    try {
      final translated =
          await translationService.translateText(text, WordTranslationPreferences.language.value);
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

  void changeLanguage(WordTranslationLanguage value) {
    WordTranslationPreferences.language.value = value;
    if (tooltipWord.isNotEmpty) translateText(tooltipWord, tooltipPosition);
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

  Widget translationTooltip(BuildContext context) {
    final media = MediaQuery.of(context);
    const maxWidth = 246.0;
    final left = math.max(
        12.0, math.min(tooltipPosition.dx - maxWidth / 2, media.size.width - maxWidth - 12));
    final top = math.max(media.padding.top + 8, tooltipPosition.dy - 96);
    return Positioned.fill(
        child: Material(
            color: Colors.transparent,
            child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: removeTranslationOverlay,
                child: Stack(children: [
                  Positioned(
                      left: left,
                      top: top,
                      width: maxWidth,
                      child: GestureDetector(
                          onTap: () {},
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
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Style.small3w4(context)
                                            .copyWith(color: AppColors.gray300)),
                                    const SizedBox(height: 3),
                                    Text(tooltipText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style:
                                            Style.bodyw6(context).copyWith(color: AppColors.white)),
                                    if (isTooltipLoading) ...[
                                      const SizedBox(height: 8),
                                      const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2))
                                    ],
                                    const SizedBox(height: 8),
                                    ValueListenableBuilder<WordTranslationLanguage>(
                                        valueListenable: WordTranslationPreferences.language,
                                        builder: (context, language, _) => Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: WordTranslationLanguage.values
                                                .map((item) => languageChip(item, language))
                                                .toList()))
                                  ])))))
                ]))));
  }

  Widget languageChip(WordTranslationLanguage item, WordTranslationLanguage selected) =>
      GestureDetector(
          onTap: () => changeLanguage(item),
          child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                  color: item == selected
                      ? AppColors.primary
                      : AppColors.white.withValues(alpha: 0.12),
                  borderRadius: Style.border16),
              child: Text(item.label.tr(),
                  style: Style.small2w5(context).copyWith(color: AppColors.white))));

  Widget selectionMenu(BuildContext context, SelectableRegionState state) {
    final buttons = [...state.contextMenuButtonItems];
    final anchors = state.contextMenuAnchors;
    if (normalizedSelection(selectedText).isNotEmpty) {
      buttons.insert(
          0,
          ContextMenuButtonItem(
              label: 'Translate'.tr(),
              onPressed: () {
                state.hideToolbar();
                translateText(selectedText, anchors.primaryAnchor);
              }));
    }
    buttons.addAll(WordTranslationLanguage.values.map((language) => ContextMenuButtonItem(
        label: language.label.tr(),
        onPressed: () {
          changeLanguage(language);
          state.hideToolbar();
        })));
    return AdaptiveTextSelectionToolbar.buttonItems(anchors: anchors, buttonItems: buttons);
  }

  @override
  Widget build(BuildContext context) => SelectionArea(
      onSelectionChanged: (content) => selectedText = content?.plainText ?? '',
      contextMenuBuilder: selectionMenu,
      child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: removeTranslationOverlay,
          child: widget.child));
}
