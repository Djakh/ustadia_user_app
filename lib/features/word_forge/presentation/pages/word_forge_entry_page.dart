import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/word_forge_audio.dart';
import '../../word_forge_module.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import '../word_forge_scope.dart';
import 'word_forge_start_page.dart';

/// Public entry point of the Word Forge module. The host app only needs to
/// show this widget with its dependencies and the signed-in player's id.
class WordForgeEntryPage extends StatefulWidget {
  final WordForgeDependencies dependencies;
  final String playerId;

  const WordForgeEntryPage({super.key, required this.dependencies, required this.playerId});

  @override
  State<WordForgeEntryPage> createState() => _WordForgeEntryPageState();
}

class _WordForgeEntryPageState extends State<WordForgeEntryPage> with WidgetsBindingObserver {
  late final WordForgeCubit _cubit =
      WordForgeCubit(dependencies: widget.dependencies, playerId: widget.playerId)..load();
  late final WordForgeAudio _audio = widget.dependencies.audioFactory();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio.preload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _audio.resumeAll();
    } else {
      _audio.pauseAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: WordForgeScope(
          dependencies: widget.dependencies,
          audio: _audio,
          child: BlocProvider.value(
            value: _cubit,
            child: BlocConsumer<WordForgeCubit, WordForgeState>(
              listenWhen: (previous, current) => previous.save?.settings.muted != current.save?.settings.muted,
              listener: (context, state) => _audio.muted = state.save?.settings.muted ?? false,
              buildWhen: (previous, current) => previous.status != current.status,
              builder: (context, state) => switch (state.status) {
                WordForgeStatus.ready => const WordForgeStartPage(),
                WordForgeStatus.loading => const _LoadingView(),
                WordForgeStatus.failure => _FailureView(onRetry: _cubit.load),
              },
            ),
          ),
        ),
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: ForgeBackdrop(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: WfColors.gold),
                ),
                const SizedBox(height: 20),
                Text(WfStrings.loading, style: WfText.body(15, color: WfColors.textDim)),
              ],
            ),
          ),
        ),
      );
}

class _FailureView extends StatelessWidget {
  final VoidCallback onRetry;

  const _FailureView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: ForgeBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: WfRoundButton(
                        glyph: WfGlyphType.back,
                        semanticsLabel: MaterialLocalizations.of(context).backButtonTooltip,
                        onTap: () => Navigator.of(context).maybePop()),
                  ),
                  const Spacer(),
                  Text(WfStrings.loadFailed, textAlign: TextAlign.center, style: WfText.title(18)),
                  const SizedBox(height: 24),
                  WfButton(label: WfStrings.retry, onTap: onRetry, expand: false),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      );
}
