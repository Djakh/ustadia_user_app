import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';

void main() {
  test('parses explicit social upload permissions', () {
    final profile = UserProfileModel.fromJson({
      'id': 'user-1',
      'roles': ['user'],
      'social_permissions': {
        'can_submit_ielts_writing': false,
        'can_upload_public_avatar': true,
      },
    });

    expect(profile.socialPermissions?.canSubmitIeltsWriting, isFalse);
    expect(profile.socialPermissions?.canUploadPublicAvatar, isTrue);
  });

  test('keeps missing permissions unknown rather than inventing access', () {
    final profile = UserProfileModel.fromJson({
      'id': 'user-1',
      'roles': ['user']
    });
    expect(profile.socialPermissions, isNull);
  });
}
