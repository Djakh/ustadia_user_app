import 'package:flutter/material.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  /// --- Widgets ---

  Widget get mainText => const Text("Learn page");
  Widget get view => Column(
        children: [mainText],
      );

  @override
  Widget build(BuildContext context) => view;
}
