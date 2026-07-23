import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/cached_images_primary/cached_image_primary.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:video_player/video_player.dart';

class ReelVideoControllerCache {
  ReelVideoControllerCache({this.maxControllers = 6});

  final int maxControllers;
  final LinkedHashMap<String, ReelVideoControllerEntry> _entries =
      LinkedHashMap<String, ReelVideoControllerEntry>();
  final Map<String, String> _fallbackUrlByFailedUrl = <String, String>{};

  String preferredUrl(String url) => _fallbackUrlByFailedUrl[url] ?? url;

  void rememberFallback({required String failedUrl, required String fallbackUrl}) {
    _fallbackUrlByFailedUrl[failedUrl] = fallbackUrl;
  }

  ReelVideoControllerEntry obtain(String url) {
    final existing = _entries.remove(url);
    if (existing != null) {
      _entries[url] = existing;
      return existing;
    }
    final entry = ReelVideoControllerEntry(url);
    _entries[url] = entry;
    _trim();
    return entry;
  }

  void _trim() {
    while (_entries.length > maxControllers) {
      final key = _entries.keys.first;
      final entry = _entries.remove(key);
      entry?.dispose();
    }
  }

  void clear() {
    for (final entry in _entries.values) {
      entry.dispose();
    }
    _entries.clear();
    _fallbackUrlByFailedUrl.clear();
  }
}

class ReelVideoControllerEntry {
  ReelVideoControllerEntry(this.url)
      : controller = VideoPlayerController.networkUrl(Uri.parse(url));

  final String url;
  final VideoPlayerController controller;
  Future<void>? initialization;
  Object? error;
  bool isDisposed = false;

  bool get isInitialized => controller.value.isInitialized;

  Future<void> initialize({
    Duration? initialPosition,
    required bool isMuted,
    required double speed,
  }) {
    if (initialization != null) return initialization!;
    initialization = _initialize(initialPosition: initialPosition, isMuted: isMuted, speed: speed);
    return initialization!;
  }

  Future<void> _initialize({
    Duration? initialPosition,
    required bool isMuted,
    required double speed,
  }) async {
    try {
      await controller.initialize();
      if (isDisposed) return;
      if (initialPosition != null &&
          initialPosition > Duration.zero &&
          initialPosition < controller.value.duration) {
        await controller.seekTo(initialPosition);
      }
      await controller.setLooping(true);
      await controller.setVolume(isMuted ? 0 : 1);
      await controller.setPlaybackSpeed(speed);
      error = null;
    } catch (exception) {
      error = exception;
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (isDisposed) return;
    isDisposed = true;
    await controller.dispose();
  }
}

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? fallbackVideoUrl;
  final String? placeholderUrl;
  final bool isActive;
  final bool shouldInitialize;
  final Duration? initialPosition;
  final ValueChanged<Duration>? onPositionChanged;
  final ReelVideoControllerCache controllerCache;

