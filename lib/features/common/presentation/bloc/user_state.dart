import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';

enum UserStatus { initial, loading, success, failure }

class UserState extends Equatable {
  final UserStatus status;
  final UserProfileModel? profile;
  final String? errorMessage;

  const UserState({this.status = UserStatus.initial, this.profile, this.errorMessage});

  UserState copyWith({UserStatus? status, UserProfileModel? profile, String? errorMessage}) {
    return UserState(
        status: status ?? this.status, profile: profile ?? this.profile, errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
