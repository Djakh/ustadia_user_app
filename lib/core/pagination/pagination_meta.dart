class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationMeta({this.page = 1, this.limit = 10, this.total = 0, this.totalPages = 1});

  bool get hasNext => page < totalPages;

  PaginationMeta copyWith({int? page, int? limit, int? total, int? totalPages}) => PaginationMeta(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages);

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final limit = _toInt(json['limit'], fallback: 10);
    final total = _toInt(json['total']);
    final totalPages =
        _toInt(json['totalPages'], fallback: limit == 0 ? 1 : (total / limit).ceil());
    return PaginationMeta(
        page: _toInt(json['page'], fallback: 1),
        limit: limit,
        total: total,
        totalPages: totalPages == 0 ? 1 : totalPages);
  }

  static int _toInt(dynamic value, {int fallback = 0}) {

    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
