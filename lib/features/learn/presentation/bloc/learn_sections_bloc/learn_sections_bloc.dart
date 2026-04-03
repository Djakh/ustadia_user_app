import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_state.dart';

class LearnSectionsBloc extends Bloc<LearnSectionsEvent, LearnSectionsState> {
  final LearnRemoteDataSource learnRemoteDataSource;

  LearnSectionsBloc({required this.learnRemoteDataSource}) : super(const LearnSectionsState()) {
    on<LearnSectionsRequested>(handleSectionsRequested);
    on<LearnSectionsLoadMoreRequested>(handleSectionsLoadMoreRequested);
  }

  Future<void> handleSectionsRequested(
      LearnSectionsRequested event, Emitter<LearnSectionsState> emit) async {
    emit(state.copyWith(
        status: Status.loading,
        sections: const [],
        pagination: const PaginationMeta(),
        isLoadingMore: false,
        errorMessage: null,
        unitId: event.unitId));
    try {
      final result = await learnRemoteDataSource.fetchSections(
          unitId: event.unitId, page: event.page, limit: event.limit);
      emit(state.copyWith(
          status: Status.success,
          sections: result.items,
          pagination: result.meta,
          errorMessage: null,
          unitId: event.unitId));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> handleSectionsLoadMoreRequested(
      LearnSectionsLoadMoreRequested event, Emitter<LearnSectionsState> emit) async {
    if (state.isLoadingMore || !state.pagination.hasNext) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await learnRemoteDataSource.fetchSections(
          unitId: event.unitId, page: state.pagination.page + 1, limit: state.pagination.limit);
      final merged = [...state.sections, ...result.items];
      emit(state.copyWith(
          status: Status.success,
          sections: merged,
          pagination: result.meta,
          isLoadingMore: false,
          errorMessage: null));
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }
}
