/// Normalises English text for answer comparison.
///
/// Comparison is case-insensitive, ignores surrounding punctuation and repeated
/// whitespace, and treats typographic apostrophes like plain ones.
class TextNormalizer {
  TextNormalizer._();

  static final RegExp _apostrophes = RegExp('[‘’ʼ`]');
  static final RegExp _punctuation = RegExp(r"[^\p{L}\p{N}'\- ]", unicode: true);
  static final RegExp _spaces = RegExp(r'\s+');

  static String normalize(String input) => input
      .toLowerCase()
      .replaceAll(_apostrophes, "'")
      .replaceAll(_punctuation, ' ')
      .replaceAll(_spaces, ' ')
      .trim();

  /// Splits a sentence into word tokens, dropping punctuation such as commas
  /// and the final full stop.
  static List<String> tokenize(String sentence) =>
      normalize(sentence).split(' ').where((token) => token.isNotEmpty).toList();

  /// Returns the sentence-final punctuation mark ('.', '?' or '!'), if any.
  static String terminatorOf(String sentence) {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty) return '';
    final last = trimmed[trimmed.length - 1];
    return const {'.', '?', '!'}.contains(last) ? last : '';
  }
}
