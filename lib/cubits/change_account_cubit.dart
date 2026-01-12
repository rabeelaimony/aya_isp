import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/change_account_service.dart';
import '../core/error_handler.dart';
import 'change_account_state.dart';
import '../models/expand_traffic_response.dart';

class ChangeAccountCubit extends Cubit<ChangeAccountState> {
  final ChangeAccountService service;

  ChangeAccountCubit(this.service) : super(ChangeAccountInitial());

  Future<void> changeToVip({
    required String username,
    required String token,
  }) async {
    emit(ChangeAccountLoading());
    try {
      final result = await service.changeToVip(
        username: username,
        token: token,
      );

      // handle responses with only message
      final rawStatus = result['status'];
      final serverMessage = result['message']?.toString();

      // If server returned only a message (Postman style), treat as success
      if ((rawStatus == null || rawStatus.toString().trim().isEmpty) &&
          serverMessage != null &&
          serverMessage.trim().isNotEmpty) {
        emit(ChangeAccountSuccess(serverMessage));
        return;
      }

      final response = ExpandTrafficResponse.fromJson(result);
      if (response.isSuccess) {
        emit(ChangeAccountSuccess(response.message ?? 'تمت العملية بنجاح'));
      } else {
        // Use ErrorHandler to extract a user-friendly message from server payload
        final msg = ErrorHandler.extractMessage(result);
        emit(ChangeAccountError(msg));
      }
    } catch (e) {
      emit(ChangeAccountError(ErrorHandler.getErrorMessage(e)));
    }
  }

  Future<void> changeToNakaba({
    required String username,
    required String token,
    required String nakabaNumber,
    required int nakabaId,
    required String imagePath,
  }) async {
    emit(ChangeAccountLoading());
    try {
      final result = await service.changeToNakaba(
        username: username,
        token: token,
        nakabaNumber: nakabaNumber,
        nakabaId: nakabaId,
        imagePath: imagePath,
      );

      final rawStatus = result['status'];
      final serverMessage = result['message']?.toString();
      if ((rawStatus == null || rawStatus.toString().trim().isEmpty) &&
          serverMessage != null &&
          serverMessage.trim().isNotEmpty) {
        emit(ChangeAccountSuccess(serverMessage));
        return;
      }

      final response = ExpandTrafficResponse.fromJson(result);
      if (response.isSuccess) {
        emit(ChangeAccountSuccess(response.message ?? 'تمت العملية بنجاح'));
      } else {
        emit(ChangeAccountError(response.message ?? 'فشلت العملية'));
      }
    } catch (e) {
      emit(ChangeAccountError(ErrorHandler.getErrorMessage(e)));
    }
  }
}
