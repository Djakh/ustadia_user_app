class ReelUploadModel {
  final String id;
  final String url;
  final String path;
  final String mimetype;
  final String filename;

  const ReelUploadModel({
    required this.id,
    required this.url,
    required this.path,
    required this.mimetype,
    required this.filename,
  });

  factory ReelUploadModel.fromJson(Map<String, dynamic> json) => ReelUploadModel(
        id: json['id']?.toString() ?? json['upload_id']?.toString() ?? '',
        url: json['url']?.toString() ??
            json['file_url']?.toString() ??
            json['fileUrl']?.toString() ??
            '',
        path: json['path']?.toString() ?? json['file_path']?.toString() ?? '',
        mimetype: json['mimetype']?.toString() ?? json['mimeType']?.toString() ?? '',
        filename: json['filename']?.toString() ?? json['originalName']?.toString() ?? '',
      );

  String get mediaPath => url.isNotEmpty ? url : path;
}

class ReelAuthorModel {
  final String id;
  final String firstName;
  final String lastName;
  final String profilePictureUrl;

  const ReelAuthorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePictureUrl,
  });

  factory ReelAuthorModel.fromJson(Map<String, dynamic> json) {
    final profilePicture = json['profilePicture'] ?? json['profile_picture'];
    final profilePictureUrl = profilePicture is Map
        ? profilePicture['url']?.toString() ?? ''
        : profilePicture?.toString() ?? json['profilePictureUrl']?.toString() ?? '';
    return ReelAuthorModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? json['first_name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? json['last_name']?.toString() ?? '',
      profilePictureUrl: profilePictureUrl,
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Ustadia' : name;
  }
}

class ReelCommentModel {
  final String id;
  final String text;
  final DateTime? createdAt;
  final String parentCommentId;
  final ReelAuthorModel? author;
  final List<ReelCommentModel> replies;

  const ReelCommentModel({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.parentCommentId,
    required this.author,
    required this.replies,
  });

  factory ReelCommentModel.fromJson(Map<String, dynamic> json) => ReelCommentModel(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        parentCommentId:
            json['parent_comment_id']?.toString() ?? json['parentCommentId']?.toString() ?? '',
        author: _mapFrom(json['author'] ?? json['user']) == null
            ? null
            : ReelAuthorModel.fromJson(_mapFrom(json['author'] ?? json['user'])!),
        replies: _listFrom(json['replies'])
            .whereType<Map<String, dynamic>>()
            .map(ReelCommentModel.fromJson)
            .toList(),
      );
}

class ReelPostModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime? createdAt;
  final ReelAuthorModel? author;
  final ReelUploadModel? mediaUpload;
  final List<ReelUploadModel> images;
  final List<ReelCommentModel> comments;

  const ReelPostModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
    required this.author,
    required this.mediaUpload,
    required this.images,
    required this.comments,
  });

  factory ReelPostModel.fromJson(Map<String, dynamic> json) {
    final mediaJson = _mapFrom(json['mediaUpload'] ?? json['media_upload'] ?? json['media']);
    final imageItems = _listFrom(json['images'] ?? json['imageUploads'] ?? json['image_uploads']);
    final comments = _listFrom(json['comments'])
        .whereType<Map<String, dynamic>>()
        .map(ReelCommentModel.fromJson)
        .toList();
    final commentsCount = _intFrom(
      json['comments_count'] ?? json['commentsCount'],
      fallback: comments.length,
    );
    return ReelPostModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'video',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      viewsCount: _intFrom(json['views_count'] ?? json['viewsCount']),
      likesCount: _intFrom(json['likes_count'] ?? json['likesCount']),
      commentsCount: commentsCount,
      isLiked: _boolFrom(json['is_liked'] ?? json['isLiked'] ?? json['liked']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      author: _mapFrom(json['author'] ?? json['user']) == null
          ? null
          : ReelAuthorModel.fromJson(_mapFrom(json['author'] ?? json['user'])!),
      mediaUpload: mediaJson == null ? null : ReelUploadModel.fromJson(mediaJson),
      images: imageItems.whereType<Map<String, dynamic>>().map((item) {
        final upload = _mapFrom(item['upload']);
        return ReelUploadModel.fromJson(upload ?? item);
      }).toList(),
      comments: comments,
    );
  }

  bool get isVideo => type.toLowerCase() == 'video';

  String get videoPath => mediaUpload?.mediaPath ?? '';

  String get primaryImagePath => images.isEmpty ? '' : images.first.mediaPath;

  ReelPostModel copyWith({
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    List<ReelCommentModel>? comments,
  }) =>
      ReelPostModel(
        id: id,
        type: type,
        title: title,
        description: description,
        viewsCount: viewsCount ?? this.viewsCount,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        isLiked: isLiked ?? this.isLiked,
        createdAt: createdAt,
        author: author,
        mediaUpload: mediaUpload,
        images: images,
        comments: comments ?? this.comments,
      );
}

Map<String, dynamic>? _mapFrom(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
  return null;
}

List<dynamic> _listFrom(dynamic value) => value is List ? value : const [];

int _intFrom(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

bool _boolFrom(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
