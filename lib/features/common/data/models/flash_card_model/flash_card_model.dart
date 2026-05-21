class LearnFlashcardModel {
  final String id;
  final String front;
  final String? back;
  final int order;
  final String status;
  final bool? isAnswered;

  const LearnFlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    required this.order,
    required this.status,
    this.isAnswered,
  });

  factory LearnFlashcardModel.fromJson(Map<String, dynamic> json) => LearnFlashcardModel(
        id: json['id']?.toString() ?? '',
        front: json['front']?.toString() ?? '',
        back: json['back']?.toString(),
        order: _toInt(json['order'] ?? json['order_index']),
        status: json['status']?.toString() ?? '',
        isAnswered: _toBoolOrNull(json['is_answered'] ?? json['isAnswered']),
      );

  LearnFlashcardModel copyWith({
    String? id,
    String? front,
    Object? back = _unset,
    int? order,
    String? status,
    Object? isAnswered = _unset,
  }) =>
      LearnFlashcardModel(
        id: id ?? this.id,
        front: front ?? this.front,
        back: identical(back, _unset) ? this.back : back as String?,
        order: order ?? this.order,
        status: status ?? this.status,
        isAnswered: identical(isAnswered, _unset) ? this.isAnswered : isAnswered as bool?,
      );

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool? _toBoolOrNull(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final text = value.toString().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }
}

const _unset = Object();
