import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/profile/data/models/settings_language_model.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/dividers/primary_divider.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/item_list_box.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/settings_language_item.dart';

class SettingsLanguagePage extends StatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  State<SettingsLanguagePage> createState() => SettingsLanguagePageState();
}

class SettingsLanguagePageState extends State<SettingsLanguagePage> {
  List<SettingsLanguageModel> items = const [
    SettingsLanguageModel(
      title: 'English',
      iconAsset: AppImages.settingsEnglish,
      isSelected: true,
    ),
    SettingsLanguageModel(
      title: 'Russian',
      iconAsset: AppImages.settingsRussian,
      isSelected: false,
    ),
    SettingsLanguageModel(
      title: 'Uzbek',
      iconAsset: AppImages.settingsUzbek,
      isSelected: false,
    ),
  ];

  /// --- Methods ---

  void selectLanguage(int index) {
    items = items
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(isSelected: entry.key == index))
        .toList();
    setState(() {});
  }

  /// --- Widgets ---

  Widget languageItemList(BuildContext context) => Column(
        children: [
          SettingsLanguageItem(item: items[0], onTap: () => selectLanguage(0)),
          const PrimaryDivider(),
          SettingsLanguageItem(item: items[1], onTap: () => selectLanguage(1)),
          const PrimaryDivider(),
          SettingsLanguageItem(item: items[2], onTap: () => selectLanguage(2)),
        ],
      );

  Column view(BuildContext context) => Column(children: [
        const SizedBox(height: 12),
        ItemListBox(child: languageItemList(context)),
        const SizedBox(height: 24)
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(title: 'Language', isScrollable: true, child: view(context)));
}
