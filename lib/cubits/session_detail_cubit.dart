import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/error_handler.dart';
import '../models/session_detail_model.dart';
import '../services/session_detail_service.dart';

part 'session_detail_state.dart';

class SessionDetailCubit extends Cubit<SessionDetailState> {
  final SessionDetailService _service;

  SessionDetailCubit(this._service) : super(SessionDetailInitial());

  Future<void> fetchSessions({
    required String username,
    required int year,
    required int month,
    int page = 1,
    int perPage = 10,
    String? token,
  }) async {
    final currentState = state;
    if (currentState is SessionDetailLoaded) {
      emit(
        SessionDetailLoaded(
          currentState.response,
          selectedYear: year,
          selectedMonth: month,
          page: page,
          perPage: perPage,
          isRefreshing: true,
        ),
      );
    } else {
      emit(SessionDetailLoading());
    }

    try {
      final response = await _service.getSessionDetails(
        username: username,
        year: year,
        month: month,
        page: page,
        perPage: perPage,
        token: token,
      );
      emit(
        SessionDetailLoaded(
          response,
          selectedYear: year,
          selectedMonth: month,
          page: page,
          perPage: perPage,
        ),
      );
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      emit(SessionDetailError(message));
    }
  }
}
