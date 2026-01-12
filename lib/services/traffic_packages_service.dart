import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../core/logger.dart';

class TrafficPackagesService {
  final Dio dio = ApiConfig.createDio(
    contentType: Headers.formUrlEncodedContentType,
  )..options.validateStatus =
      (status) => true; // السماح بتجاوز فحص statusCode لقراءة الجسم

  Future<List<dynamic>> fetchPackages() async {
    final response = await dio.get("/get_extra_packages");

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey("data")) {
        AppLogger.d("TrafficPackagesService response: ${data["data"]}");
        return data["data"];
      } else {
        throw Exception("هيكل بيانات غير متوقع: $data");
      }
    } else {
      AppLogger.e("Traffic packages fetch failed, status: ${response.statusCode}");
      throw Exception("فشل جلب الحزم الإضافية");
    }
  }
}
