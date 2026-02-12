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

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    requestAudio();
    player.onPlayerComplete.listen((_) => setState(() => isPlaying = false));
  }

  @override
  void didUpdateWidget(covariant AudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionModel.audioFile?.url != widget.sectionModel.audioFile?.url) {
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

  Future<void> toggleAudio() async {
    final state = audioBloc.state;
    if (state.status.isLoading) return;
    if (state.filePath == null || state.filePath!.isEmpty) {
      requestAudio();
      return;
    }
    if (isPlaying) {
      await player.stop();
      if (!mounted) return;
      setState(() => isPlaying = false);
      return;
    }
    setState(() => isPlaying = true);
    await player.play(DeviceFileSource(state.filePath!));
  }

  String statusText(AudioState state) {
    if (state.status.isLoading) return 'Downloading...';
    if (state.status.isError) return 'Tap to retry';
    if (isPlaying) return 'Playing...';
    return 'Tap to listen';
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

  Widget view(BuildContext context, AudioState state) => Row(children: [
        SvgPicture.asset(AppImages.learnListeningAudio, height: 32, width: 32),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Audio lesson'.tr(), style: Style.bodyw6(context)),
          const SizedBox(height: 4),
          Text(statusText(state), style: Style.small3w4(context, color: TextColorRole.greyColor))
        ])),
        playButton(state)
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
