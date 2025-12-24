import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/listen_mode_choose_view.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/listen_quiz_view.dart';

class ListenTapQuestion {
  final String prompt;
  final List<String> options;
  final int answerIndex;

  const ListenTapQuestion({required this.prompt, required this.options, required this.answerIndex});
}

enum ListenTapMode { words, sentences }

class ListenTapPage extends StatefulWidget {
  const ListenTapPage({super.key});

  @override
  State<ListenTapPage> createState() => _ListenTapPageState();
}

class _ListenTapPageState extends State<ListenTapPage> {
  final FlutterTts _tts = FlutterTts();
  ListenTapMode? mode;

  /// --- Life cycle ---

  @override
  void dispose() {
    _safeStopTts();

    super.dispose();
  }

  Future<void> _safeStopTts() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore missing plugin when widget is disposed during hot-reload/navigation.
    }
  }

  /// --- Methods ---

  void selectMode(ListenTapMode value) => setState(() {
        mode = value;
      });

  /// --- Widgets ---

  Widget get view => PrimaryBackground(
      title: 'Listen & Tap',
      isScrollable: true,
      child: mode == null
          ? ListenModeChooseContent(selectMode: selectMode)
          : ListenQuizView(selectMode: selectMode, tts: _tts, mode: mode!));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
