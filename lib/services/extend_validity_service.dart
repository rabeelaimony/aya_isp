import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../models/extend_validity_response.dart';

class ExtendValidityService {
  final Dio _dio = ApiConfig.createDio(
    contentType: Headers.formUrlEncodedContentType,
  )..options.validateStatus = (status) => true;

  Future<ExtendValidityResponse> extendExpiry({
    required String username,
    required String token,
  }) async {
    final response = await _dio.post(
      '/expand_expiry',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
      data: FormData.fromMap({'username': username}),
    );

    if (response.statusCode != null && response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Request failed with status ${response.statusCode}',
      );
    }

    final body = response.data;

    if (body is Map<String, dynamic>) {
      return ExtendValidityResponse.fromJson(body);
    }

    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return ExtendValidityResponse.fromJson(decoded);
        }
      } catch (_) {
        // ignore and fall through to error
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: 'Unexpected body while extending expiry',
    );
  }
}
