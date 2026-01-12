import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';

class UserState extends Equatable {
  final Status status;
  final UserProfileModel? profile;
  final String? errorMessage;

  const UserState({this.status = Status.initial, this.profile, this.errorMessage});

  UserState copyWith({Status? status, UserProfileModel? profile, String? errorMessage}) {
    return UserState(
        status: status ?? this.status, profile: profile ?? this.profile, errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
