import 'package:equatable/equatable.dart';

abstract class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object?> get props => [];
}

class AudioRequested extends AudioEvent {
  final String url;

  const AudioRequested({required this.url});

  @override
  List<Object?> get props => [url];
}
