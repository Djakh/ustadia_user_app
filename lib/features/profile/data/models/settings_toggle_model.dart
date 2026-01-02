class SettingsToggleModel {
  final String title;
  final bool isEnabled;

  const SettingsToggleModel({required this.title, required this.isEnabled});

  SettingsToggleModel copyWith({bool? isEnabled}) =>
      SettingsToggleModel(title: title, isEnabled: isEnabled ?? this.isEnabled);
}
