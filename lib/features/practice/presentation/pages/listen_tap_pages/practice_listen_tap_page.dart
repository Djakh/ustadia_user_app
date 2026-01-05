import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/practice_listen_mode_choose_view.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/practice_listen_quiz_view.dart';



enum PracticeListenTapMode { words, sentences }

class PracticeListenTapPage extends StatefulWidget {
  const PracticeListenTapPage({super.key});

  @override
  State<PracticeListenTapPage> createState() => PracticeListenTapPageState();
}

class PracticeListenTapPageState extends State<PracticeListenTapPage> {
  PracticeListenTapMode? mode;

  /// --- Methods ---

  void selectMode(PracticeListenTapMode value) => setState(() {
        mode = value;
      });

  /// --- Widgets ---

  Widget get view => PrimaryBackground(
      title: 'Listen & Tap',
      isScrollable: true,
      child: mode == null
          ? PracticeListenModeChooseView(selectMode: selectMode)
          : PracticeListenQuizView(mode: mode!));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
