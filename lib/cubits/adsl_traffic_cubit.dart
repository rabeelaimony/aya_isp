import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/adsl_traffic_service.dart';
import '../core/error_handler.dart';

part 'adsl_traffic_state.dart';

class AdslTrafficCubit extends Cubit<AdslTrafficState> {
  final AdslTrafficService _service;

  AdslTrafficCubit(this._service) : super(AdslTrafficInitial());

  Future<bool> fetchTraffic(String username, {String? token}) async {
    final currentState = state;
    if (currentState is AdslTrafficLoaded) {
      emit(
        AdslTrafficLoaded(
          currentState.response,
          isRefreshing: true,
        ),
      );
    } else {
      emit(AdslTrafficLoading());
    }

    try {
      final res = await _service.getAdslTraffic(username, token: token);
      emit(AdslTrafficLoaded(res));
      return true;
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      emit(AdslTrafficError(message));
      return false;
    }
  }
}
