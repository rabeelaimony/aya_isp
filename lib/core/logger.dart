import 'package:logger/logger.dart';

// ✅ Logger عام للمشروع
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // عدد الأسطر من الـ stack trace
      errorMethodCount: 5, // عدد الأسطر عند الخطأ
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void d(dynamic message) => _logger.d(message); // Debug
  static void i(dynamic message) => _logger.i(message); // Info
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace); // Warning
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace); // Error
}
