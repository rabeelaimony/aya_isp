import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../models/session_detail_model.dart';

class SessionDetailService {
  final Dio _dio = ApiConfig.createDio(
    contentType: Headers.formUrlEncodedContentType,
  );

  Future<SessionDetailResponse> getSessionDetails({
    required String username,
    required int year,
    required int month,
    int page = 1,
    int perPage = 10,
    String? token,
  }) async {
    try {
      final options = Options();
      if (token != null && token.isNotEmpty) {
        options.headers = {'Authorization': 'Bearer $token'};
      }

      final response = await _dio.post(
        '/get_session_detail',
        options: options,
        data: FormData.fromMap({
          'username': username,
          'year': year,
          'month': month,
          'page': page,
          'per_page': perPage,
        }),
      );

      final dynamic raw = response.data;
      final Map<String, dynamic> decoded = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return SessionDetailResponse.fromJson(decoded);
    } catch (e) {
      rethrow;
    }
  }
}
