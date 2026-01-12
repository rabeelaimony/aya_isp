import 'package:shared_preferences/shared_preferences.dart';

/// Caches normalized mobile numbers per username for notification requests.
class UserMobileCache {
  static const _prefix = 'user_mobile_';

  static String _key(String username) => '$_prefix${username.toLowerCase()}';

  static Future<void> save(String username, String? mobile) async {
    final normalized = normalize(mobile);
    if (normalized == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(username), normalized);
  }

  static Future<String?> read(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key(username));
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (!digits.startsWith('963')) {
      digits = '963$digits';
    }
    return digits;
  }
}
