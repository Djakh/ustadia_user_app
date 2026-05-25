import 'package:dio/dio.dart';

enum WordTranslationLanguage {
  uzbek('uz'),
  russian('ru');

  final String code;

  const WordTranslationLanguage(this.code);
}

class WordTranslationService {
  final Dio dio;
  final Map<String, String> _cache = {};

  WordTranslationService({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
                baseUrl: 'https://translate.googleapis.com',
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 8),
                responseType: ResponseType.json));

  Future<String> translateWord(String word, WordTranslationLanguage language) async {
    final normalized = word.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    final cacheKey = '${language.code}:$normalized';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final response = await dio.get('/translate_a/single', queryParameters: {
      'client': 'gtx',
      'sl': 'en',
      'tl': language.code,
      'dt': 't',
      'q': normalized,
    });
    final translated = _readTranslatedText(response.data).trim();
    if (translated.isEmpty) return normalized;
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
