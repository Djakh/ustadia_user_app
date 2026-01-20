class FlashcardStatusResponse {
  final String? back;
  final String status;

  const FlashcardStatusResponse({required this.back, required this.status});

  factory FlashcardStatusResponse.fromJson(Map<String, dynamic> json) =>
      FlashcardStatusResponse(
        back: json['back']?.toString(),
        status: json['status']?.toString() ?? '',
      );
}
