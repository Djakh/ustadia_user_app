enum IntroSurveyQuestionType {
  single,
  multiple,
}

class IntroSurveyAnswerModel {
  final String id;
  final String text;
  final int sortOrder;

  const IntroSurveyAnswerModel({
    required this.id,
    required this.text,
    required this.sortOrder
  });

  factory IntroSurveyAnswerModel.fromJson(Map<String, dynamic> json) => IntroSurveyAnswerModel(
      id: json['id']?.toString() ?? '',
      text: json['answer_text']?.toString() ?? '',
      sortOrder: json['sort_order'] is int ? json['sort_order'] as int : 0
    );
}

class IntroSurveyQuestionModel {
  final String id;
  final String description;
  final IntroSurveyQuestionType type;
  final int sortOrder;
  final List<IntroSurveyAnswerModel> answers;

  const IntroSurveyQuestionModel({
    required this.id,
    required this.description,
    required this.type,
    required this.sortOrder,
    required this.answers
  });

  factory IntroSurveyQuestionModel.fromJson(Map<String, dynamic> json) {
    final answersJson = json['answers'] as List<dynamic>? ?? [];
    final answers = answersJson
        .whereType<Map<String, dynamic>>()
        .map(IntroSurveyAnswerModel.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return IntroSurveyQuestionModel(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: introSurveyQuestionTypeFromString(json['type']?.toString() ?? ''),
      sortOrder: json['sort_order'] is int ? json['sort_order'] as int : 0,
      answers: answers
    );
  }
}

IntroSurveyQuestionType introSurveyQuestionTypeFromString(String value) {
  if (value.toLowerCase() == 'multiple') return IntroSurveyQuestionType.multiple;
  return IntroSurveyQuestionType.single;
}
