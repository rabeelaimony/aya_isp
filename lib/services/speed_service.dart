import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api_config.dart';

class SpeedPackage {
  final String id;
  final String name;
  final int speedVal;
  final String price;
  final String? quota;
  final String? accType;
  final String? defaultAttributes;

  SpeedPackage({
    required this.id,
    required this.name,
    required this.speedVal,
    required this.price,
    this.quota,
    this.accType,
    this.defaultAttributes,
  });

  factory SpeedPackage.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return SpeedPackage(
      id: json['PackageId']?.toString() ?? '',
      name: json['PackageName']?.toString() ?? '',
      speedVal: parseInt(json['speed']),
      price: json['Price']?.toString() ?? '',
      quota: json['quota']?.toString(),
      accType: json['acctype']?.toString(),
      defaultAttributes: json['default_attributes']?.toString(),
    );
  }
}

class SpeedChangeResult {
  final bool status;
  final String? message;
  final int? newSpeed;

  SpeedChangeResult({required this.status, this.message, this.newSpeed});
}

class SpeedService {
  final Dio _dio;

  SpeedService({Dio? dio})
    : _dio =
          dio ??
          ApiConfig.createDio(contentType: Headers.formUrlEncodedContentType);

  Future<List<SpeedPackage>> getSpeedPackages({
    required String accType,
    required String bearerToken,
  }) async {
    final response = await _dio.post(
      '/getSpeedPackage',
      options: Options(
        headers: {'Authorization': 'Bearer $bearerToken'},
        validateStatus: (_) => true,
      ),
      data: FormData.fromMap({'acctype': accType}),
    );

    if (response.statusCode != null &&
        (response.statusCode! < 200 || response.statusCode! >= 300)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: response.data,
      );
    }

    final raw = response.data;
    List<dynamic>? list;
    if (raw is Map<String, dynamic>) {
      if (raw['message'] is List) {
        list = raw['message'] as List<dynamic>;
      } else if (raw['data'] is List) {
        list = raw['data'] as List<dynamic>;
      }
    } else if (raw is List) {
      list = raw;
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) list = decoded;
        if (decoded is Map && decoded['message'] is List) {
          list = decoded['message'] as List<dynamic>;
        }
      } catch (_) {}
    }

    if (list == null) {
      throw Exception('Unexpected speed package response: ${response.data}');
    }

    return list
        .whereType<Map>()
        .map((e) => SpeedPackage.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  Future<SpeedChangeResult> changeSpeed({
    required String username,
    required int speedId,
    required int speedVal,
    required String bearerToken,
  }) async {
    final response = await _dio.post(
      '/chanespeed',
      options: Options(
        headers: {'Authorization': 'Bearer $bearerToken'},
        validateStatus: (_) => true,
      ),
      data: FormData.fromMap({
        'username': username,
        'speedId': speedId.toString(),
        'speedVal': speedVal.toString(),
      }),
    );

    if (response.statusCode != null &&
        (response.statusCode! < 200 || response.statusCode! >= 300)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: response.data,
      );
    }

    Map<String, dynamic>? map;
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      map = raw;
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) map = decoded;
      } catch (_) {
        map = {'message': raw};
      }
    }

    final message = map?['message']?.toString();
    final status =
        (map?['status'] == true ||
        map?['status']?.toString().toLowerCase() == 'success' ||
        map?['status']?.toString() == 'true');

    int? parsedNewSpeed;
    if (map?['new_speed'] != null) {
      if (map!['new_speed'] is int) {
        parsedNewSpeed = map['new_speed'] as int;
      } else {
        parsedNewSpeed = int.tryParse(map['new_speed'].toString());
      }
    }

    return SpeedChangeResult(
      status: status,
      message: message,
      newSpeed: parsedNewSpeed,
    );
  }
}
