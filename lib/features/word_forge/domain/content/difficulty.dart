import 'package:equatable/equatable.dart';

/// CEFR-like metadata attached to content. Used for display and filtering;
/// gameplay balancing uses the internal [DegreeRange] instead.
enum CefrLevel {
  a1,
  a2,
  b1,
  b2,
  c1;

  String get label => name.toUpperCase();

  static CefrLevel parse(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    return CefrLevel.values.firstWhere((level) => level.name == value, orElse: () => CefrLevel.a1);
  }
}

/// Inclusive range of internal difficulty degrees (1 = very common A1 words).
class DegreeRange extends Equatable {
  final int min;
  final int max;

  const DegreeRange(this.min, this.max) : assert(min <= max);

  const DegreeRange.single(int degree)
      : min = degree,
        max = degree;

  bool contains(int degree) => degree >= min && degree <= max;

  /// Widens the range by [by] degrees on both sides (never below 1).
  DegreeRange widen([int by = 1]) => DegreeRange((min - by).clamp(1, min), max + by);

  factory DegreeRange.fromJson(Object? json) {
    if (json is List && json.length == 2) {
      final a = (json[0] as num).toInt();
      final b = (json[1] as num).toInt();
      return a <= b ? DegreeRange(a, b) : DegreeRange(b, a);
    }
    if (json is num) return DegreeRange.single(json.toInt());
    throw FormatException('Invalid degree range: $json');
  }

  List<int> toJson() => [min, max];

  @override
  List<Object?> get props => [min, max];

  @override
  String toString() => 'Degree($min-$max)';
}
