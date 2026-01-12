import '../core/user_mobile_cache.dart';
import 'notification_center.dart';
import 'notification_service.dart';
import 'session_manager.dart';

/// Fetches notifications once per app session so the badge can show unread
/// counts even before the user opens the notifications screen.
class NotificationPrefetcher {
  static bool _isFetching = false;
  static String? _lastFetchedUserId;

  /// Preload notifications for the current user if we have a stored session.
  /// When [force] is true we fetch even if we already prefetched for the same
  /// user in this app run (useful right after a fresh login).
  static Future<void> fetchOncePerSession({bool force = false}) async {
    if (_isFetching) return;

    final active = await SessionManager.getActiveAccount();
    if (active == null) return;

    final userIdStr = active.userId.toString();
    if (!force && _lastFetchedUserId == userIdStr) return;

    _isFetching = true;
    try {
      NotificationCenter.instance.setCurrentUser(
        userIdStr,
        resetHistory: false,
      );

      final identifier = await UserMobileCache.read(active.username) ??
          active.userId.toString();
      final page = await NotificationService().fetchNotifications(
        userId: active.userId,
        userIdentifier: identifier,
        bearerToken: active.token,
      );

      final mapped = page.items
          .map(
            (n) => ReceivedNotification(
              userId: userIdStr,
              title: n.title,
              body: n.body,
              timestamp: n.sentAt ?? DateTime.now(),
              data: {
                'delivery_id': n.id,
                'notification_id': n.notificationId,
                'user_id': active.userId,
                'user_name': n.userName,
              },
              read: n.read,
            ),
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      NotificationCenter.instance.replaceCurrent(mapped);
      _lastFetchedUserId = userIdStr;
    } catch (e) {
      print('[NotificationPrefetcher] preload failed: $e');
    } finally {
      _isFetching = false;
    }
  }
}
