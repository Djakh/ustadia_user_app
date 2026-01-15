import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';

class PaginationResult<T> {
  final List<T> items;
  final PaginationMeta meta;

  const PaginationResult({required this.items, required this.meta});
}
