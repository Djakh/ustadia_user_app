import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TutorialStorageService stores opt-in and completed pages', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = TutorialStorageService(prefs: prefs);

    expect(storage.isPromptAnswered, isFalse);
    expect(storage.shouldConsiderPage('dashboard'), isTrue);

    await storage.setTutorialEnabled(false);

    expect(storage.isPromptAnswered, isTrue);
    expect(storage.isEnabled, isFalse);
    expect(storage.shouldConsiderPage('dashboard'), isFalse);

    await storage.setTutorialEnabled(true);
    await storage.markPageCompleted('dashboard');

    expect(storage.isEnabled, isTrue);
    expect(storage.isPageCompleted('dashboard'), isTrue);
    expect(storage.shouldConsiderPage('dashboard'), isFalse);
  });
}
