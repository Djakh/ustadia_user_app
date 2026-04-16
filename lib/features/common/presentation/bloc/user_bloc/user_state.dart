import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';

const userStateProfileUnchanged = Object();

class UserState extends Equatable {
  final Status status;
  final UserProfileModel? profile;
  final String? errorMessage;

  const UserState({this.status = Status.initial, this.profile, this.errorMessage});

  UserState copyWith(
      {Status? status, Object? profile = userStateProfileUnchanged, String? errorMessage}) {
    return UserState(
        status: status ?? this.status,
        profile: identical(profile, userStateProfileUnchanged)
            ? this.profile
            : profile as UserProfileModel?,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
