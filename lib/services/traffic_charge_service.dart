import 'package:dio/dio.dart';

import '../core/api_config.dart';

class TrafficChargeService {
  final Dio dio;

  TrafficChargeService()
    : dio = ApiConfig.createDio(
        contentType: Headers.formUrlEncodedContentType,
      ) {
    dio.options.validateStatus = (int? _) => true;
  }

  Future<Map<String, dynamic>> chargePackage({
    required String username,
    required String packageId,
    required String token,
  }) async {
    final response = await dio.post(
      "/charge_extra_traffic",
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
      ),
      data: {"username": username, "packageId": packageId},
    );

    return response.data;
  }
}
