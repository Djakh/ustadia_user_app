import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/practice/data/models/monkey_type_model.dart';

class MonkeyTypePracticesState extends Equatable {
  final Status status;
  final String? errorMessage;
  final List<MonkeyTypePracticeModel> practices;

  const MonkeyTypePracticesState({
    this.status = Status.initial,
    this.errorMessage,
    this.practices = const [],
  });

  MonkeyTypePracticesState copyWith({
    Status? status,
    String? errorMessage,
    List<MonkeyTypePracticeModel>? practices,
  }) =>
      MonkeyTypePracticesState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        practices: practices ?? this.practices,
      );

  @override
  List<Object?> get props => [status, errorMessage, practices];
}
