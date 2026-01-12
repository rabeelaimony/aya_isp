import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../core/logger.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      AppLogger.e("DioException", error, error.stackTrace);

      // Prefer any meaningful message coming from the server, regardless of type.
      final serverMessage = _extractServerMessage(error.response?.data);
      if (serverMessage != null && serverMessage.isNotEmpty) {
        return _finalizeMessage(serverMessage);
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return _finalizeMessage(
            'انتهت مهلة الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى.',
          );

        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          switch (code) {
            case 401:
              return _finalizeMessage('غير مصرح. يرجى تسجيل الدخول مرة أخرى.');
            case 403:
              return _finalizeMessage('لا تملك صلاحية الوصول.');
            case 404:
              return _finalizeMessage('الخدمة غير موجودة.');
            case 502:
            case 504:
            case 500:
            case 503:
            case 522:
            case 524:
              return _finalizeMessage('الخادم غير متاح حالياً. حاول لاحقاً.');
            default:
              return _finalizeMessage('حدث خطأ غير متوقع في الخادم.');
          }

        case DioExceptionType.connectionError:
          return _finalizeMessage(
            'لا يوجد اتصال بالانترنت. تحقق من الشبكة وحاول مرة أخرى.',
          );

        case DioExceptionType.unknown:
          final mapped = _mapUnexpected(error.error);
          if (mapped != null) return _finalizeMessage(mapped);
          return _finalizeMessage('حدث خطأ غير متوقع.');

        default:
          return _finalizeMessage('حدث خطأ غير متوقع.');
      }
    }

    AppLogger.e("Unexpected Error", error);
    return _finalizeMessage(_mapUnexpected(error) ?? 'حدث خطأ غير متوقع.');
  }

  static String? _extractServerMessage(dynamic data) {
    if (data is List<int>) {
      try {
        final decoded = utf8.decode(data, allowMalformed: true).trim();
        if (decoded.isNotEmpty) {
          return _extractServerMessage(decoded);
        }
      } catch (_) {
        // ignore decode failures
      }
    }

    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty && !_looksLikeHtml(msg)) {
        final cleaned = _sanitizeMessage(msg);
        if (cleaned.isNotEmpty) return cleaned;
      }

      final errors =
          data['errors'] ?? data['error'] ?? data['validationErrors'];
      if (errors != null) {
        if (errors is Map) {
          final msgs = <String>[];
          errors.forEach((k, v) {
            if (v is List && v.isNotEmpty) {
              msgs.add(v.first.toString());
            } else if (v is String && v.trim().isNotEmpty) {
              msgs.add(v.trim());
            } else if (v != null) {
              msgs.add(v.toString());
            }
          });
          if (msgs.isNotEmpty) {
            final joined = msgs.join('? ');
            final cleaned = _sanitizeMessage(joined);
            if (cleaned.isNotEmpty) return cleaned;
          }
        }

        if (errors is List) {
          final msgs = errors
              .where((e) => e != null)
              .map((e) => e.toString())
              .toList();
          if (msgs.isNotEmpty) {
            final joined = msgs.join('? ');
            final cleaned = _sanitizeMessage(joined);
            if (cleaned.isNotEmpty) return cleaned;
          }
        }
      }
    } else if (data is String && data.trim().isNotEmpty) {
      final raw = data.trim();
      final proxyMessage = _mapProxyMessage(raw);
      if (proxyMessage != null) return proxyMessage;
      try {
        final decoded = jsonDecode(raw);
        final decodedMessage = _extractServerMessage(decoded);
        if (decodedMessage != null && decodedMessage.isNotEmpty) {
          return decodedMessage;
        }
      } catch (_) {
        // Not JSON, fall back to plain text handling.
      }

      final trimmed = _sanitizeMessage(raw);
      if (trimmed.isNotEmpty && !_looksLikeHtml(trimmed)) return trimmed;
    }
    return null;
  }

  static String extractMessage(dynamic data) {
    final msg = _extractServerMessage(data);
    if (msg != null && msg.isNotEmpty) return msg;
    return getErrorMessage(data);
  }

  static String? _mapUnexpected(dynamic error) {
    if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى.';
    }
    if (error is SocketException) {
      return 'لا يوجد اتصال بالانترنت. تحقق من الشبكة وحاول مرة أخرى.';
    }
    if (error is HandshakeException) {
      return 'فشل التحقق من شهادة الاتصال الآمن.';
    }
    return null;
  }

  static String? _mapProxyMessage(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('error occurred while trying to proxy')) {
      return 'تعذر الوصول إلى الخادم . حاول لاحقاً.';
    }
    if (lower.contains('gateway timeout') || lower.contains('bad gateway')) {
      return 'الخادم غير متاح حالياً. حاول لاحقاً.';
    }
    return null;
  }

  static bool _looksLikeHtml(String text) {
    final lower = text.toLowerCase();
    return lower.startsWith('<!doctype') ||
        lower.startsWith('<html') ||
        lower.contains('<head') ||
        lower.contains('<body');
  }

  static String _sanitizeMessage(String text) {
    // Strip any technical prefixes or English exception words.
    var cleaned = text.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:Unhandled\s+Exception|Exception\s+has\s+occurred\.?|Exception|DioException|Error)\s*[:\-]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bException\b[:\-]?\s*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bDioException\b[:\-]?\s*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bUnhandled\b[:\-]?\s*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bError\b[:\-]?\s*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ');
    return cleaned.trim();
  }

  static String _finalizeMessage(String? message) {
    final sanitized = _sanitizeMessage(message ?? '');
    if (sanitized.isNotEmpty) return sanitized;
    return 'حدث خطأ غير متوقع.';
  }
}
