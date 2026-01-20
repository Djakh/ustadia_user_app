import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class AudioState extends Equatable {
  final Status status;
  final String? filePath;
  final String? errorMessage;

  const AudioState({
    this.status = Status.initial,
    this.filePath,
    this.errorMessage,
  });

  AudioState copyWith({Status? status, String? filePath, String? errorMessage}) {
    return AudioState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, filePath, errorMessage];
}
