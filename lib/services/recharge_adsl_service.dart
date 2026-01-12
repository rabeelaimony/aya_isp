import 'dart:convert';
import 'package:dio/dio.dart';

import '../core/api_config.dart';

class RechargeAdslService {
  final Dio dio;

  RechargeAdslService() : dio = ApiConfig.createDio();

  Future<Map<String, dynamic>> rechargeAdsl({
    required String username,
    required int duration,
    required String token,
  }) async {
    final response = await dio.post(
      '/rechargeAdsl',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: FormData.fromMap({
        'username': username,
        'duration': duration.toString(),
      }),
    );

    final raw = response.data;

    if (raw is Map<String, dynamic>) return raw;

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
      return {'status': 'error', 'message': raw};
    }

    return {'status': 'error', 'message': raw?.toString() ?? 'Empty response'};
  }
}
