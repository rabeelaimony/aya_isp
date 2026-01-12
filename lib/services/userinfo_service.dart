import 'dart:convert';
import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../core/logger.dart';
import '../models/userinfo_model.dart';

class UserInfoService {
  final Dio _dio = ApiConfig.createDio(
    contentType: Headers.formUrlEncodedContentType,
  )..options.responseType = ResponseType.plain;

  Future<UserInfoResponse> getUserInfo(String token, String username) async {
    try {
      final response = await _dio.post(
        "/getUserInfo",
        options: Options(headers: {"Authorization": "Bearer $token"}),
        data: FormData.fromMap({"username": username}),
      );

      // ✅ جرّب مباشرةً
      dynamic decoded;
      try {
        decoded = jsonDecode(response.data);
      } catch (_) {
        // fallback: جرّب latin1
        decoded = jsonDecode(latin1.decode(response.data.codeUnits));
      }

      AppLogger.d("UserInfoService response: $decoded");
      return UserInfoResponse.fromJson(decoded);
    } catch (e) {
      AppLogger.e("UserInfoService error", e);
      rethrow;
    }
  }
}
