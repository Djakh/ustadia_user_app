import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/practice_listen_quiz_view.dart';

class PracticeListenTapPage extends StatefulWidget {
  final PracticeListenTapSetModel set;

  const PracticeListenTapPage({super.key, required this.set});

  @override
  State<PracticeListenTapPage> createState() => PracticeListenTapPageState();
}

class PracticeListenTapPageState extends State<PracticeListenTapPage> {
  /// --- Widgets ---

  Widget get view => PrimaryBackground(
      title: widget.set.title,
      isScrollable: false,
      child: PracticeListenQuizView(set: widget.set));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
