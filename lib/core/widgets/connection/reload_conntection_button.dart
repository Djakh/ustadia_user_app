import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class ReloadConntectionButton extends StatefulWidget {
  final FutureOr<void> Function() onReloadConnection;
  const ReloadConntectionButton({super.key, required this.onReloadConnection});

  @override
  State<ReloadConntectionButton> createState() => ReloadConntectionButtonState();
}

class ReloadConntectionButtonState extends State<ReloadConntectionButton> {
  bool isLoading = false;

  /// --- Widgets ---

  Future<void> onTapReload() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      await widget.onReloadConnection();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget get reloadButton => Button.text(
        onTap: onTapReload,
        isLoading: isLoading,
        text: 'Reload'.tr(),
      );

  Widget view(BuildContext context) => Column(children: [
        Text('Something went wrong'.tr(),
            style: Style.small2w3(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 4),
        reloadButton
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
