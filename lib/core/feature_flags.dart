import 'package:aya_isp/services/login_check_service.dart';

enum LoginCheckStatus { working, notWorking, unavailable }

class LoginCheckResult {
  final LoginCheckStatus status;
  final String? message;

  const LoginCheckResult(this.status, {this.message});
}

class FeatureFlags {
  FeatureFlags._();

  // Set true to always force the simplified experience.
  static const bool forceSimplifiedApp = false;

  static Future<LoginCheckResult> loginCheckStatus() async {
    if (forceSimplifiedApp) {
      return const LoginCheckResult(LoginCheckStatus.notWorking);
    }
    return LoginCheckService().checkStatus();
  }
}
