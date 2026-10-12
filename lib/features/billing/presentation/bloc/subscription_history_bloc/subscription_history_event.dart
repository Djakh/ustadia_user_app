import 'dart:async';

import 'package:equatable/equatable.dart';

abstract class SubscriptionHistoryEvent extends Equatable {
  const SubscriptionHistoryEvent();

  @override
  List<Object?> get props => [];
}

class SubscriptionHistoryRequested extends SubscriptionHistoryEvent {
  final bool showLoading;

  /// Completed when loading ends, so pull-to-refresh can stop its spinner.
  final Completer<void>? completer;

  const SubscriptionHistoryRequested({this.showLoading = true, this.completer});

  @override
  List<Object?> get props => [showLoading];
}
