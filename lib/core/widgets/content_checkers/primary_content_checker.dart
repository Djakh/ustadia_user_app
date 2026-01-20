import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';

class BlocStatusView<B extends StateStreamable<S>, S, T> extends StatelessWidget {
  final B? bloc;

  final Status Function(S state) statusOf;
  final String? Function(S state) errorOf;

  final T Function(S state) data;
  final bool Function(T data) isEmpty;
  final Widget Function(BuildContext context, T data) builder;
  final bool isCustomLoading;
  final Widget? loading;
  final Widget? empty;
  final Widget Function(String message)? errorBuilder;
  final Widget? invalid;

  final void Function(BuildContext context, S state)? listener;

  final bool Function(S previous, S current)? listenWhen;

  final bool Function(S previous, S current)? buildWhen;

  const BlocStatusView({
    super.key,
    this.bloc,
    required this.statusOf,
    required this.errorOf,
    required this.data,
    required this.isEmpty,
    required this.builder,
    this.isCustomLoading = false,
    this.loading,
    this.empty,
    this.errorBuilder,
    this.invalid,
    this.listener,
    this.listenWhen,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<B, S>(
      bloc: bloc,
      listenWhen: listenWhen,
      buildWhen: buildWhen,
      listener: (context, state) => listener?.call(context, state),
      builder: (context, state) {
        if (invalid != null) return invalid!;

        final status = statusOf(state);

        if (status.isInitial || status.isLoading || isCustomLoading) {
          return loading ?? const PrimaryLoadingIndicator(height: 30, width: 30);
        }

        if (status.isError) {
          final msg = errorOf(state) ?? 'Something went wrong';
          return errorBuilder != null ? errorBuilder!(msg) : Center(child: Text(msg));
        }

        final value = data(state);
        if (isEmpty(value)) {
          return empty ?? const Center(child: Text('No data found'));
        }

        return builder(context, value);
      },
    );
  }
}
