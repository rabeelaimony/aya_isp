import 'package:dio/dio.dart';

import '../core/api_config.dart';

class ChangePasswordService {
  final Dio dio = ApiConfig.createDio(
    contentType: Headers.formUrlEncodedContentType,
  );

  Future<Map<String, dynamic>> changePassword({
    required String username,
    required String old_Pass,
    required String new_Pass,
    required String new_Pass_Confirmation,
    required String token,
  }) async {
    final formData = FormData.fromMap({
      // ✅ المفاتيح مطابقة للسيرفر مع underscores
      "username": username,
      "old_pass": old_Pass,
      "new_pass": new_Pass,
      "new_pass_confirmation": new_Pass_Confirmation,
    });

    try {
      final response = await dio.post(
        "/change_password",
        options: Options(headers: {"Authorization": "Bearer $token"}),
        data: formData,
      );

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw Exception("الاستجابة غير متوقعة: ${response.data}");
      }
    } on DioException catch (e) {
      // If server returned a response body (e.g., JSON with msg/status), return it
      final resp = e.response;
      if (resp != null && resp.data is Map<String, dynamic>) {
        return resp.data as Map<String, dynamic>;
      }
      // otherwise rethrow so higher layers can handle network/server error
      rethrow;
    }
  }
}
