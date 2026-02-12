class SettingsLanguageModel {
  final String title;
  final String iconAsset;
  final bool isSelected;
  final String key;

  const SettingsLanguageModel({
    required this.title,
    required this.iconAsset,
    required this.isSelected,
    required this.key,
  });

  SettingsLanguageModel copyWith({String? title, bool? isSelected}) => SettingsLanguageModel(
      title: title ?? this.title,
      iconAsset: iconAsset,
      isSelected: isSelected ?? this.isSelected,
      key: key);
}
