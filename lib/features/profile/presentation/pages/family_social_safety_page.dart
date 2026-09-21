import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/compliance/social_feature_settings_service.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/item_list_box.dart';
import 'package:ustadia_user_app/injection_container.dart';

class FamilySocialSafetyPage extends StatefulWidget {
  const FamilySocialSafetyPage({super.key});

  @override
  State<FamilySocialSafetyPage> createState() => _FamilySocialSafetyPageState();
}

class _FamilySocialSafetyPageState extends State<FamilySocialSafetyPage> {
  final settings = sl<SocialFeatureSettingsService>();
  bool unlocked = false;

  @override
  void initState() {
    super.initState();
    settings.addListener(onSettingsChanged);
  }

  @override
  void dispose() {
    settings.removeListener(onSettingsChanged);
    super.dispose();
  }

  void onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<String?> pinDialog({required bool confirm}) async {
    final controller = TextEditingController();
    final confirmationController = TextEditingController();
    final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
              title: Text(confirm ? 'Set adult controls PIN'.tr() : 'Adult controls'.tr()),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(confirm
                    ? 'Choose a PIN that only a parent or guardian knows.'.tr()
                    : 'Enter the adult controls PIN to manage social features.'.tr()),
                const SizedBox(height: 12),
                TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(labelText: 'PIN'.tr())),
                if (confirm)
                  TextField(
                      controller: confirmationController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(labelText: 'Confirm PIN'.tr()))
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(), child: Text('Cancel'.tr())),
                FilledButton(
                    onPressed: () {
                      final pin = controller.text.trim();
                      if (pin.length < 4 ||
                          (confirm && pin != confirmationController.text.trim())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Enter matching PIN with 4 to 6 digits.'.tr())));
                        return;
                      }
                      Navigator.of(dialogContext).pop(pin);
                    },
                    child: Text(confirm ? 'Save'.tr() : 'Unlock'.tr()))
              ],
            ));
    controller.dispose();
    confirmationController.dispose();
    return result;
  }

  Future<bool> unlock() async {
    final pin = await pinDialog(confirm: !settings.hasAdultPin);
    if (!mounted || pin == null) return false;
    if (!settings.hasAdultPin) {
      await settings.setAdultPin(pin);
      return true;
    }
    if (settings.verifyAdultPin(pin)) return true;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Incorrect adult controls PIN.'.tr())));
    return false;
  }

  Future<void> openControls() async {
    if (unlocked || await unlock()) {
      if (mounted) setState(() => unlocked = true);
    }
  }

  Widget toggle(
          {required String title,
          required String subtitle,
          required bool value,
          required Future<void> Function(bool) onChanged}) =>
      SwitchListTile.adaptive(
          title: Text(title.tr()),
          subtitle: Text(subtitle.tr()),
          value: value,
          onChanged: unlocked ? onChanged : null);

  Widget content(BuildContext context) {
    if (!unlocked) {
      return Center(
          child: Padding(
              padding: Style.paddingAll24,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.family_restroom_rounded, size: 52),
                const SizedBox(height: 16),
                Text('Adult controls protect social features for child users.'.tr(),
                    textAlign: TextAlign.center, style: Style.bodyw5(context)),
                const SizedBox(height: 8),
                Text('A parent or guardian must unlock this page with the adult PIN.'.tr(),
                    textAlign: TextAlign.center, style: Style.small3w4(context)),
                const SizedBox(height: 20),
                FilledButton(onPressed: openControls, child: Text('Open adult controls'.tr()))
              ])));
    }
    return ItemListBox(
        child: Column(children: [
      toggle(
          title: 'Comments and replies',
          subtitle: 'Allow children to exchange freeform text on learning reels.'.tr(),
          value: settings.commentsEnabled,
          onChanged: settings.setCommentsEnabled),
      toggle(
          title: 'Likes',
          subtitle: 'Allow children to react to learning reels.'.tr(),
          value: settings.likesEnabled,
          onChanged: settings.setLikesEnabled),
      toggle(
          title: 'Public profiles and avatars',
          subtitle: 'Allow profile pages and public profile images in social areas.'.tr(),
          value: settings.publicProfilesEnabled,
          onChanged: settings.setPublicProfilesEnabled),
    ]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(
          title: 'Family & social safety'.tr(),
          isScrollable: true,
          child: Padding(padding: Style.paddingV24, child: content(context))));
}
