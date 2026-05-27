import 'package:shared_preferences/shared_preferences.dart';

class TutorialStorageService {
  final SharedPreferences prefs;

  TutorialStorageService({required this.prefs});

  static const String promptAnsweredKey = 'tutorial_prompt_answered';
  static const String enabledKey = 'tutorial_enabled';
  static const String completedPagesKey = 'tutorial_completed_pages';
  static const String contentVersion = 'v3';

  bool get isPromptAnswered => prefs.getBool(promptAnsweredKey) ?? false;

  bool get isEnabled => prefs.getBool(enabledKey) ?? false;

  Set<String> get completedPages => (prefs.getStringList(completedPagesKey) ?? []).toSet();

  String versionedPageId(String pageId) => '$contentVersion:$pageId';

  bool isPageCompleted(String pageId) => completedPages.contains(versionedPageId(pageId));

  bool shouldConsiderPage(String pageId) {
    if (!isPromptAnswered) return true;
    return isEnabled && !isPageCompleted(pageId);
  }

  Future<void> setTutorialEnabled(bool value) async {
    await prefs.setBool(promptAnsweredKey, true);
    await prefs.setBool(enabledKey, value);
  }

  Future<void> markPageCompleted(String pageId) async {
    final pages = completedPages..add(versionedPageId(pageId));
    await prefs.setStringList(completedPagesKey, pages.toList());
  }

  Future<void> resetTutorial() async {
    await prefs.remove(promptAnsweredKey);
    await prefs.remove(enabledKey);
    await prefs.remove(completedPagesKey);
  }
}
