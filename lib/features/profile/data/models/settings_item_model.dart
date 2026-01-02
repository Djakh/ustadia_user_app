class SettingsItemModel {
  final String title;
  final String iconAsset;
  final bool isDestructive;

  const SettingsItemModel({
    required this.title,
    required this.iconAsset,
    this.isDestructive = false,
  });
}
