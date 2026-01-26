import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../core/app_info.dart';
import '../core/error_handler.dart';
import '../core/feature_flags.dart';

class LoginCheckService {
  static const String _baseUrl = 'http://api-services.aya.sy/api';

  final Dio _dio;

  LoginCheckService([Dio? dio]) : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final dio = ApiConfig.createDio(
      headers: {
        'X-App-Version': AppInfo.version,
        'Platform': _resolvePlatform(),
      },
    );
    dio.options.baseUrl = _baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 6);
    dio.options.receiveTimeout = const Duration(seconds: 6);
    return dio;
  }

  Future<LoginCheckResult> checkStatus() async {
    try {
      final response = await _dio.get('/loginCheack');
      final message = _extractMessage(response.data);
      if (message == null) {
        return const LoginCheckResult(LoginCheckStatus.unavailable);
      }
      final normalized = message.trim().toLowerCase();
      if (normalized == 'the login function working now') {
        return const LoginCheckResult(LoginCheckStatus.working);
      }
      if (normalized == 'the login function not working now') {
        return const LoginCheckResult(LoginCheckStatus.notWorking);
      }
      return LoginCheckResult(LoginCheckStatus.unavailable, message: message);
    } on DioException catch (error) {
      return LoginCheckResult(
        LoginCheckStatus.unavailable,
        message: ErrorHandler.getErrorMessage(error),
      );
    } catch (error) {
      return LoginCheckResult(
        LoginCheckStatus.unavailable,
        message: ErrorHandler.getErrorMessage(error),
      );
    }
  }

  static String _resolvePlatform() {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['Message']?.toString() ?? data['message']?.toString();
    }
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded['Message']?.toString() ??
              decoded['message']?.toString();
        }
      } catch (_) {}
    }
    return null;
  }
}
