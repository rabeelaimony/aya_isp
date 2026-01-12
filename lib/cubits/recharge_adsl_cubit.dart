import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/recharge_adsl_service.dart';
import '../core/error_handler.dart';
import 'recharge_adsl_state.dart';
import '../models/expand_traffic_response.dart';

class RechargeAdslCubit extends Cubit<RechargeAdslState> {
  final RechargeAdslService service;

  RechargeAdslCubit(this.service) : super(RechargeAdslInitial());

  Future<void> recharge({
    required String username,
    required int duration,
    required String token,
  }) async {
    if (duration <= 0) {
      emit(RechargeAdslError('الرجاء اختيار مدة صالحة أكبر من صفر.'));
      return;
    }

    if (duration > 6) {
      emit(RechargeAdslError('لا يمكنك شحن أكثر من 6 أشهر.'));
      return;
    }

    emit(RechargeAdslLoading());
    try {
      final result = await service.rechargeAdsl(
        username: username,
        duration: duration,
        token: token,
      );

      // Some endpoints return only { "message": "..." } without a status
      // Treat that as success when there's a non-empty message and no status field.
      final rawStatus = result['status'];
      final serverMessage = result['message']?.toString();

      if ((rawStatus == null || rawStatus.toString().trim().isEmpty) &&
          serverMessage != null &&
          serverMessage.trim().isNotEmpty) {
        emit(RechargeAdslSuccess(serverMessage));
        return;
      }

      final response = ExpandTrafficResponse.fromJson(result);

      if (response.isSuccess) {
        emit(
          RechargeAdslSuccess(
            response.message ??
                'تم العملية بنجاح، الرجاء الانتظار دقيقتين حتى تتم العملية',
          ),
        );
      } else {
        final serverMsg = response.message ?? 'فشلت عملية الشحن.';
        emit(RechargeAdslError(serverMsg));
      }
    } catch (e) {
      emit(RechargeAdslError(ErrorHandler.getErrorMessage(e)));
    }
  }
}
