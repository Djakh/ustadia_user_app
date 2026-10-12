import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_history_bloc/subscription_history_event.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_history_bloc/subscription_history_state.dart';

class SubscriptionHistoryBloc extends Bloc<SubscriptionHistoryEvent, SubscriptionHistoryState> {
  final BillingRemoteDataSource billingRemoteDataSource;

  SubscriptionHistoryBloc({required this.billingRemoteDataSource})
      : super(const SubscriptionHistoryState()) {
    on<SubscriptionHistoryRequested>(handleRequested);
  }

  Future<void> handleRequested(
      SubscriptionHistoryRequested event, Emitter<SubscriptionHistoryState> emit) async {
    final showLoading = event.showLoading || state.items.isEmpty;
    emit(state.copyWith(status: showLoading ? Status.loading : state.status));
    try {
      final items = await billingRemoteDataSource.fetchHistory();
      emit(state.copyWith(status: Status.success, items: items));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: showLoading ? Status.error : state.status,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: showLoading ? Status.error : state.status,
          errorMessage: DioErrorMessage.fromUnknown(error)));
    } finally {
      event.completer?.complete();
    }
  }
}
