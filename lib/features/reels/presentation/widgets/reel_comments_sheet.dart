import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reels_bloc/reels_state.dart';

class ReelCommentsSheet extends StatefulWidget {
  final ReelPostModel post;
  final ReelsState state;
  final String Function(String path) resolveUrl;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onSubmit;

  const ReelCommentsSheet({
    super.key,
    required this.post,
    required this.state,
    required this.resolveUrl,
    required this.onRetry,
    required this.onLoadMore,
    required this.onSubmit,
  });

  @override
  State<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<ReelCommentsSheet> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool get isSending =>
      widget.state.actionStatus.isLoading && widget.state.actionPostId == widget.post.id;

  bool get isLoadingComments =>
      widget.state.commentsStatus.isLoading &&
      widget.state.commentsPostId == widget.post.id &&
      widget.post.comments.isEmpty;

  bool get isLoadingMore =>
      widget.state.isLoadingMoreComments && widget.state.commentsPostId == widget.post.id;

  bool get hasCommentsError =>
      widget.state.commentsStatus.isError &&
      widget.state.commentsPostId == widget.post.id &&
      widget.state.commentsErrorMessage != null;

  bool get canLoadMore => widget.state.hasMoreComments(widget.post.id) && !isLoadingMore;

  void onScroll(ScrollNotification notification) {
    if (!canLoadMore || notification.metrics.maxScrollExtent <= 0) return;
    final remaining = notification.metrics.maxScrollExtent - notification.metrics.pixels;
    if (remaining < 120) widget.onLoadMore();
  }

  void submit() {
    final text = controller.text.trim();
    if (text.isEmpty || isSending) return;
    widget.onSubmit(text);
    controller.clear();
  }

  Widget commentTile(BuildContext context, ReelCommentModel comment, {bool isReply = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            UserAvatar(
                radius: isReply ? 14 : 17,
                imageUrl: widget.resolveUrl(comment.author?.profilePictureUrl ?? '')),
            const SizedBox(width: 10),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(comment.author?.fullName ?? 'Ustadia'.tr(), style: Style.small3w5(context)),
              const SizedBox(height: 2),
              Text(comment.text, style: Style.small3w4(context))
            ]))
          ]));

  Widget commentWithReplies(BuildContext context, ReelCommentModel comment) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        commentTile(context, comment),
        if (comment.replies.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Column(
                  children: comment.replies
                      .map((reply) => commentTile(context, reply, isReply: true))
                      .toList()))
      ]);

  Widget get emptyState => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Text('No comments yet'.tr(),
              style: Style.bodyw4(context, color: TextColorRole.greyColor))));

  Widget get loadingState => const Center(child: PrimaryLoadingIndicator(height: 28, width: 28));

  Widget errorState(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.state.commentsErrorMessage ?? 'Failed to load comments'.tr(),
                textAlign: TextAlign.center,
                style: Style.bodyw4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 12),
            TextButton(onPressed: widget.onRetry, child: Text('Retry'.tr()))
          ])));

  Widget footer(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: PrimaryLoadingIndicator(height: 24, width: 24)));
    }
    if (hasCommentsError && widget.post.comments.isNotEmpty) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:
              Center(child: TextButton(onPressed: widget.onLoadMore, child: Text('Retry'.tr()))));
    }
    if (widget.state.hasMoreComments(widget.post.id)) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(
              child: TextButton(onPressed: widget.onLoadMore, child: Text('Load more'.tr()))));
    }
    return const SizedBox(height: 8);
  }

  Widget commentsList(BuildContext context, ScrollController scrollController) {
    final comments = widget.state.commentsForPost(widget.post);
    if (isLoadingComments) return loadingState;
    if (hasCommentsError && comments.isEmpty) return errorState(context);
    if (comments.isEmpty) return emptyState;
    return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          onScroll(notification);
          return false;
        },
        child: ListView.builder(
            controller: scrollController,
            itemCount: comments.length + 1,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            itemBuilder: (context, index) {
              if (index == comments.length) return footer(context);
              return commentWithReplies(context, comments[index]);
            }));
  }

  Widget inputBox(BuildContext context) => SafeArea(
      top: false,
      child: Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
          child: Row(children: [
            Expanded(
                child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                        hintText: 'Add a comment'.tr(),
                        filled: true,
                        fillColor: AppColors.gray50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: Style.border16,
                            borderSide: const BorderSide(color: AppColors.gray100)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: Style.border16,
                            borderSide: const BorderSide(color: AppColors.gray100))))),
            const SizedBox(width: 10),
            IconButton(
                onPressed: isSending ? null : submit,
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.gray200),
                icon: const Icon(Icons.send_rounded, color: AppColors.white))
          ])));

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(children: [
            const SizedBox(height: 8),
            Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: AppColors.gray300, borderRadius: Style.border4)),
            const SizedBox(height: 12),
            Text('Comments'.tr(), style: Style.body2w6(context)),
            const SizedBox(height: 8),
            Expanded(child: commentsList(context, scrollController)),
            inputBox(context)
          ]));
}
