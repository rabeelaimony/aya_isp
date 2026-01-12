import 'dart:convert';

import 'package:dio/dio.dart';

import 'force_update_service.dart';

class ForceUpdateDetector {
  ForceUpdateDetector._();

  static void check(Response<dynamic> response) {
    try {
      final payload = _toMap(response.data);
      if (payload == null) return;

      final code = payload['code']?.toString().toUpperCase();
      final data = _toMap(payload['data']);
      final forceFlag = _toBoolean(data?['force_update']) ?? false;

      if (code != 'FORCE_UPDATE' && !forceFlag) return;

      final info = ForceUpdateInfo(
        force: true,
        message: payload['message']?.toString() ?? data?['message']?.toString(),
        storeUrl: data?['store_url']?.toString(),
        latestVersion: data?['latest_version']?.toString(),
        minVersion: data?['min_version']?.toString(),
      );

      ForceUpdateService.instance.notify(info);
    } catch (_) {
      // Swallow any parsing errors; detection is best-effort.
    }
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  static bool? _toBoolean(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final trimmed = raw.trim().toLowerCase();
      if (trimmed.isEmpty) return null;
      if (trimmed == 'true' || trimmed == '1' || trimmed == 'yes') return true;
      if (trimmed == 'false' || trimmed == '0' || trimmed == 'no') return false;
    }
    return null;
  }
}
