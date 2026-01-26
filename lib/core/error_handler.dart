import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../core/logger.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      AppLogger.e("DioException", error, error.stackTrace);

      // ✅ خذ رسالة السيرفر فقط إذا كانت آمنة (ليست تقنية)
      final initialServerMessage = _extractServerMessage(error.response?.data);
      if (initialServerMessage != null &&
          initialServerMessage.isNotEmpty &&
          !_isTechnicalMessage(initialServerMessage)) {
        return _finalizeMessage(initialServerMessage);
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

          // 1) جرّب رسالة السيرفر مرة ثانية (إذا آمنة)
          final serverMessage = _extractServerMessage(error.response?.data);
          if (serverMessage != null &&
              serverMessage.isNotEmpty &&
              !_isTechnicalMessage(serverMessage)) {
            return _finalizeMessage(serverMessage);
          }

          // 2) fallback حسب status code
          switch (code) {
            case 400:
              return _finalizeMessage('طلب غير صالح.');
            case 401:
              return _finalizeMessage('غير مصرح. يرجى تسجيل الدخول مرة أخرى.');
            case 403:
              return _finalizeMessage('لا تملك صلاحية الوصول.');
            case 404:
              return _finalizeMessage('الخدمة غير موجودة.');
            case 409:
              return _finalizeMessage('يوجد تعارض بالبيانات. حاول مرة أخرى.');
            case 422:
              return _finalizeMessage('البيانات المرسلة غير صحيحة.');
            case 429:
              return _finalizeMessage('عدد طلبات كبير. حاول لاحقاً.');
            case 500:
            case 502:
            case 503:
            case 504:
            case 520:
            case 522:
            case 524:
              return _finalizeMessage('الخادم غير متاح حالياً. حاول لاحقاً.');
            default:
              // 3) إذا الكود null أو غير معروف
              if (code == null) {
                return _finalizeMessage('حدث خطأ في الاتصال بالخادم.');
              }
              // إذا ما بدك تعرض الرمز للمستخدم، احذف (رمز $code)
              return _finalizeMessage(
                'حدث خطأ غير متوقع في الخادم. (رمز $code)',
              );
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
        if (decoded.isNotEmpty) return _extractServerMessage(decoded);
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
          errors.forEach((_, v) {
            if (v is List && v.isNotEmpty) {
              msgs.add(v.first.toString());
            } else if (v is String && v.trim().isNotEmpty) {
              msgs.add(v.trim());
            } else if (v != null) {
              msgs.add(v.toString());
            }
          });
          if (msgs.isNotEmpty) {
            final joined = msgs.join('، ');
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
            final joined = msgs.join('، ');
            final cleaned = _sanitizeMessage(joined);
            if (cleaned.isNotEmpty) return cleaned;
          }
        }
      }
    } else if (data is String && data.trim().isNotEmpty) {
      final raw = data.trim();

      final proxyMessage = _mapProxyMessage(raw);
      if (proxyMessage != null) return proxyMessage;

      // لو رجع JSON كنص
      try {
        final decoded = jsonDecode(raw);
        final decodedMessage = _extractServerMessage(decoded);
        if (decodedMessage != null && decodedMessage.isNotEmpty) {
          return decodedMessage;
        }
      } catch (_) {
        // Not JSON
      }

      final trimmed = _sanitizeMessage(raw);
      if (trimmed.isNotEmpty && !_looksLikeHtml(trimmed)) return trimmed;
    }

    return null;
  }

  static String extractMessage(dynamic data) {
    final msg = _extractServerMessage(data);
    if (msg != null && msg.isNotEmpty && !_isTechnicalMessage(msg)) {
      return _finalizeMessage(msg);
    }
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
      return 'تعذر الوصول إلى الخادم. حاول لاحقاً.';
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
    var cleaned = text.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:Unhandled\s+Exception|Exception\s+has\s+occurred\.?|Exception|DioException|Error)\s*[:\-]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(Exception|DioException|Unhandled|Error)\b[:\-]?\s*',
        caseSensitive: false,
      ),
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

  /// ✅ فلتر: يمنع إظهار رسائل Laravel/PHP التقنية (paths/stack traces)
  static bool _isTechnicalMessage(String text) {
    final s = text.toLowerCase();

    const keywords = [
      'php fatal',
      'fatal error',
      'stack trace',
      'syntax error',
      'undefined',
      'exception',
      'sqlstate',
      'laravel',
      'eloquent',
      'internaldb',
      'vendor/',
      ' on line ',
      ' in ',
      'trace',
    ];

    for (final k in keywords) {
      if (s.contains(k)) return true;
    }

    final hasPath = RegExp(
      r'([a-zA-Z]:\\|/var/www|/home/|/srv/|/opt/)\S+',
    ).hasMatch(text);

    final hasPhpLine = RegExp(
      r'\.php\b|\bline\s+\d+\b',
      caseSensitive: false,
    ).hasMatch(text);

    return hasPath || hasPhpLine;
  }
}
