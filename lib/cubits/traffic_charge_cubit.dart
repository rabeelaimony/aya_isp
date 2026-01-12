import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/traffic_charge_repository.dart';
import '../models/traffic_charge_model.dart';
import '../core/error_handler.dart';
import '../core/logger.dart';
import 'traffic_charge_state.dart';

class TrafficChargeCubit extends Cubit<TrafficChargeState> {
  final TrafficChargeRepository repository;

  TrafficChargeCubit(this.repository) : super(TrafficChargeInitial());

  Future<String> chargePackage({
    required String username,
    required String packageId,
    required String token,
  }) async {
    emit(TrafficChargeLoading());
    try {
      final result = await repository.chargePackage(
        username: username,
        packageId: packageId,
        token: token,
      );
      // Prefer the raw server 'message' when available so the UI prints
      // exactly what the server sent (even if it's malformed). Also log it.
      final rawMessage = result['message']?.toString();

      if (rawMessage != null && rawMessage.trim().isNotEmpty) {
        AppLogger.w('Server raw message: $rawMessage');
      }

      final response = TrafficChargeResponse.fromJson(result);

      if (response.isSuccess) {
        final fallbackMessage = response.message;
        final msg = (rawMessage != null && rawMessage.trim().isNotEmpty)
            ? rawMessage
            : (fallbackMessage != null && fallbackMessage.trim().isNotEmpty)
                  ? fallbackMessage
                  : 'تم شحن الباقة بنجاح';
        emit(TrafficChargeSuccess(msg));
        return msg;
      }

      // Prefer server/normalized error messages for failures.
      final normalized = ErrorHandler.extractMessage(result);
      final errMsg = (rawMessage != null && rawMessage.trim().isNotEmpty)
          ? rawMessage
          : (normalized.isNotEmpty
                ? normalized
                : (response.message ?? 'فشلت عملية الشحن'));
      AppLogger.w('Charge failed, server message/raw: $errMsg');
      emit(TrafficChargeError(errMsg));
      throw Exception(errMsg);
    } catch (e) {
      final friendly = ErrorHandler.getErrorMessage(e);
      emit(TrafficChargeError(friendly));
      throw Exception(friendly);
    }
  }
}
