import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/compliance/report_reason_dialog.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/network/api_url_resolver.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/cached_images_primary/cached_image_primary.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reel_user_profile_bloc/reel_user_profile_bloc.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reel_user_profile_bloc/reel_user_profile_event.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reel_user_profile_bloc/reel_user_profile_state.dart';
import 'package:ustadia_user_app/features/reels/presentation/pages/reels_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/profile_image_view_page.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class ReelUserProfilePage extends StatefulWidget {
  final String userId;
  final ReelAuthorModel? initialAuthor;

  const ReelUserProfilePage({super.key, required this.userId, this.initialAuthor});

  @override
  State<ReelUserProfilePage> createState() => _ReelUserProfilePageState();
}

class _ReelUserProfilePageState extends State<ReelUserProfilePage> {
  final ReelUserProfileBloc profileBloc = sl<ReelUserProfileBloc>();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
    profileBloc.add(ReelUserProfileRequested(userId: widget.userId));
  }

  @override
  void dispose() {
    scrollController.removeListener(onScroll);
    scrollController.dispose();
    profileBloc.close();
    super.dispose();
  }

  String resolveMediaUrl(String path) =>
      resolveApiAssetUrl(path, baseUrl: sl<AuthRemoteDataSource>().dio.options.baseUrl);

  void onScroll() {
    if (!scrollController.hasClients || profileBloc.state.isLoadingMore) return;
    final position = scrollController.position;
    if (position.maxScrollExtent - position.pixels < 240) {
      profileBloc.add(const ReelUserProfileLoadMoreRequested());
    }
  }

  void openReel(int index, List<ReelPostModel> posts, ReelAuthorModel author) {
    context.push('/reels',
        extra: ReelsPageParams(initialPosts: posts, initialIndex: index, title: author.fullName));
  }

  void openAvatarPreview(ReelAuthorModel? user) {
    context.push(profileImageViewRoute,
        extra: ProfileImageViewParams(imageUrl: resolveMediaUrl(user?.profilePictureUrl ?? '')));
  }

  Future<void> reloadProfile() async {
    profileBloc.add(ReelUserProfileRequested(userId: widget.userId));
  }

  Future<void> reportProfile() async {
    final reason = await showReportReasonDialog(context,
        title: 'Report profile image',
        reasons: const [
          'Inappropriate image',
          'Personal information',
          'Harassment or impersonation',
          'Other'
        ]);
    if (!mounted || reason == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile reporting is not available yet. Please contact support.'.tr())));
  }

  Widget profileHeader(ReelUserProfileState state) {
    final user = state.user ?? widget.initialAuthor;
    final name = user?.fullName ?? 'Ustadia';
    return Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 18),
        child: Row(children: [
          GestureDetector(
              onTap: () => openAvatarPreview(user),
              child:
                  UserAvatar(radius: 38, imageUrl: resolveMediaUrl(user?.profilePictureUrl ?? ''))),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Style.body2w7(context)),
            const SizedBox(height: 8),
            Row(children: [
              Text(state.pagination.total.toString(), style: Style.bodyw7(context)),
              const SizedBox(width: 5),
              Text('Posts'.tr(), style: Style.small3w4(context, color: TextColorRole.greyColor))
            ])
          ])),
          IconButton(
              tooltip: 'Report profile image'.tr(),
              onPressed: reportProfile,
              icon: const Icon(Icons.flag_outlined))
        ]));
  }

  Widget videoPlaceholder(ReelPostModel post) => Container(
      color: AppColors.black,
      child: Stack(fit: StackFit.expand, children: [
        Center(
            child: Icon(Icons.play_arrow_rounded,
                color: AppColors.white.withValues(alpha: 0.88), size: 42)),
        Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Style.small2w5(context).copyWith(color: AppColors.white)))
      ]));

  Widget postTile(
      ReelPostModel post, int index, List<ReelPostModel> posts, ReelAuthorModel author) {
    final imagePath = post.primaryImagePath;
    return GestureDetector(
        onTap: () => openReel(index, posts, author),
        child: ClipRRect(
            borderRadius: Style.border8,
            child: Stack(fit: StackFit.expand, children: [
              if (!post.isVideo && imagePath.isNotEmpty)
                CachedImagePrimary(
                    imageUrl: resolveMediaUrl(imagePath),
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover)
              else
                videoPlaceholder(post),
              Positioned(
                  left: 6,
                  bottom: 6,
                  child: Row(children: [
                    const Icon(Icons.visibility_rounded, color: AppColors.white, size: 14),
                    const SizedBox(width: 3),
                    Text(post.viewsCount.toString(),
                        style: Style.small2w5(context).copyWith(color: AppColors.white))
                  ]))
            ])));
  }

  Widget postsGrid(ReelUserProfileState state, ReelAuthorModel author) => SliverGrid(
      delegate: SliverChildBuilderDelegate(
          (context, index) => postTile(state.posts[index], index, state.posts, author),
          childCount: state.posts.length),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 9 / 16));

  Widget footer(ReelUserProfileState state) {
    if (!state.isLoadingMore) return const SliverToBoxAdapter(child: SizedBox(height: 24));
    return const SliverToBoxAdapter(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: PrimaryLoadingIndicator(height: 24, width: 24)));
  }

  Widget emptyState() => SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
          child: Text('No reels yet'.tr(),
              style: Style.bodyw5(context, color: TextColorRole.greyColor))));

  Widget profileView(ReelUserProfileState state) {
    final author = state.user ?? widget.initialAuthor;
    return RefreshIndicator(
        onRefresh: reloadProfile,
        child: CustomScrollView(controller: scrollController, slivers: [
          SliverToBoxAdapter(child: profileHeader(state)),
          if (author != null && state.posts.isNotEmpty) postsGrid(state, author),
          if (state.posts.isEmpty) emptyState(),
          footer(state)
        ]));
  }

  Widget errorView(String message) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center, style: Style.bodyw4(context)),
            const SizedBox(height: 12),
            TextButton(onPressed: reloadProfile, child: Text('Retry'.tr()))
          ])));

  Widget content(ReelUserProfileState state) {
    if (state.status.isLoading && state.user == null && state.posts.isEmpty) {
      return const PrimaryLoadingIndicator(height: 30, width: 30);
    }
    if (state.status.isError && state.user == null && state.posts.isEmpty) {
      return errorView(state.errorMessage ?? 'Something went wrong'.tr());
    }
    return profileView(state);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: (widget.initialAuthor?.fullName ?? 'Profile').tr(),
          onBack: () => context.pop(),
          child: BlocBuilder<ReelUserProfileBloc, ReelUserProfileState>(
              bloc: profileBloc, builder: (context, state) => content(state))));
}
