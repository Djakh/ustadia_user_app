import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_url_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HtmlVideoPlayerParams {
  final String url;
  final String title;

  const HtmlVideoPlayerParams({required this.url, this.title = ''});
}

class HtmlVideoPlayerPage extends StatefulWidget {
  final HtmlVideoPlayerParams params;

  const HtmlVideoPlayerPage({super.key, required this.params});

  @override
  State<HtmlVideoPlayerPage> createState() => _HtmlVideoPlayerPageState();
}

class _HtmlVideoPlayerPageState extends State<HtmlVideoPlayerPage> with WidgetsBindingObserver {
  static const Duration seekStep = Duration(seconds: 5);

  VideoPlayerController? directController;
  YoutubePlayerController? youtubeController;
  bool hasError = false;
  String errorMessage = '';
  bool wasPlayingBeforePause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializePlayer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    directController?.dispose();
    youtubeController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      pauseForLifecycle();
      return;
    }
    if (state == AppLifecycleState.resumed) resumeAfterLifecycle();
  }

  String get url => widget.params.url.trim();
  String get title =>
      widget.params.title.trim().isEmpty ? 'Video'.tr() : widget.params.title.trim();
  bool get isYoutube => HtmlVideoUrlUtils.isYoutubeUrl(url);

  Future<void> initializePlayer() async {
    if (url.isEmpty) {
      setError('Video URL is empty'.tr());
      return;
    }
    if (isYoutube) {
      initializeYoutubePlayer();
      return;
    }
    await initializeDirectPlayer();
  }

  void initializeYoutubePlayer() {
    final videoId = HtmlVideoUrlUtils.youtubeVideoId(url);
    if (videoId == null || videoId.isEmpty) {
      setError('Video is not available'.tr());
      return;
    }
    youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
            autoPlay: true, controlsVisibleAtStart: true, enableCaption: true));
    if (mounted) setState(() {});
  }

  Future<void> initializeDirectPlayer() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    directController = controller;
    try {
      await controller.initialize();
      await controller.play();
      if (mounted) setState(() {});
    } catch (error) {
      await controller.dispose();
      directController = null;
      setError(error.toString());
    }
  }

  void setError(String message) {
    if (!mounted) return;
    setState(() {
      hasError = true;
      errorMessage = message;
    });
  }

  void pauseForLifecycle() {
    final directPlayer = directController;
    if (directPlayer != null && directPlayer.value.isInitialized) {
      wasPlayingBeforePause = directPlayer.value.isPlaying;
      directPlayer.pause();
      return;
    }
    final youtubePlayer = youtubeController;
    if (youtubePlayer != null) {
      wasPlayingBeforePause = youtubePlayer.value.isPlaying;
      youtubePlayer.pause();
    }
  }

  void resumeAfterLifecycle() {
    if (!wasPlayingBeforePause) return;
    directController?.play();
    youtubeController?.play();
    wasPlayingBeforePause = false;
  }

  void pausePlayers() {
    directController?.pause();
    youtubeController?.pause();
  }

  void closePage() {
    pausePlayers();
    Navigator.of(context).pop();
  }

  void toggleDirectPlayback(VideoPlayerController controller) {
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  void seekDirect(VideoPlayerController controller, Duration offset) {
    final value = controller.value;
    final duration = value.duration;
    final target = value.position + offset;
    final clampedTarget = target < Duration.zero
        ? Duration.zero
        : target > duration
            ? duration
            : target;
    unawaited(controller.seekTo(clampedTarget));
  }

  void toggleYoutubePlayback(YoutubePlayerController controller) {
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  void seekYoutube(YoutubePlayerController controller, Duration offset) {
    final duration = controller.metadata.duration;
    final target = controller.value.position + offset;
    final clampedTarget = target < Duration.zero
        ? Duration.zero
        : duration > Duration.zero && target > duration
            ? duration
            : target;
    controller.seekTo(clampedTarget);
  }

  String durationText(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  Widget iconCircleButton({required IconData icon, required VoidCallback onTap}) => InkWell(
      onTap: onTap,
      borderRadius: Style.border95,
      child: Ink(
          width: 46,
          height: 46,
          decoration:
              BoxDecoration(color: AppColors.white.withValues(alpha: 0.10), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.white, size: 25)));

  Widget get closeButton => InkWell(
      onTap: closePage,
      borderRadius: Style.border95,
      child: Ink(
          width: 44,
          height: 44,
          decoration:
              BoxDecoration(color: AppColors.white.withValues(alpha: 0.10), shape: BoxShape.circle),
          child: const Icon(Icons.close_rounded, color: AppColors.white, size: 26)));

  Widget get topBar => SafeArea(
      bottom: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            closeButton,
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Style.bodyw6(context, color: TextColorRole.whiteColor)))
          ])));

  Widget get loading => const Center(child: PrimaryLoadingIndicator(height: 34, width: 34));

  Widget get errorView => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.play_disabled_rounded, color: AppColors.white, size: 52),
            const SizedBox(height: 12),
            Text('Video is not available'.tr(),
                textAlign: TextAlign.center,
                style: Style.bodyw6(context, color: TextColorRole.whiteColor)),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(errorMessage,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Style.small3w4(context).copyWith(color: AppColors.gray300))
            ]
          ])));

  Widget directControls(VideoPlayerController controller) =>
      ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, child) => SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    VideoProgressIndicator(controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                            playedColor: AppColors.primary,
                            bufferedColor: AppColors.gray500,
                            backgroundColor: AppColors.gray700),
                        padding: const EdgeInsets.symmetric(vertical: 10)),
                    Row(children: [
                      Text(durationText(value.position),
                          style: Style.small3w5(context, color: TextColorRole.whiteColor)),
                      const Spacer(),
                      Text(durationText(value.duration),
                          style: Style.small3w5(context).copyWith(color: AppColors.gray300))
                    ]),
                    const SizedBox(height: 18),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      iconCircleButton(
                          icon: Icons.replay_5_rounded,
                          onTap: () => seekDirect(controller, -seekStep)),
                      const SizedBox(width: 24),
                      iconCircleButton(
                          icon: value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          onTap: () => toggleDirectPlayback(controller)),
                      const SizedBox(width: 24),
                      iconCircleButton(
                          icon: Icons.forward_5_rounded,
                          onTap: () => seekDirect(controller, seekStep))
                    ])
                  ]))));

  Widget directPlayerView(VideoPlayerController controller) => Column(children: [
        Expanded(
            child: Center(
                child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)))),
        directControls(controller)
      ]);

  Widget youtubeControls(YoutubePlayerController controller) =>
      ValueListenableBuilder<YoutubePlayerValue>(
          valueListenable: controller,
          builder: (context, value, child) => SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Text(durationText(value.position),
                          style: Style.small3w5(context, color: TextColorRole.whiteColor)),
                      const Spacer(),
                      Text(durationText(controller.metadata.duration),
                          style: Style.small3w5(context).copyWith(color: AppColors.gray300))
                    ]),
                    const SizedBox(height: 18),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      iconCircleButton(
                          icon: Icons.replay_5_rounded,
                          onTap: () => seekYoutube(controller, -seekStep)),
                      const SizedBox(width: 24),
                      iconCircleButton(
                          icon: value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          onTap: () => toggleYoutubePlayback(controller)),
                      const SizedBox(width: 24),
                      iconCircleButton(
                          icon: Icons.forward_5_rounded,
                          onTap: () => seekYoutube(controller, seekStep))
                    ])
                  ]))));

  Widget youtubePlayerView(YoutubePlayerController controller) => Column(children: [
        Expanded(
            child: Center(
                child: YoutubePlayer(
                    controller: controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppColors.primary,
                    progressColors: const ProgressBarColors(
                        playedColor: AppColors.primary,
                        handleColor: AppColors.primary,
                        bufferedColor: AppColors.gray500,
                        backgroundColor: AppColors.gray700)))),
        youtubeControls(controller)
      ]);

  Widget get content {
    if (hasError) return errorView;
    final youtubePlayer = youtubeController;
    if (youtubePlayer != null) return youtubePlayerView(youtubePlayer);
    final directPlayer = directController;
    if (directPlayer == null || !directPlayer.value.isInitialized) return loading;
    return directPlayerView(directPlayer);
  }

  @override
  Widget build(BuildContext context) => PopScope(
      onPopInvokedWithResult: (didPop, result) => pausePlayers(),
      child: Scaffold(
          backgroundColor: AppColors.black,
          body: Stack(children: [
            Positioned.fill(
                child: Padding(padding: const EdgeInsets.only(top: 72), child: content)),
            Positioned(top: 0, left: 0, right: 0, child: topBar)
          ])));
}
