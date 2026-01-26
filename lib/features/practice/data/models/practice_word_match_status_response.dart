class PracticeWordMatchStatusResponse {
  final String wordMatchId;
  final String status;
  final int correctAnswers;
  final int wrongAnswers;
  final String message;

  const PracticeWordMatchStatusResponse({
    required this.wordMatchId,
    required this.status,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.message,
  });

  factory PracticeWordMatchStatusResponse.fromJson(Map<String, dynamic> json) =>
      PracticeWordMatchStatusResponse(
        wordMatchId: json['wordMatchId']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        correctAnswers: _toInt(json['correctAnswers']),
        wrongAnswers: _toInt(json['wrongAnswers']),
        message: json['message']?.toString() ?? '',
      );
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? fallback;
}
