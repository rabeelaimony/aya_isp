import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api_config.dart';

class ExpandTrafficService {
  final Dio dio;

  ExpandTrafficService() : dio = ApiConfig.createDio();

  Future<Map<String, dynamic>> expandTrafficSelection({
    required String username,
    required int reqSize,
    required String token,
  }) async {
    final response = await dio.post(
      '/expand_trafic_selection',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      data: FormData.fromMap({
        'username': username,
        'reqsize': reqSize.toString(),
      }),
    );
    final raw = response.data;

    if (raw is Map<String, dynamic>) return raw;

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}

      return <String, dynamic>{'status': 'error', 'message': raw};
    }

    return <String, dynamic>{
      'status': 'error',
      'message': raw?.toString() ?? 'Empty response',
    };
  }
}
