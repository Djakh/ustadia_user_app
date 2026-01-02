import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/profile/data/models/settings_toggle_model.dart';

class SettingsNotificationItem extends StatelessWidget {
  final SettingsToggleModel item;
  final ValueChanged<bool> onChanged;

  const SettingsNotificationItem({super.key, required this.item, required this.onChanged});

  Widget get switcher => Switch.adaptive(
        value: item.isEnabled,
        activeTrackColor: AppColors.green6A,
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.greenC6;
          }
          return null;
        }),
        trackOutlineWidth: WidgetStateProperty.all(1.0),
        onChanged: onChanged,
      );

  Widget view(BuildContext context) =>
      Row(children: [Expanded(child: Text(item.title, style: Style.bodyw4(context))), switcher]);

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(16.0), child: view(context));
}
