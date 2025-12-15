import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;

  const PageIndicator({super.key, required this.currentIndex, required this.total});

  Widget itemAnimatedContainer(int index) => AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(right: 4),
      height: 4,
      width: 56,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(index == currentIndex ? 0.9 : 0.55),
          borderRadius: BorderRadius.circular(12)));

  @override
  Widget build(BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(total, (index) => itemAnimatedContainer(index)));
}
