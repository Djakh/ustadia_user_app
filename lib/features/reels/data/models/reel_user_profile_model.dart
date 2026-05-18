import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/core/pagination/pagination_result.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';

class ReelUserProfileModel {
  final ReelAuthorModel user;
  final PaginationResult<ReelPostModel> feeds;

  const ReelUserProfileModel({required this.user, required this.feeds});

  factory ReelUserProfileModel.fromJson(Map<String, dynamic> json) {
    final userJson = _mapFrom(json['user']) ?? const <String, dynamic>{};
    final feedsJson = _mapFrom(json['feeds']) ?? const <String, dynamic>{};
    final items = _listFrom(feedsJson['items']);
    return ReelUserProfileModel(
        user: ReelAuthorModel.fromJson(userJson),
        feeds: PaginationResult(
            items: items.whereType<Map<String, dynamic>>().map(ReelPostModel.fromJson).toList(),
            meta: PaginationMeta.fromJson(feedsJson)));
  }
}

Map<String, dynamic>? _mapFrom(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
  return null;
}

List<dynamic> _listFrom(dynamic value) => value is List ? value : const [];
