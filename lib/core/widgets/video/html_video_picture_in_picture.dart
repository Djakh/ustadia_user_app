import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_player_page.dart';
import 'package:ustadia_user_app/core/widgets/video/html_video_url_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum _PictureInPictureCorner { topLeft, topRight, bottomLeft, bottomRight }

/// An in-app floating video player that stays above the article while the
/// reader scrolls the content behind it.
class HtmlVideoPictureInPicture extends StatefulWidget {
  final HtmlVideoPlayerParams params;
  final VoidCallback onClose;
  final ValueChanged<Duration> onEnterFullscreen;

  const HtmlVideoPictureInPicture({
    super.key,
    required this.params,
    required this.onClose,
    required this.onEnterFullscreen,
  });

  @override
  State<HtmlVideoPictureInPicture> createState() => _HtmlVideoPictureInPictureState();
}

class _HtmlVideoPictureInPictureState extends State<HtmlVideoPictureInPicture>
    with WidgetsBindingObserver {
  static const Duration seekStep = Duration(seconds: 10);
  static const Duration controlsTimeout = Duration(seconds: 3);
  static const double playerAspectRatio = 16 / 9;
  static const double screenMargin = 12;
  static const double maximumPlayerWidth = 480;
  static const double minimumPlayerWidth = 220;

  VideoPlayerController? directController;
  YoutubePlayerController? youtubeController;
  Timer? controlsTimer;
  bool controlsVisible = true;
  bool hasError = false;
  bool wasPlayingBeforePause = false;
  bool isMoving = false;
  double? playerWidth;
  double resolvedPlayerWidth = maximumPlayerWidth;
  Rect playerBounds = Rect.zero;
  Size renderedPlayerSize = Size.zero;
  Offset resolvedPlayerPosition = Offset.zero;
  Offset? freePlayerPosition;
  _PictureInPictureCorner playerCorner = _PictureInPictureCorner.bottomRight;

  String get url => widget.params.url.trim();
  bool get isYoutube => HtmlVideoUrlUtils.isYoutubeUrl(url);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializePlayer();
  }

  @override
  void dispose() {
    controlsTimer?.cancel();
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
    if (state == AppLifecycleState.resumed && wasPlayingBeforePause) {
      directController?.play();
      youtubeController?.play();
      wasPlayingBeforePause = false;
      scheduleControlsHide();
    }
  }

  Future<void> initializePlayer() async {
    if (url.isEmpty) {
      setError();
      return;
    }
    if (isYoutube) {
      final videoId = HtmlVideoUrlUtils.youtubeVideoId(url);
      if (videoId == null || videoId.isEmpty) {
        setError();
        return;
      }
      youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
              autoPlay: true,
              hideControls: true,
              enableCaption: true,
              startAt: widget.params.initialPosition.inSeconds));
      if (mounted) setState(() {});
      scheduleControlsHide();
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    directController = controller;
    try {
      await controller.initialize();
      final initialPosition = widget.params.initialPosition;
      if (initialPosition > Duration.zero) await controller.seekTo(initialPosition);
      await controller.play();
      if (mounted) setState(() {});
      scheduleControlsHide();
    } catch (_) {
      await controller.dispose();
      directController = null;
      setError();
    }
  }

  void setError() {
    if (!mounted) return;
    setState(() => hasError = true);
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

  void scheduleControlsHide() {
    controlsTimer?.cancel();
    controlsTimer = Timer(controlsTimeout, () {
      if (!mounted || !isPlaying || isMoving) return;
      setState(() => controlsVisible = false);
    });
  }

  bool get isPlaying {
    final directPlayer = directController;
    if (directPlayer != null && directPlayer.value.isInitialized) {
      return directPlayer.value.isPlaying;
    }
    return youtubeController?.value.isPlaying ?? false;
  }

  Duration get currentPosition {
    final directPlayer = directController;
    if (directPlayer != null && directPlayer.value.isInitialized) {
      return directPlayer.value.position;
    }
    return youtubeController?.value.position ?? widget.params.initialPosition;
  }

  void toggleControls() {
    setState(() => controlsVisible = !controlsVisible);
    if (controlsVisible) scheduleControlsHide();
  }

  void togglePlayback() {
    final directPlayer = directController;
    late final bool willPlay;
    if (directPlayer != null && directPlayer.value.isInitialized) {
      willPlay = !directPlayer.value.isPlaying;
      willPlay ? directPlayer.play() : directPlayer.pause();
    } else {
      final youtubePlayer = youtubeController;
      if (youtubePlayer == null) return;
      willPlay = !youtubePlayer.value.isPlaying;
      willPlay ? youtubePlayer.play() : youtubePlayer.pause();
    }
    setState(() => controlsVisible = true);
    if (willPlay) {
      scheduleControlsHide();
    } else {
      controlsTimer?.cancel();
    }
  }

  void seek(Duration offset) {
    final directPlayer = directController;
    if (directPlayer != null && directPlayer.value.isInitialized) {
      final target =
          clampedPosition(directPlayer.value.position + offset, directPlayer.value.duration);
      unawaited(directPlayer.seekTo(target));
    } else {
      final youtubePlayer = youtubeController;
      if (youtubePlayer == null) return;
      final target =
          clampedPosition(youtubePlayer.value.position + offset, youtubePlayer.metadata.duration);
      youtubePlayer.seekTo(target);
    }
    setState(() => controlsVisible = true);
    scheduleControlsHide();
  }

  Duration clampedPosition(Duration position, Duration duration) {
    if (position < Duration.zero) return Duration.zero;
    if (duration > Duration.zero && position > duration) return duration;
    return position;
  }

  void enterFullscreen() {
    directController?.pause();
    youtubeController?.pause();
    widget.onEnterFullscreen(currentPosition);
  }

  bool get isRightCorner =>
      playerCorner == _PictureInPictureCorner.topRight ||
      playerCorner == _PictureInPictureCorner.bottomRight;

  double clampedPlayerWidth(double width) {
    final maximum = math.min(
        maximumPlayerWidth, math.min(playerBounds.width, playerBounds.height * playerAspectRatio));
    final minimum = math.min(minimumPlayerWidth, maximum);
    return width.clamp(minimum, maximum).toDouble();
  }

  Offset clampedPlayerPosition(Offset position, Size playerSize) => Offset(
      position.dx.clamp(playerBounds.left, playerBounds.right - playerSize.width).toDouble(),
      position.dy.clamp(playerBounds.top, playerBounds.bottom - playerSize.height).toDouble());

  Offset positionForCorner(Size playerSize) {
    final left = isRightCorner ? playerBounds.right - playerSize.width : playerBounds.left;
    final isBottom = playerCorner == _PictureInPictureCorner.bottomLeft ||
        playerCorner == _PictureInPictureCorner.bottomRight;
    final top = isBottom ? playerBounds.bottom - playerSize.height : playerBounds.top;
    return Offset(left, top);
  }

  void startMoving(DragStartDetails details) {
    controlsTimer?.cancel();
    setState(() {
      isMoving = true;
      controlsVisible = true;
      freePlayerPosition = resolvedPlayerPosition;
    });
  }

  void movePlayer(DragUpdateDetails details) {
    final currentPosition = freePlayerPosition ?? resolvedPlayerPosition;
    setState(() => freePlayerPosition =
        clampedPlayerPosition(currentPosition + details.delta, renderedPlayerSize));
  }

  void finishMoving(DragEndDetails details) {
    final position = freePlayerPosition ?? resolvedPlayerPosition;
    final playerCenter =
        position + Offset(renderedPlayerSize.width / 2, renderedPlayerSize.height / 2);
    final onLeft = playerCenter.dx < playerBounds.center.dx;
    final onTop = playerCenter.dy < playerBounds.center.dy;
    setState(() {
      playerCorner = onTop
          ? onLeft
              ? _PictureInPictureCorner.topLeft
              : _PictureInPictureCorner.topRight
          : onLeft
              ? _PictureInPictureCorner.bottomLeft
              : _PictureInPictureCorner.bottomRight;
      freePlayerPosition = null;
      isMoving = false;
    });
    scheduleControlsHide();
  }

  void cyclePlayerSize() {
    final minimum = clampedPlayerWidth(minimumPlayerWidth);
    final maximum = clampedPlayerWidth(maximumPlayerWidth);
    final medium = (minimum + maximum) / 2;
    final sizes = [minimum, medium, maximum];
    final next =
        sizes.firstWhere((width) => width > resolvedPlayerWidth + 8, orElse: () => minimum);
    setState(() {
      playerWidth = next;
      freePlayerPosition = null;
      controlsVisible = true;
    });
    scheduleControlsHide();
  }

  String durationText(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  Widget controlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    double size = 42,
    double iconSize = 25,
  }) =>
      Material(
          color: AppColors.black.withValues(alpha: .52),
          shape: const CircleBorder(),
          child: IconButton(
              constraints: BoxConstraints.tightFor(width: size, height: size),
              padding: EdgeInsets.zero,
              tooltip: tooltip,
              onPressed: onPressed,
              icon: Icon(icon, color: AppColors.white, size: iconSize)));

  Widget get videoView {
    if (hasError) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.play_disabled_rounded, color: AppColors.white, size: 42),
        const SizedBox(height: 6),
        Text('Video is not available'.tr(),
            style: Style.small3w5(context, color: TextColorRole.whiteColor))
      ]));
    }
    final youtubePlayer = youtubeController;
    if (youtubePlayer != null) {
      return Center(
          child: IgnorePointer(
              child: YoutubePlayer(
                  controller: youtubePlayer,
                  showVideoProgressIndicator: false,
                  aspectRatio: 16 / 9)));
    }
    final directPlayer = directController;
    if (directPlayer == null || !directPlayer.value.isInitialized) {
      return const Center(child: PrimaryLoadingIndicator(height: 30, width: 30));
    }
    return Center(
        child: AspectRatio(
            aspectRatio: directPlayer.value.aspectRatio, child: VideoPlayer(directPlayer)));
  }

  Widget progress(VideoPlayerValue? directValue, YoutubePlayerValue? youtubeValue) {
    final directPlayer = directController;
    if (directPlayer != null && directValue != null) {
      return VideoProgressIndicator(directPlayer,
          allowScrubbing: true,
          colors: const VideoProgressColors(
              playedColor: AppColors.primary,
              bufferedColor: AppColors.gray500,
              backgroundColor: AppColors.gray700),
          padding: const EdgeInsets.symmetric(vertical: 7));
    }
    final youtubePlayer = youtubeController;
    if (youtubePlayer != null && youtubeValue != null) {
      return ProgressBar(
          controller: youtubePlayer,
          colors: const ProgressBarColors(
              playedColor: AppColors.primary,
              handleColor: AppColors.primary,
              bufferedColor: AppColors.gray500,
              backgroundColor: AppColors.gray700));
    }
    return const SizedBox(height: 14);
  }

  Widget controls(VideoPlayerValue? directValue, YoutubePlayerValue? youtubeValue) {
    final position = directValue?.position ?? youtubeValue?.position ?? Duration.zero;
    final duration = directValue?.duration ?? youtubeController?.metadata.duration ?? Duration.zero;
    final playing = directValue?.isPlaying ?? youtubeValue?.isPlaying ?? false;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 280;
      final smallButtonSize = compact ? 32.0 : 38.0;
      final centerButtonSize = compact ? 36.0 : 42.0;
      final playButtonSize = compact ? 44.0 : 52.0;
      final spacing = compact ? 9.0 : 18.0;
      return AnimatedOpacity(
          opacity: controlsVisible || !playing ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
              ignoring: !controlsVisible && playing,
              child: Stack(children: [
                const Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                      Color(0x99000000),
                      Color(0x18000000),
                      Color(0xB3000000)
                    ])))),
                Positioned(
                    top: 8,
                    left: 8,
                    child: controlButton(
                        icon: Icons.close_rounded,
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        onPressed: widget.onClose,
                        size: smallButtonSize,
                        iconSize: compact ? 20 : 23)),
                Positioned(
                    top: 8,
                    right: compact ? 46 : 54,
                    child: controlButton(
                        icon: Icons.aspect_ratio_rounded,
                        tooltip: 'Change player size'.tr(),
                        onPressed: cyclePlayerSize,
                        size: smallButtonSize,
                        iconSize: compact ? 18 : 21)),
                Positioned(
                    top: 8,
                    right: 8,
                    child: controlButton(
                        icon: Icons.fullscreen_rounded,
                        tooltip: 'Open full screen'.tr(),
                        onPressed: enterFullscreen,
                        size: smallButtonSize,
                        iconSize: compact ? 21 : 25)),
                Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  controlButton(
                      icon: Icons.replay_10_rounded,
                      tooltip: 'Rewind 10 seconds'.tr(),
                      onPressed: () => seek(-seekStep),
                      size: centerButtonSize,
                      iconSize: compact ? 22 : 25),
                  SizedBox(width: spacing),
                  controlButton(
                      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      tooltip: playing ? 'Pause'.tr() : 'Play'.tr(),
                      onPressed: togglePlayback,
                      size: playButtonSize,
                      iconSize: compact ? 27 : 32),
                  SizedBox(width: spacing),
                  controlButton(
                      icon: Icons.forward_10_rounded,
                      tooltip: 'Forward 10 seconds'.tr(),
                      onPressed: () => seek(seekStep),
                      size: centerButtonSize,
                      iconSize: compact ? 22 : 25)
                ])),
                Positioned(
                    left: 12,
                    right: 12,
                    bottom: 7,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      progress(directValue, youtubeValue),
                      if (!compact)
                        Row(children: [
                          Text(durationText(position),
                              style: Style.small3w5(context, color: TextColorRole.whiteColor)),
                          const Spacer(),
                          Text(durationText(duration),
                              style: Style.small3w5(context).copyWith(color: AppColors.gray300))
                        ])
                    ]))
              ])));
    });
  }

  Widget get moveHandle => Positioned(
      top: 4,
      left: 0,
      right: 0,
      child: Center(
          child: Tooltip(
              message: 'Move video'.tr(),
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: startMoving,
                  onPanUpdate: movePlayer,
                  onPanEnd: finishMoving,
                  child: Container(
                      width: 48,
                      height: 30,
                      alignment: Alignment.topCenter,
                      child: Container(
                          width: 30,
                          height: 4,
                          decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: .85),
                              borderRadius: BorderRadius.circular(4))))))));

  Widget player(VideoPlayerValue? directValue, YoutubePlayerValue? youtubeValue) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: toggleControls,
      child: Stack(fit: StackFit.expand, children: [
        videoView,
        controls(directValue, youtubeValue),
      ]));

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    playerBounds = Rect.fromLTRB(
        screenMargin,
        mediaQuery.padding.top + screenMargin,
        screenSize.width - screenMargin,
        screenSize.height - mediaQuery.padding.bottom - screenMargin);
    resolvedPlayerWidth = clampedPlayerWidth(playerWidth ?? maximumPlayerWidth);
    renderedPlayerSize = Size(resolvedPlayerWidth, resolvedPlayerWidth / playerAspectRatio);
    resolvedPlayerPosition = clampedPlayerPosition(
        freePlayerPosition ?? positionForCorner(renderedPlayerSize), renderedPlayerSize);

    final playerCard = Material(
        color: AppColors.black,
        elevation: 12,
        shadowColor: AppColors.black,
        borderRadius: Style.border16,
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
            aspectRatio: 16 / 9,
            child: youtubeController != null
                ? ValueListenableBuilder<YoutubePlayerValue>(
                    valueListenable: youtubeController!,
                    builder: (context, value, child) => player(null, value))
                : directController != null
                    ? ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: directController!,
                        builder: (context, value, child) => player(value, null))
                    : player(null, null)));

    return AnimatedPositioned(
        duration: isMoving ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        left: resolvedPlayerPosition.dx,
        top: resolvedPlayerPosition.dy,
        width: resolvedPlayerWidth,
        height: renderedPlayerSize.height,
        child: Stack(fit: StackFit.expand, children: [playerCard, moveHandle]));
  }
}
