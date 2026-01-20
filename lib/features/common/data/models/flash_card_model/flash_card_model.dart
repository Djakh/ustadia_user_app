class LearnFlashcardModel {
  final String id;
  final String front;
  final String? back;
  final int order;
  final String status;

  const LearnFlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    required this.order,
    required this.status,
  });

  factory LearnFlashcardModel.fromJson(Map<String, dynamic> json) => LearnFlashcardModel(
        id: json['id']?.toString() ?? '',
        front: json['front']?.toString() ?? '',
        back: json['back']?.toString(),
        order: json['order'],
        status: json['status']?.toString() ?? '',
      );
}
