import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

enum WordMatchCardState { idle, selected, matched, wrong }

class WordMatchCardData {
  final int pairId;
  final String text;

  const WordMatchCardData({required this.pairId, required this.text});
}

class WordMatchCard extends StatelessWidget {
  final WordMatchCardData data;
  final WordMatchCardState state;
  final VoidCallback onTap;

  const WordMatchCard({super.key, required this.data, required this.state, required this.onTap});

  /// --- Widgets ---
  
  Color borderColor(BuildContext context) =>
      switch (state) { WordMatchCardState.selected => context.cs.primary, _ => Colors.transparent };

  Color fillColor(BuildContext context) => switch (state) {
        WordMatchCardState.matched => context.cs.primary,
        WordMatchCardState.wrong => context.cs.error,
        WordMatchCardState.selected => context.cs.surface,
        _ => context.cs.surface,
      };

  Color textColor(BuildContext context) =>
      state == WordMatchCardState.matched || state == WordMatchCardState.wrong
          ? Colors.white
          : context.cs.onSurface;

  Widget view(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: Style.border16,
      child: Ink(
          decoration: BoxDecoration(
              color: fillColor(context),
              borderRadius: Style.border16,
              border: Border.all(
                  color: borderColor(context),
                  width: state == WordMatchCardState.selected ? 2 : 0)),
          child: Center(
              child: Text(data.text,
                  style: Style.body2w5(context).copyWith(color: textColor(context))))));
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: view(context));
}
