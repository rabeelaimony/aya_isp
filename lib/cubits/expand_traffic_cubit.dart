import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/expand_traffic_service.dart';
import '../models/expand_traffic_response.dart';
import '../core/error_handler.dart';
import 'expand_traffic_state.dart';

class ExpandTrafficCubit extends Cubit<ExpandTrafficState> {
  final ExpandTrafficService service;

  ExpandTrafficCubit(this.service) : super(ExpandTrafficInitial());

  Future<void> extendTraffic({
    required String username,
    required int reqSize,
    required String token,
  }) async {
    emit(ExpandTrafficLoading());
    try {
      print(
        'ExpandTrafficCubit: extendTraffic -> username=$username reqSize=$reqSize',
      );

      final result = await service.expandTrafficSelection(
        username: username,
        reqSize: reqSize,
        token: token,
      );

      print('ExpandTrafficCubit: response -> $result');

      final response = ExpandTrafficResponse.fromJson(result);

      if (response.isSuccess) {
        emit(
          ExpandTrafficSuccess(response.message ?? 'تم تمديد الترافيك بنجاح'),
        );
      } else {
        emit(
          ExpandTrafficError(
            response.message ?? 'تعذر تمديد الترافيك، حاول لاحقاً.',
          ),
        );
      }
    } catch (e) {
      print('ExpandTrafficCubit: error -> $e');
      emit(ExpandTrafficError(ErrorHandler.getErrorMessage(e)));
    }
  }
}
