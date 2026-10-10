import 'package:flutter/material.dart';

/// Route transition from the host app into Word Forge: a short fade with a
/// gentle zoom-in. Leaving plays it backwards.
class WordForgeFadeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const WordForgeFadeTransition({super.key, required this.animation, required this.child});

  static const Duration duration = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}
