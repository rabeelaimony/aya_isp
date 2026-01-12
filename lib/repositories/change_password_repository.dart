import '../services/change_password_service.dart';

class ChangePasswordRepository {
  final ChangePasswordService service;

  ChangePasswordRepository(this.service);

  Future<Map<String, dynamic>> changePassword({
    required String username,
    required String oldPass,
    required String newPass,
    required String newPassConfirmation,
    required String token,
  }) {
    return service.changePassword(
      username: username,
      old_Pass: oldPass,
      new_Pass: newPass,
      new_Pass_Confirmation: newPassConfirmation,
      token: token,
    );
  }
}
