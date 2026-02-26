import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_state.dart';
import 'package:ustadia_user_app/injection_container.dart';

class AudioCard extends StatefulWidget {
  final SectionModel sectionModel;
  const AudioCard({super.key, required this.sectionModel});

  @override
  State<AudioCard> createState() => AudioCardState();
}

class AudioCardState extends State<AudioCard> {
  final AudioPlayer player = AudioPlayer();
  final AudioBloc audioBloc = sl<AudioBloc>();
  bool isPlaying = false;
  bool hasLoadedSource = false;
  bool isSeeking = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    requestAudio();
    player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
        currentPosition = totalDuration;
      });
    });
    player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => totalDuration = duration);
    });
    player.onPositionChanged.listen((position) {
      if (!mounted) return;
      if (isSeeking) return;
      setState(() => currentPosition = position);
    });
  }

  @override
  void didUpdateWidget(covariant AudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionModel.audioFile?.url != widget.sectionModel.audioFile?.url) {
      resetPlayerForNewAudio();
      requestAudio();
    }
  }

  @override
  void dispose() {
    player.dispose();
    audioBloc.close();
    super.dispose();
  }

  /// --- Getters ---
  String? get audioUrl => widget.sectionModel.audioFile?.url;
  double get progressValue {
    if (totalDuration.inMilliseconds == 0) return 0;
    final value = currentPosition.inMilliseconds / totalDuration.inMilliseconds;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  /// --- Listeners ---

  void audioListener(context, state) {
    print("my state is ${state.status}");
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  /// --- Methods ---

  void requestAudio() {
    final url = audioUrl;
    if (url == null || url.isEmpty) return;
    audioBloc.add(AudioRequested(url: url));
  }

  void resetPlayerForNewAudio() {
    player.stop();
    if (!mounted) return;
    setState(() {
      isPlaying = false;
      hasLoadedSource = false;
      isSeeking = false;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
    });
  }

  Future<void> toggleAudio() async {
    final state = audioBloc.state;
    if (state.status.isLoading) return;
    if (state.filePath == null || state.filePath!.isEmpty) {
      requestAudio();
      return;
    }
    if (isPlaying) {
      await player.pause();
      if (!mounted) return;
      setState(() => isPlaying = false);
      return;
    }
    setState(() => isPlaying = true);
    if (hasLoadedSource) {
      if (totalDuration != Duration.zero && currentPosition >= totalDuration) {
        await player.seek(Duration.zero);
        if (mounted) setState(() => currentPosition = Duration.zero);
      }
      await player.resume();
    } else {
      await player.play(DeviceFileSource(state.filePath!));
      hasLoadedSource = true;
    }
  }

  Future<void> seekRelative(Duration delta) async {
    final target = currentPosition + delta;
    final clamped = clampPosition(target);
    await player.seek(clamped);
    if (!mounted) return;
    setState(() => currentPosition = clamped);
  }

  Duration clampPosition(Duration target) {
    if (target < Duration.zero) return Duration.zero;
    if (totalDuration == Duration.zero) return target;
    if (target > totalDuration) return totalDuration;
    return target;
  }

  String statusText(AudioState state) {
    if (state.status.isLoading) return 'Downloading...';
    if (state.status.isError) return 'Tap to retry';
    if (isPlaying) return 'Playing...';
    return 'Tap to listen';
  }

  onChanged(value) {
    setState(() {
      isSeeking = true;
      currentPosition = Duration(milliseconds: (value * totalDuration.inMilliseconds).round());
    });
  }

  onChangeEnd(value) async {
    isSeeking = false;
    final target = Duration(milliseconds: (value * totalDuration.inMilliseconds).round());
    await player.seek(target);
  }

  /// --- Widgets ---

  Widget playButtonBody(AudioState state) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: isPlaying ? AppColors.primary : AppColors.grayF4, shape: BoxShape.circle),
      child: state.status.isLoading
          ? const PrimaryLoadingIndicator()
          : Center(
              child: SvgPicture.asset(
                  isPlaying ? AppImages.learnListeningStop : AppImages.learnListeningPlay)));

  InkWell playButton(AudioState state) => InkWell(
      onTap: state.status.isLoading ? null : toggleAudio,
      borderRadius: Style.border20,
      child: playButtonBody(state));

  Expanded audioTexts(BuildContext context, AudioState state) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Audio lesson'.tr(), style: Style.bodyw6(context)),
        const SizedBox(height: 4),
        Text(statusText(state), style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]));

  Widget controlButton(Widget child, VoidCallback onTap) => InkWell(
      onTap: hasLoadedSource ? onTap : null,
      borderRadius: Style.border20,
      child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.grayF4,
              borderRadius: Style.border95,
              border: Border.all(color: AppColors.gray100)),
          child: Center(child: child)));

  Widget headerRow(BuildContext context, AudioState state) => Row(children: [
        SvgPicture.asset(AppImages.learnListeningAudio, height: 32, width: 32),
        const SizedBox(width: 12),
        audioTexts(context, state),
        controlButton(
          const Icon(Icons.replay_5, size: 24, color: AppColors.primary),
          () => seekRelative(const Duration(seconds: -5)),
        ),
        const SizedBox(width: 16),
        playButton(state),
        const SizedBox(width: 16),
        controlButton(const Icon(Icons.forward_5, size: 24, color: AppColors.primary),
            () => seekRelative(const Duration(seconds: 5)))
      ]);

  Widget progressBar(BuildContext context) => SliderTheme(
      data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.gray100,
          thumbColor: AppColors.primary),
      child: Slider(
          min: 0,
          max: 1,
          value: progressValue,
          onChanged: totalDuration == Duration.zero ? null : onChanged,
          onChangeEnd: totalDuration == Duration.zero ? null : onChangeEnd));

  Widget view(BuildContext context, AudioState state) => Column(children: [
        headerRow(context, state),
        const SizedBox(height: 12),
        progressBar(context),
      ]);

  @override
  Widget build(BuildContext context) => BlocConsumer<AudioBloc, AudioState>(
      bloc: audioBloc,
      listener: audioListener,
      builder: (context, state) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: context.cs.surface,
              borderRadius: Style.border20,
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))
              ]),
          child: view(context, state)));
}
