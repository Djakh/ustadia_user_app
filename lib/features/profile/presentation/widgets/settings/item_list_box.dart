import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class ItemListBox extends StatelessWidget {
  final Widget child;
  const ItemListBox({super.key, required this.child});

  Widget view(BuildContext context) => Container(
        decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
        child: child,
      );
      
  @override
  Widget build(BuildContext context) => view(context);
}
