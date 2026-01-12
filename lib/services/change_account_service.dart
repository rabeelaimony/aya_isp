import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../core/api_config.dart';

class ChangeAccountService {
  final Dio dio;

  ChangeAccountService() : dio = ApiConfig.createDio();

  Future<Map<String, dynamic>> changeToVip({
    required String username,
    required String token,
  }) async {
    final response = await dio.post(
      '/changeToVip',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: FormData.fromMap({'username': username}),
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

  Future<Map<String, dynamic>> changeToNakaba({
    required String username,
    required String token,
    required String nakabaNumber,
    required int nakabaId,
    required String imagePath,
  }) async {
    final fileName = imagePath.split('/').last;
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    String mimeType = 'jpeg';
    if (ext == 'png') mimeType = 'png';
    final multipart = await MultipartFile.fromFile(
      imagePath,
      filename: fileName,
      contentType: MediaType('image', mimeType),
    );

    final form = FormData.fromMap({
      'username': username,
      'nakabaNumber': nakabaNumber,
      // send as integer (server may expect numeric field)
      'nakabaId': nakabaId,
      'nakabaImgFile': multipart,
    });

    // Note: Postman used '/changetonakaba' — use that path to match server
    Response response;
    try {
      response = await dio.post(
        '/changetonakaba',
        // accept any status so we can read server error payloads (422 etc.)
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
        data: form,
      );
    } catch (e) {
      // network or unexpected error
      return {'status': 'error', 'message': e.toString()};
    }

    // If server returned non-2xx, return its payload so caller can show server message
    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      final rawErr = response.data;
      if (rawErr is Map<String, dynamic>) return rawErr;
      if (rawErr is String) {
        try {
          final decoded = jsonDecode(rawErr);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
        return {'status': 'error', 'message': rawErr};
      }
      return {
        'status': 'error',
        'message': 'Server returned status ${response.statusCode}',
      };
    }

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
