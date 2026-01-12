import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../models/adsl_traffic_model.dart';

class AdslTrafficService {
  final Dio _dio = ApiConfig.createDio(
    contentType: Headers.formUrlEncodedContentType,
  );

  Future<AdslTrafficResponse> getAdslTraffic(String username, {String? token}) async {
    try {
      final options = Options();
      if (token != null && token.isNotEmpty) {
        options.headers = {'Authorization': 'Bearer $token'};
      }

      final response = await _dio.post(
        '/getAdslTraffic',
        options: options,
        data: FormData.fromMap({'username': username}),
      );

      return AdslTrafficResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
