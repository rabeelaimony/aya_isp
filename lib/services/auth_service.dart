import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../models/login_model.dart';

class LogoutApiResponse {
  final int statusCode;
  final String? status;
  final bool? data;

  const LogoutApiResponse({
    required this.statusCode,
    required this.status,
    required this.data,
  });

  bool get isSuccess =>
      statusCode == 200 && status == 'success' && data == true;
}

class AuthService {
  final Dio _dio = ApiConfig.createDio(
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
  );

  Future<LoginResponse> login(
    String name,
    String password, {
    String? fcmToken,
  }) async {
    final Map<String, dynamic> map = {"name": name, "password": password};
    if (fcmToken != null && fcmToken.isNotEmpty) {
      map['fcmToken'] = fcmToken;
    }

    final response = await _postWithRetry(
      path: "/login",
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        extra: {'formDataBuilder': () => FormData.fromMap(map)},
      ),
      formDataBuilder: () => FormData.fromMap(map),
    );

    return LoginResponse.fromJson(response.data);
  }

  Future<LogoutApiResponse> logout({
    required int userId,
    required String name,
    required String token,
  }) async {
    final payloadMap = {
      'name': name,
      'userId': userId,
    };

    final response = await _postWithRetry(
      path: "/logout",
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        headers: {"Authorization": "Bearer $token"},
        validateStatus: (_) => true,
        extra: {'formDataBuilder': () => FormData.fromMap(payloadMap)},
      ),
      formDataBuilder: () => FormData.fromMap(payloadMap),
    );

    dynamic body = response.data;
    if (body is String && body.trim().isNotEmpty) {
      try {
        body = jsonDecode(body);
      } catch (_) {
        // keep raw string
      }
    }

    String? status;
    bool? data;
    if (body is Map) {
      status = body['status']?.toString();
      final rawData = body['data'];
      if (rawData is bool) data = rawData;
      if (rawData is String) data = rawData.toLowerCase() == 'true';
      if (rawData is num) data = rawData != 0;
    }

    return LogoutApiResponse(
      statusCode: response.statusCode ?? 0,
      status: status,
      data: data,
    );
  }

  Future<Response<dynamic>> _postWithRetry({
    required String path,
    required Options options,
    int maxAttempts = 2,
    dynamic data,
    FormData Function()? formDataBuilder,
  }) async {
    DioException? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final requestData =
            formDataBuilder != null ? formDataBuilder() : data;
        return await _dio.post(path, data: requestData, options: options);
      } on DioException catch (e) {
        lastError = e;
        final isTransient = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            (e.type == DioExceptionType.unknown && e.error is SocketException);
        if (!isTransient || attempt == maxAttempts - 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    throw lastError!;
  }
}
