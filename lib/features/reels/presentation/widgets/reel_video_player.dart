import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:video_player/video_player.dart';

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool shouldInitialize;

  const ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
    this.shouldInitialize = true,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> with WidgetsBindingObserver {
  VideoPlayerController? controller;
  bool hasError = false;
  String errorMessage = '';
  bool appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.shouldInitialize) initializePlayer();
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.shouldInitialize) {
      disposePlayer();
      return;
    }
    if (oldWidget.videoUrl != widget.videoUrl || !oldWidget.shouldInitialize) {
      initializePlayer();
      return;
    }
    syncPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appResumed = state == AppLifecycleState.resumed;
    syncPlayback();
  }

  Future<void> disposePlayer() async {
    final player = controller;
    controller = null;
    hasError = false;
    if (player != null) await player.dispose();
    if (mounted) setState(() {});
  }

  Future<void> initializePlayer() async {
    await controller?.dispose();
    controller = null;
    hasError = false;
    errorMessage = '';
    if (widget.videoUrl.isEmpty) {
      setState(() {
        hasError = true;
        errorMessage = 'Video URL is empty';
      });
      return;
    }
    final nextController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    controller = nextController;
    try {
      await nextController.initialize();
      await nextController.setLooping(true);
      if (widget.isActive && appResumed) await nextController.play();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = error.toString();
        });
      }
    }
  }

  void syncPlayback() {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    if (widget.isActive && appResumed && !player.value.isPlaying) {
      player.play();
    }
    if ((!widget.isActive || !appResumed) && player.value.isPlaying) {
      player.pause();
    }
  }

  void togglePlayback() {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    player.value.isPlaying ? player.pause() : player.play();
    setState(() {});
  }

  Widget get fallback => Container(
      color: AppColors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.play_disabled_rounded, color: AppColors.white, size: 44),
        const SizedBox(height: 10),
        Text('Video is not available'.tr(),
            textAlign: TextAlign.center,
            style: Style.bodyw5(context).copyWith(color: AppColors.white)),
        if (errorMessage.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(errorMessage,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Style.small2w4(context).copyWith(color: AppColors.gray300))
        ]
      ]));

  Widget get loading => Container(
      color: AppColors.black,
      alignment: Alignment.center,
      child: const PrimaryLoadingIndicator(height: 34, width: 34));

  Widget playerView(VideoPlayerController player) => GestureDetector(
      onTap: togglePlayback,
      child: SizedBox.expand(
          child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                  width: player.value.size.width,
                  height: player.value.size.height,
                  child: VideoPlayer(player)))));

  @override
  Widget build(BuildContext context) {
    final player = controller;
    if (!widget.shouldInitialize) return loading;
    if (hasError) return fallback;
    if (player == null || !player.value.isInitialized) return loading;
    return playerView(player);
  }
}
