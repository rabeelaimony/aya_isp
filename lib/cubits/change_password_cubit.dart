import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/change_password_repository.dart';
import '../models/change_password_model.dart';
import 'change_password_state.dart';
import '../../core/error_handler.dart'; // ✅ استدعاء ErrorHandler

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ChangePasswordRepository repository;

  ChangePasswordCubit(this.repository) : super(ChangePasswordInitial());

  Future<void> changePassword({
    required String username,
    required String oldPass,
    required String newPass,
    required String newPassConfirmation,
    required String token,
  }) async {
    emit(ChangePasswordLoading());
    try {
      final result = await repository.changePassword(
        username: username,
        oldPass: oldPass,
        newPass: newPass,
        newPassConfirmation: newPassConfirmation,
        token: token,
      );

      final response = ChangePasswordResponse.fromJson(result);

      if (response.status == true) {
        emit(ChangePasswordSuccess(response.message));
      } else {
        emit(ChangePasswordError(response.message));
      }
    } catch (error) {
      // ✅ استخدام ErrorHandler
      final errorMessage = ErrorHandler.getErrorMessage(error);
      emit(ChangePasswordError(errorMessage));
    }
  }
}
