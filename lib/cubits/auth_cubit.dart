import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aya_isp/services/notification_center.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/login_model.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';
import '../core/error_handler.dart';

part 'auth_state.dart';

class LogoutResult {
  final bool success;
  final String message;

  const LogoutResult({required this.success, required this.message});
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial());

  Future<void> login(String name, String password) async {
    emit(AuthLoading());

    try {
      final prefs = await SharedPreferences.getInstance();

      String? fcmToken = prefs.getString("fcm_token");
      if (fcmToken == null || fcmToken.isEmpty) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await prefs.setString("fcm_token", fcmToken);
          }
        } catch (_) {
          fcmToken = null;
        }
      }

      final result = await _authService.login(
        name,
        password,
        fcmToken: fcmToken,
      );

      if (result.status == "success" && result.data != null) {
        final account = StoredAccount(
          userId: result.data!.userId,
          username: name,
          token: result.data!.token,
          displayName: result.data!.name,
          lastUsed: DateTime.now(),
        );

        await SessionManager.upsertAccount(account, setActive: true);

        NotificationCenter.instance.setCurrentUser(
          account.userId.toString(),
          resetHistory: true,
        );

        emit(AuthSuccess(result.data!));
      } else {
        emit(AuthFailure(result.message ?? "خطاء في تسجيل الدخول"));
      }
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      emit(AuthFailure(message));
    }
  }

  Future<LogoutResult> logout() async {
    final activeAccount = await SessionManager.getActiveAccount();
    final token = activeAccount?.token;
    final username = activeAccount?.username;
    final userId = activeAccount?.userId;

    LogoutResult result;

    try {
      if (token != null &&
          token.isNotEmpty &&
          username != null &&
          username.isNotEmpty &&
          userId != null) {
        final response = await _authService.logout(
          userId: userId,
          name: username,
          token: token,
        );

        if (response.isSuccess) {
          result = const LogoutResult(
            success: true,
            message: "تم تسجيل الخروج بنجاح",
          );
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          result = const LogoutResult(
            success: true,
            message: "انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً",
          );
        } else if (response.statusCode >= 500) {
          result = const LogoutResult(
            success: false,
            message: "حدث خطأ في السيرفر، حاول لاحقاً",
          );
        } else {
          result = const LogoutResult(
            success: false,
            message: "تعذر تسجيل الخروج الآن، حاول لاحقاً",
          );
        }
      } else {
        result = const LogoutResult(success: true, message: "تم تسجيل الخروج");
      }
    } catch (_) {
      result = const LogoutResult(
        success: false,
        message: "تعذر الاتصال بالسيرفر، حاول لاحقاً",
      );
    } finally {
      if (activeAccount != null) {
        await SessionManager.removeAccount(activeAccount.userId);
      }
      await SessionManager.clearActiveSession();
      emit(AuthInitial());
    }

    return result;
  }
}
