class SettingsLanguageModel {
  final String title;
  final String iconAsset;
  final bool isSelected;

  const SettingsLanguageModel({
    required this.title,
    required this.iconAsset,
    required this.isSelected,
  });

  SettingsLanguageModel copyWith({bool? isSelected}) => SettingsLanguageModel(
        title: title,
        iconAsset: iconAsset,
        isSelected: isSelected ?? this.isSelected,
      );
}
