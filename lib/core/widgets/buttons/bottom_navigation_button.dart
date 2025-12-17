import "package:flutter/material.dart";

class BottomNavigationButton extends StatelessWidget {
  const BottomNavigationButton({
    required this.child,
    this.bottomPadding = 8,
    this.leftPadding = 48,
    this.rightPadding = 48,
    this.topPadding = 8,
    super.key,
  });

  final Widget child;
  final double bottomPadding;
  final double leftPadding;
  final double rightPadding;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottom = bottomPadding + mediaQuery.padding.bottom + mediaQuery.viewInsets.bottom;

    return SafeArea(
      minimum: EdgeInsets.only(
        top: topPadding,
        left: leftPadding,
        right: rightPadding,
        bottom: bottom,
      ),
      child: child,
    );
  }
}