  const ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    this.fallbackVideoUrl,
    this.placeholderUrl,
    required this.isActive,
    this.shouldInitialize = true,
    this.initialPosition,
    this.onPositionChanged,
    required this.controllerCache,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> with WidgetsBindingObserver {
  ReelVideoControllerEntry? entry;
  bool hasError = false;
  String errorMessage = '';
  bool appResumed = true;
  bool isMuted = false;
  bool isManuallyPaused = false;
  bool isTemporarySpeedActive = false;
  bool isScrubbing = false;
  double selectedSpeed = 1;
  double scrubProgress = 0;
  int attachGeneration = 0;

  VideoPlayerController? get controller => entry?.controller;

  void reportPosition() {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    widget.onPositionChanged?.call(player.value.position);
  }

  List<double> get speedOptions => const [0.5, 1, 1.5, 2];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.shouldInitialize) attachPlayer();
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.shouldInitialize) {
      // The page is kept alive. Pause the native player, but retain its last
      // rendered frame and position so returning to the reel is instant.
      syncPlayback();
      return;
    }
    if (oldWidget.videoUrl != widget.videoUrl ||
        entry == null ||
        entry!.isDisposed ||
        !entry!.isInitialized) {
      attachPlayer();
      return;
    }
    syncPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    reportPosition();
    controller?.removeListener(reportPosition);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appResumed = state == AppLifecycleState.resumed;
    syncPlayback();
  }

  Future<void> attachPlayer() async {
    final generation = ++attachGeneration;
    final previousPlayer = controller;
    if (previousPlayer != null) {
      reportPosition();
      previousPlayer.removeListener(reportPosition);
    }
    entry = null;
    hasError = false;
    errorMessage = '';
    isManuallyPaused = false;
    isTemporarySpeedActive = false;
    isScrubbing = false;
    scrubProgress = 0;
    if (!mounted || generation != attachGeneration) return;
    if (widget.videoUrl.isEmpty) {
      setState(() {
        hasError = true;
        errorMessage = 'Video URL is empty';
      });
      return;
    }
    final sourceUrl = widget.controllerCache.preferredUrl(widget.videoUrl);
    final nextEntry = widget.controllerCache.obtain(sourceUrl);
    try {
      await initializeEntry(nextEntry);
      if (!mounted || generation != attachGeneration) return;
      if (widget.isActive && appResumed) await nextEntry.controller.play();
      if (mounted && generation == attachGeneration) setState(() {});
    } catch (streamError) {
      final fallbackUrl = widget.fallbackVideoUrl;
      final canRetryOriginal =
          fallbackUrl != null && fallbackUrl.isNotEmpty && fallbackUrl != sourceUrl;
      if (canRetryOriginal) {
        nextEntry.controller.removeListener(reportPosition);
        debugPrint('[Reels] Stream URL could not play; retrying original media URL. $streamError');
        try {
          final fallbackEntry = widget.controllerCache.obtain(fallbackUrl);
          await initializeEntry(fallbackEntry);
          if (!mounted || generation != attachGeneration) return;
          widget.controllerCache
              .rememberFallback(failedUrl: widget.videoUrl, fallbackUrl: fallbackUrl);
          if (widget.isActive && appResumed) await fallbackEntry.controller.play();
          if (mounted && generation == attachGeneration) setState(() {});
          return;
        } catch (fallbackError) {
          if (mounted && generation == attachGeneration) {
            setState(() {
              hasError = true;
              errorMessage = fallbackError.toString();
            });
          }
          return;
        }
      }
      if (mounted && generation == attachGeneration) {
        setState(() {
          hasError = true;
          errorMessage = streamError.toString();
        });
      }
    }
  }

  Future<void> initializeEntry(ReelVideoControllerEntry nextEntry) async {
    entry = nextEntry;
    nextEntry.controller.addListener(reportPosition);
    await nextEntry.initialize(
        initialPosition: widget.initialPosition, isMuted: isMuted, speed: selectedSpeed);
  }

  void syncPlayback() {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    if (widget.isActive && appResumed && !isManuallyPaused && !player.value.isPlaying) {
      player.play();
    }
    if ((!widget.isActive || !appResumed) && player.value.isPlaying) {
      player.pause();
    }
  }

  Future<void> togglePlayback() async {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    if (player.value.isPlaying) {
      isManuallyPaused = true;
      await player.pause();
    } else {
      isManuallyPaused = false;
      await player.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> toggleMute() async {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    isMuted = !isMuted;
    await player.setVolume(isMuted ? 0 : 1);
    setState(() {});
  }

  Future<void> setSelectedSpeed(double speed) async {
    final player = controller;
    selectedSpeed = speed;
    isTemporarySpeedActive = false;
    if (player != null && player.value.isInitialized) {
      await player.setPlaybackSpeed(speed);
    }
    if (mounted) setState(() {});
  }

  Future<void> startTemporarySpeed() async {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    isTemporarySpeedActive = true;
    await player.setPlaybackSpeed(2);
    if (!player.value.isPlaying && widget.isActive && appResumed) {
      isManuallyPaused = false;
      await player.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> stopTemporarySpeed() async {
    final player = controller;
    if (player == null || !player.value.isInitialized || !isTemporarySpeedActive) return;
    isTemporarySpeedActive = false;
    await player.setPlaybackSpeed(selectedSpeed);
    if (mounted) setState(() {});
  }

  bool isSideLongPress(Offset position, Size size) {
    final leftEdge = size.width * 0.28;
    final rightEdge = size.width * 0.72;
    return position.dx <= leftEdge || position.dx >= rightEdge;
  }

  Future<void> onLongPressStart(LongPressStartDetails details) async {
    final size = context.size;
    if (size == null) return;
    if (isSideLongPress(details.localPosition, size)) {
      await startTemporarySpeed();
      return;
    }
    showSpeedSheet();
  }

  void onLongPressEnd(LongPressEndDetails details) {
    stopTemporarySpeed();
  }

  Future<void> showSpeedSheet() async {
    await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: Style.borderVer24),
        builder: (context) => speedSheet(context));
  }

  String speedLabel(double value) {
    if (value == value.roundToDouble()) return '${value.toInt()}x';
    return '${value}x';
  }

  double progressValue(VideoPlayerValue value) {
    if (isScrubbing) return scrubProgress;
    final duration = value.duration.inMilliseconds;
    if (duration <= 0) return 0;
    final progress = value.position.inMilliseconds / duration;
    if (progress < 0) return 0;
    if (progress > 1) return 1;
    return progress;
  }

  void onProgressChangeStart(double value) {
    setState(() {
      isScrubbing = true;
      scrubProgress = value;
    });
  }

  void onProgressChanged(double value) {
    setState(() => scrubProgress = value);
  }

  Future<void> onProgressChangeEnd(double value) async {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    final duration = player.value.duration.inMilliseconds;
    final position = Duration(milliseconds: (duration * value).round());
    await player.seekTo(position);
    if (!mounted) return;
    setState(() {
      isScrubbing = false;
      scrubProgress = value;
    });
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.placeholderUrl != null && widget.placeholderUrl!.isNotEmpty)
            CachedImagePrimary(
                imageUrl: widget.placeholderUrl!,
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover),
          Container(color: AppColors.black.withValues(alpha: 0.18)),
          const Center(child: PrimaryLoadingIndicator(height: 34, width: 34)),
        ],
      ));

  Widget speedChip(BuildContext context, double speed) {
    final isSelected = selectedSpeed == speed && !isTemporarySpeedActive;
    return InkWell(
        onTap: () {
          Navigator.of(context).pop();
          setSelectedSpeed(speed);
        },
        borderRadius: Style.border16,
        child: Container(
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.grayF4,
                borderRadius: Style.border16),
            child: Center(
                child: Text(speedLabel(speed),
                    style: Style.bodyw7(context)
                        .copyWith(color: isSelected ? AppColors.white : AppColors.black)))));
  }

  Widget speedSheet(BuildContext context) => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(color: AppColors.gray400, borderRadius: Style.border95)),
            const SizedBox(height: 22),
            Row(children: [
              const Icon(Icons.speed_rounded, color: AppColors.black),
              const SizedBox(width: 10),
              Text('Playback speed'.tr(), style: Style.body2w7(context))
            ]),
            const SizedBox(height: 18),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: speedOptions.map((speed) => speedChip(context, speed)).toList())
          ])));

  Widget centerControl(VideoPlayerController player) {
    if (player.value.isPlaying && !isTemporarySpeedActive) return const SizedBox.shrink();
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (!player.value.isPlaying)
        InkWell(
            onTap: toggleMute,
            borderRadius: Style.border95,
            child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.42), shape: BoxShape.circle),
                child: Icon(isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: AppColors.white, size: 28))),
      if (!player.value.isPlaying) const SizedBox(height: 16),
      Container(
          width: 86,
          height: 86,
          decoration:
              BoxDecoration(color: AppColors.black.withValues(alpha: 0.42), shape: BoxShape.circle),
          child: Icon(
              isTemporarySpeedActive
                  ? Icons.fast_forward_rounded
                  : player.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
              color: AppColors.white,
              size: 48))
    ]));
  }

  Widget speedHint(BuildContext context) {
    if (!isTemporarySpeedActive) return const SizedBox.shrink();
    return Positioned(
        left: 24,
        right: 24,
        bottom: 112,
        child: Center(
            child: Text('Slide down to lock 2x speed'.tr(),
                textAlign: TextAlign.center,
                style: Style.bodyw5(context).copyWith(color: AppColors.white))));
  }

  Widget progressBar(VideoPlayerController player) => Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
          top: false,
          child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: player,
              builder: (context, value, _) {
                final hasDuration = value.duration.inMilliseconds > 0;
                return SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        activeTrackColor: AppColors.white,
                        inactiveTrackColor: AppColors.white.withValues(alpha: 0.28),
                        thumbColor: AppColors.white,
                        overlayColor: AppColors.white.withValues(alpha: 0.18),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12)),
                    child: Slider(
                        min: 0,
                        max: 1,
                        value: progressValue(value),
                        onChangeStart: hasDuration ? onProgressChangeStart : null,
                        onChanged: hasDuration ? onProgressChanged : null,
                        onChangeEnd: hasDuration ? onProgressChangeEnd : null));
              })));

  Widget playerView(VideoPlayerController player) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: togglePlayback,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: SizedBox.expand(
          child: Stack(fit: StackFit.expand, children: [
        FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
                width: player.value.size.width,
                height: player.value.size.height,
                child: VideoPlayer(player))),
        ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: player,
            builder: (context, value, _) {
              if (!value.isBuffering) return const SizedBox.shrink();
              return Container(
                  color: AppColors.black.withValues(alpha: 0.18),
                  child: const Center(child: PrimaryLoadingIndicator(height: 34, width: 34)));
            }),
        centerControl(player),
        speedHint(context),
        progressBar(player)
      ])));

  @override
  Widget build(BuildContext context) {
    final player = controller;
    if (hasError) return fallback;
    if (player == null || !player.value.isInitialized) return loading;
    return playerView(player);
  }
}
