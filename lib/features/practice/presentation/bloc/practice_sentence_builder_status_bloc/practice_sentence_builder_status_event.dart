import 'package:equatable/equatable.dart';

abstract class PracticeSentenceBuilderStatusEvent extends Equatable {
  const PracticeSentenceBuilderStatusEvent();

  @override
  List<Object?> get props => [];
}

class PracticeSentenceBuilderStatusRequested extends PracticeSentenceBuilderStatusEvent {
  final String sentenceBuilderId;
  final String status;

  const PracticeSentenceBuilderStatusRequested({
    required this.sentenceBuilderId,
    required this.status,
  });

  @override
  List<Object?> get props => [sentenceBuilderId, status];
}
