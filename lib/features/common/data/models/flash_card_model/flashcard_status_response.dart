class FlashcardStatusResponse {
  final String? back;
  final String status;
  final bool? isAnswered;

  const FlashcardStatusResponse({
    required this.back,
    required this.status,
    required this.isAnswered,
  });

  factory FlashcardStatusResponse.fromJson(Map<String, dynamic> json) => FlashcardStatusResponse(
        back: json['back']?.toString(),
        status: json['status']?.toString() ?? '',
        isAnswered: _toBoolOrNull(json['is_answered'] ?? json['isAnswered']),
      );

  static bool? _toBoolOrNull(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final text = value.toString().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }
}
