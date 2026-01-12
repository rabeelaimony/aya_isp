import 'package:package_info_plus/package_info_plus.dart';

import 'logger.dart';

/// Captures metadata that other layers can reuse (e.g., headers).
class AppInfo {
  AppInfo._();

  static String version = '0.0.0';

  static Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
    } catch (error, stackTrace) {
      AppLogger.w('Failed to load package info', error, stackTrace);
    }
  }
}
