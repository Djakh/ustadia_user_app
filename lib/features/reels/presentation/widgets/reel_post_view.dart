import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/cached_images_primary/cached_image_primary.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';
import 'package:ustadia_user_app/features/reels/presentation/widgets/reel_action_button.dart';
import 'package:ustadia_user_app/features/reels/presentation/widgets/reel_video_player.dart';

class ReelPostView extends StatelessWidget {
  final ReelPostModel post;
  final bool isActive;
  final bool shouldPreload;
  final Duration? initialPosition;
  final ValueChanged<Duration>? onPositionChanged;
  final ReelVideoControllerCache controllerCache;
  final String Function(String path) resolveUrl;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback? onAuthorTap;

  const ReelPostView({
    super.key,
    required this.post,
    required this.isActive,
    this.shouldPreload = true,
    this.initialPosition,
    this.onPositionChanged,
    required this.controllerCache,
    required this.resolveUrl,
    required this.onLike,
    required this.onComments,
    this.onAuthorTap,
  });

  String countLabel(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  /// The reels service exposes an optimized streaming endpoint by appending
  /// `/stream` to the uploaded file URL. Keep query parameters and fragments
  /// intact when building that URL.
  String streamUrl(String url) {
    if (url.isEmpty) return url;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.path.endsWith('/stream')) return url;
    final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    return uri.replace(path: '$path/stream').toString();
  }

  Widget get mediaView {
    if (post.isVideo) {
      final originalVideoUrl = resolveUrl(post.videoPath);
      return ReelVideoPlayer(
          videoUrl: streamUrl(originalVideoUrl),
          fallbackVideoUrl: originalVideoUrl,
          placeholderUrl: post.primaryImagePath.isEmpty ? null : resolveUrl(post.primaryImagePath),
          isActive: isActive,
          initialPosition: initialPosition,
          onPositionChanged: onPositionChanged,
          controllerCache: controllerCache,
          shouldInitialize: shouldPreload);
    }
    return CachedImagePrimary(
        imageUrl: resolveUrl(post.primaryImagePath),
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover);
  }

  Widget gradientOverlay() => const DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0x00000000), Color(0xCC000000)],
              stops: [0, 0.38, 1])));

  Widget authorRow(BuildContext context) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAuthorTap,
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
                shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 1.2)),
            child:
                UserAvatar(radius: 17, imageUrl: resolveUrl(post.author?.profilePictureUrl ?? ''))),
        const SizedBox(width: 10),
        Expanded(
            child: Text(post.author?.fullName ?? 'Ustadia',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Style.bodyw6(context).copyWith(color: AppColors.white)))
      ]));

  Widget info(BuildContext context) => Positioned(
      left: 16,
      right: 86,
      bottom: 12,
      child: SafeArea(
          top: false,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                authorRow(context),
                if (post.title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Style.body2w7(context).copyWith(color: AppColors.white))
                ],
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(post.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Style.small3w4(context).copyWith(color: AppColors.white))
                ],
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.visibility_rounded, color: AppColors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(countLabel(post.viewsCount),
                      style: Style.small2w5(context).copyWith(color: AppColors.white))
                ])
              ])));

  Widget actions(BuildContext context) => Positioned(
      right: 14,
      bottom: 14,
      child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ReelActionButton(
                icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: post.isLiked ? AppColors.error : AppColors.white,
                label: countLabel(post.likesCount),
                onTap: onLike),
            ReelActionButton(
                icon: Icons.mode_comment_outlined,
                label: countLabel(post.commentsCount),
                onTap: onComments)
          ])));

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: GestureDetector(
          onDoubleTap: onLike,
          child: Stack(fit: StackFit.expand, children: [
            mediaView,
            IgnorePointer(child: gradientOverlay()),
            info(context),
            actions(context),
          ])));
}
