import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/core/compliance/social_feature_settings_service.dart';

void main() {
  test('defaults social features to disabled and persists adult changes', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = SocialFeatureSettingsService(preferences: preferences);

    expect(settings.commentsEnabled, isFalse);
    expect(settings.likesEnabled, isFalse);
    expect(settings.publicProfilesEnabled, isFalse);
    expect(settings.hasAdultPin, isFalse);

    await settings.setAdultPin('1234');
    await settings.setCommentsEnabled(false);
    await settings.setLikesEnabled(false);
    await settings.setPublicProfilesEnabled(false);

    expect(settings.hasAdultPin, isTrue);
    expect(settings.verifyAdultPin('1234'), isTrue);
    expect(settings.verifyAdultPin('9999'), isFalse);
    expect(settings.commentsEnabled, isFalse);
    expect(settings.likesEnabled, isFalse);
    expect(settings.publicProfilesEnabled, isFalse);
  });
}
