import 'package:dio/dio.dart';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

enum WordTranslationLanguage {
  uzbek('uz'),
  russian('ru');

  final String code;

  const WordTranslationLanguage(this.code);

  String get label => switch (this) {
        WordTranslationLanguage.uzbek => 'Uzbek',
        WordTranslationLanguage.russian => 'Russian',
      };

  static WordTranslationLanguage fromLocale(String languageCode) =>
      languageCode.toLowerCase().startsWith('ru')
          ? WordTranslationLanguage.russian
          : WordTranslationLanguage.uzbek;
}

class WordTranslationPreferences {
  WordTranslationPreferences._();

  static final ValueNotifier<WordTranslationLanguage> language =
      ValueNotifier<WordTranslationLanguage>(WordTranslationLanguage.uzbek);
}

class WordTranslationService {
  static const int maxTextLength = 500;

  final Dio dio;
  final Map<String, String> _cache = {};

  WordTranslationService({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
                baseUrl: 'https://translate.googleapis.com',
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 8),
                responseType: ResponseType.json));

  Future<String> translateWord(String word, WordTranslationLanguage language) =>
      translateText(word, language);

  Future<String> translateText(String text, WordTranslationLanguage language) async {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return '';
    final limited = normalized.characters.take(maxTextLength).join();
    final cacheKey = '${language.code}:${limited.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final response = await dio.get('/translate_a/single', queryParameters: {
      'client': 'gtx',
      'sl': 'en',
      'tl': language.code,
      'dt': 't',
      'q': limited,
    });
    final translated = _readTranslatedText(response.data).trim();
    if (translated.isEmpty) return limited;
    _cache[cacheKey] = translated;
    return translated;
  }

  String _readTranslatedText(dynamic data) {
    if (data is! List || data.isEmpty) return '';
    final translations = data.first;
    if (translations is! List) return '';
    return translations
        .whereType<List>()
        .map((item) => item.isNotEmpty ? item.first?.toString() ?? '' : '')
        .where((item) => item.isNotEmpty)
        .join();
  }
}
