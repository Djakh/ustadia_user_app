import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class ReloadConntectionButton extends StatelessWidget {
  final Function() onReloadConnection;
  const ReloadConntectionButton({super.key, required this.onReloadConnection});

  /// --- Widgets ---

  Widget get reloadButton => Button.text(
        onTap: onReloadConnection,
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
