import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'app_info.dart';
import 'app_navigator.dart';
import 'force_update_detector.dart';
import 'ui.dart';

/// Provides a unified API client configuration that prefers HTTPS and
/// transparently falls back to HTTP for the existing backend if TLS
/// is unavailable. Also retries مرة واحدة على الأخطاء العابرة لتفادي
/// ظهور خطأ الاتصال في المحاولة الأولى.
class ApiConfig {
  // Secure proxy endpoint required for the Google Play build.
  static const String primaryBaseUrl = 'https://api-mobile.proxy.aya.sy/api';
  static const String fallbackBaseUrl = 'https://api-mobile.proxy.aya.sy/api';
  static const String _retryKey = '_api_retry_attempts';
  static const String _slowHintKey = '_slow_hint_timer';
  static const int _maxTransientRetries = 2;
  static const Duration _slowHintDelay = Duration(seconds: 10);

  /// Create a Dio instance configured for the Aya ISP API.
  /// If an HTTPS handshake fails, the interceptor retries once over HTTP,
  /// ثم يعيد المحاولة مرة واحدة أخرى للأخطاء العابرة (timeouts/connection).
  static Dio createDio({Map<String, dynamic>? headers, String? contentType}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: primaryBaseUrl,
        headers: _mergeHeaders(headers),
        contentType: contentType,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final timer = Timer(_slowHintDelay, () {
            final ctx = appNavigatorKey.currentContext;
            if (ctx == null || !ctx.mounted) return;
            showSlowConnectionHint(ctx);
          });
          options.extra[_slowHintKey] = timer;
          handler.next(options);
        },
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          final timer = err.requestOptions.extra[_slowHintKey];
          if (timer is Timer) {
            timer.cancel();
          }
          final attempts = (err.requestOptions.extra[_retryKey] as int?) ?? 0;

          // 1) HTTPS -> HTTP fallback on TLS/connection errors
          if (_shouldFallback(err, dio)) {
            final retryReq = _cloneRequest(err.requestOptions);
            retryReq.baseUrl = fallbackBaseUrl;
            retryReq.extra[_retryKey] = attempts + 1;
            dio.options.baseUrl = fallbackBaseUrl;
            try {
              final retryResponse = await dio.fetch(retryReq);
              return handler.resolve(retryResponse);
            } catch (_) {
              // continue to next step
            }
          }

          // 2) Retry transient network errors (a couple of times)
          if (attempts < _maxTransientRetries && _isTransient(err)) {
            final retryReq = _cloneRequest(err.requestOptions);
            retryReq.extra[_retryKey] = attempts + 1;
            try {
              await Future.delayed(const Duration(milliseconds: 220));
              final retryResponse = await dio.fetch(retryReq);
              return handler.resolve(retryResponse);
            } catch (_) {
              // fallthrough to original error
            }
          }

          if (err.response != null) {
            ForceUpdateDetector.check(err.response!);
          }

          handler.next(err);
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final timer = response.requestOptions.extra[_slowHintKey];
          if (timer is Timer) {
            timer.cancel();
          }
          ForceUpdateDetector.check(response);
          handler.next(response);
        },
      ),
    );

    return dio;
  }

  static Map<String, dynamic> _mergeHeaders(
    Map<String, dynamic>? overrideHeaders,
  ) {
    final result = <String, dynamic>{
      'X-Platform': 'android',
      'X-App-Version': AppInfo.version,
    };
    if (overrideHeaders != null) {
      result.addAll(overrideHeaders);
    }
    return result;
  }

  static bool _shouldFallback(DioException err, Dio dio) {
    if (dio.options.baseUrl == fallbackBaseUrl) return false;
    if (err.type == DioExceptionType.badCertificate ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.unknown) {
      if (err.error is HandshakeException ||
          err.error is SocketException ||
          err.type == DioExceptionType.badCertificate ||
          err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.connectionError) {
        return true;
      }
    }
    return false;
  }

  static bool _isTransient(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.type == DioExceptionType.unknown &&
            (err.error is SocketException));
  }

  static RequestOptions _cloneRequest(RequestOptions original) {
    dynamic clonedData = original.data;
    if (original.data is FormData) {
      final builder = original.extra['formDataBuilder'];
      if (builder is FormData Function()) {
        clonedData = builder();
      }
    }

    return RequestOptions(
      path: original.path,
      method: original.method,
      baseUrl: original.baseUrl,
      queryParameters: Map<String, dynamic>.from(original.queryParameters),
      data: clonedData,
      headers: Map<String, dynamic>.from(original.headers),
      extra: Map<String, dynamic>.from(original.extra),
      contentType: original.contentType,
      responseType: original.responseType,
      followRedirects: original.followRedirects,
      listFormat: original.listFormat,
      maxRedirects: original.maxRedirects,
      receiveTimeout: original.receiveTimeout,
      sendTimeout: original.sendTimeout,
      receiveDataWhenStatusError: original.receiveDataWhenStatusError,
      requestEncoder: original.requestEncoder,
      responseDecoder: original.responseDecoder,
      validateStatus: original.validateStatus,
    );
  }
}
