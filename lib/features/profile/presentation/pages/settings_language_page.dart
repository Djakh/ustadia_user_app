import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/profile/data/models/settings_language_model.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/dividers/primary_divider.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/item_list_box.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/settings_language_item.dart';

class SettingsLanguagePage extends StatefulWidget {
  final UserProfileModel userProfileModel;
  const SettingsLanguagePage({super.key, required this.userProfileModel});

  @override
  State<SettingsLanguagePage> createState() => SettingsLanguagePageState();
}

class SettingsLanguagePageState extends State<SettingsLanguagePage> {
  late String selectedKey;

  List<SettingsLanguageModel> items = const [
    SettingsLanguageModel(
        title: 'English', iconAsset: AppImages.settingsEnglish, isSelected: true, key: 'en'),
    SettingsLanguageModel(
        title: 'Russian', iconAsset: AppImages.settingsRussian, isSelected: false, key: 'ru'),
    SettingsLanguageModel(
        title: 'Uzbek', iconAsset: AppImages.settingsUzbek, isSelected: false, key: 'uz'),
  ];

  /// --- Life cycle ---
  @override
  void initState() {
    selectedKey = widget.userProfileModel.language;
    super.initState();
  }

  /// --- Methods ---

  void selectLanguage(String key) {
    selectedKey = key;
    context.read<UserBloc>().add(UserProfileUpdated(language: selectedKey));
  }

  /// --- Widgets ---

  Widget languageItemList(BuildContext context) => BlocBuilder<UserBloc, UserState>(
      builder: (context, state) => Column(
            children: [
              SettingsLanguageItem(
                  item: items[0], isSelected: items[0].key == selectedKey, onTap: selectLanguage),
              const PrimaryDivider(),
              SettingsLanguageItem(
                  item: items[1], isSelected: items[1].key == selectedKey, onTap: selectLanguage),
              const PrimaryDivider(),
              SettingsLanguageItem(
                  item: items[2], isSelected: items[2].key == selectedKey, onTap: selectLanguage),
            ],
          ));

  Column view(BuildContext context) => Column(children: [
        const SizedBox(height: 12),
        ItemListBox(child: languageItemList(context)),
        const SizedBox(height: 24)
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(title: 'Language', isScrollable: true, child: view(context)));
}
