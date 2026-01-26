import 'package:equatable/equatable.dart';

abstract class PracticeSentenceBuilderSetsEvent extends Equatable {
  const PracticeSentenceBuilderSetsEvent();

  @override
  List<Object?> get props => [];
}

class PracticeSentenceBuilderSetsRequested extends PracticeSentenceBuilderSetsEvent {
  const PracticeSentenceBuilderSetsRequested();
}
