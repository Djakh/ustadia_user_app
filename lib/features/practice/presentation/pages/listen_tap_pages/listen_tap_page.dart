import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/listen_mode_choose_view.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/listen_quiz_view.dart';



enum ListenTapMode { words, sentences }

class ListenTapPage extends StatefulWidget {
  const ListenTapPage({super.key});

  @override
  State<ListenTapPage> createState() => _ListenTapPageState();
}

class _ListenTapPageState extends State<ListenTapPage> {
  ListenTapMode? mode;

  /// --- Methods ---

  void selectMode(ListenTapMode value) => setState(() {
        mode = value;
      });

  /// --- Widgets ---

  Widget get view => PrimaryBackground(
      title: 'Listen & Tap',
      isScrollable: true,
      child: mode == null
          ? ListenModeChooseView(selectMode: selectMode)
          : ListenQuizView(mode: mode!));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
