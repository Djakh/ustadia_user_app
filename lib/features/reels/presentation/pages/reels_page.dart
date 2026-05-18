import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/network/api_url_resolver.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reels_bloc/reels_bloc.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reels_bloc/reels_event.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reels_bloc/reels_state.dart';
import 'package:ustadia_user_app/features/reels/presentation/widgets/reel_comments_sheet.dart';
import 'package:ustadia_user_app/features/reels/presentation/widgets/reel_post_view.dart';
import 'package:ustadia_user_app/injection_container.dart';

class ReelsPageParams {
  final List<ReelPostModel> initialPosts;
  final int initialIndex;
  final String title;

  const ReelsPageParams({
    required this.initialPosts,
    this.initialIndex = 0,
    this.title = 'Reels',
  });
}

class ReelsPage extends StatefulWidget {
  final ReelsPageParams? params;

  const ReelsPage({super.key, this.params});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> with WidgetsBindingObserver {
  final ReelsBloc reelsBloc = sl<ReelsBloc>();
  late final PageController pageController;
  int activeIndex = 0;
  bool playbackAllowed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    activeIndex = widget.params?.initialIndex ?? 0;
    pageController = PageController(initialPage: activeIndex);
    if (widget.params?.initialPosts.isNotEmpty ?? false) {
      reelsBloc.add(ReelsSeeded(posts: widget.params!.initialPosts));
    } else {
      reelsBloc.add(const ReelsRequested());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    reelsBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldPlay = state == AppLifecycleState.resumed;
    if (playbackAllowed == shouldPlay) return;
    setState(() => playbackAllowed = shouldPlay);
  }

  String resolveMediaUrl(String path) =>
      resolveApiAssetUrl(path, baseUrl: sl<AuthRemoteDataSource>().dio.options.baseUrl);

  Future<void> reloadReels() async {
    setState(() {
      activeIndex = 0;
      playbackAllowed = false;
    });
    if (widget.params?.initialPosts.isNotEmpty ?? false) {
      reelsBloc.add(ReelsSeeded(posts: widget.params!.initialPosts));
    } else {
      reelsBloc.add(const ReelsRequested());
    }
  }

  void onPageChanged(int index, List<ReelPostModel> posts, ReelsState state) {
    setState(() => activeIndex = index);
    if (state.pagination.hasNext && index >= posts.length - 3) {
      reelsBloc.add(const ReelsLoadMoreRequested());
    }
  }

  void showComments(ReelPostModel post) {
    reelsBloc.add(ReelCommentsRequested(postId: post.id));
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cs.surface,
        shape: RoundedRectangleBorder(borderRadius: Style.borderVer24),
        builder: (_) => BlocBuilder<ReelsBloc, ReelsState>(
            bloc: reelsBloc,
            builder: (context, currentState) {
              final currentPost =
                  currentState.posts.firstWhere((item) => item.id == post.id, orElse: () => post);
              return ReelCommentsSheet(
                  post: currentPost,
                  state: currentState,
                  resolveUrl: resolveMediaUrl,
                  onRetry: () => reelsBloc.add(ReelCommentsRequested(postId: currentPost.id)),
                  onLoadMore: () =>
                      reelsBloc.add(ReelCommentsLoadMoreRequested(postId: currentPost.id)),
                  onSubmit: (text) =>
                      reelsBloc.add(ReelCommentSubmitted(postId: currentPost.id, text: text)));
            }));
  }

  void openAuthorProfile(ReelPostModel post) {
    final author = post.author;
    if (author == null || author.id.isEmpty) return;
    context.push('/reels/user/${Uri.encodeComponent(author.id)}', extra: author);
  }

  void listenState(BuildContext context, ReelsState state) {
    if (state.status.isSuccess && !playbackAllowed) {
      setState(() => playbackAllowed = true);
    }
    if (state.actionStatus.isError && state.actionErrorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.actionErrorMessage!)));
    }
  }

  Widget topBar(BuildContext context) => SafeArea(
      bottom: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(children: [
            IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white)),
            Text((widget.params?.title ?? 'Reels').tr(),
                style: Style.body2w7(context).copyWith(color: AppColors.white))
          ])));

  Widget reelsView(BuildContext context, List<ReelPostModel> posts, ReelsState state) =>
      RefreshIndicator(
          onRefresh: reloadReels,
          child: PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              itemCount: posts.length + (state.isLoadingMore ? 1 : 0),
              onPageChanged: (index) => onPageChanged(index, posts, state),
              itemBuilder: (context, index) {
                if (index >= posts.length) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.white));
                }
                final post = posts[index];
                return ReelPostView(
                    post: post,
                    isActive: playbackAllowed && index == activeIndex,
                    shouldPreload: (index - activeIndex).abs() <= 1,
                    resolveUrl: resolveMediaUrl,
                    onLike: () => reelsBloc.add(ReelLikeToggled(post: post)),
                    onComments: () => showComments(post),
                    onAuthorTap: () => openAuthorProfile(post));
              }));

  Widget get loadingView => Stack(children: [
        Container(color: AppColors.black),
        const Center(child: PrimaryLoadingIndicator(height: 34, width: 34)),
        Positioned(
            left: 16,
            right: 96,
            bottom: 34,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              loadingLine(width: 170, height: 18),
              const SizedBox(height: 14),
              loadingLine(width: 230, height: 28),
              const SizedBox(height: 10),
              loadingLine(width: 280, height: 14),
              const SizedBox(height: 8),
              loadingLine(width: 90, height: 14)
            ])),
        Positioned(
            right: 16,
            bottom: 40,
            child: Column(children: [loadingCircle(), const SizedBox(height: 22), loadingCircle()]))
      ]);

  Widget loadingLine({required double width, required double height}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.14), borderRadius: Style.border8));

  Widget loadingCircle() => Container(
      width: 46,
      height: 46,
      decoration:
          BoxDecoration(color: AppColors.white.withValues(alpha: 0.14), shape: BoxShape.circle));

  Widget get contentChecker => BlocStatusView<ReelsBloc, ReelsState, List<ReelPostModel>>(
      bloc: reelsBloc,
      statusOf: (state) => state.status,
      errorOf: (state) => state.errorMessage,
      data: (state) => state.posts,
      isEmpty: (posts) => posts.isEmpty,
      keepDataOnLoading: true,
      loading: loadingView,
      empty: Center(
          child: Text('No reels yet'.tr(),
              style: Style.bodyw5(context).copyWith(color: AppColors.white))),
      builder: (context, posts) => reelsView(context, posts, reelsBloc.state));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.black,
      body: BlocConsumer<ReelsBloc, ReelsState>(
          bloc: reelsBloc,
          listener: listenState,
          builder: (context, state) => Stack(children: [contentChecker, topBar(context)])));
}
