import 'dart:collection';
import 'dart:async';

import 'package:flutter/foundation.dart';

class ReceivedNotification {
  ReceivedNotification({
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.data,
    this.read = false,
  });

  final String userId;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  bool read;

  /// Computed id for the notification. Prefer `delivery_id`, then
  /// `notification_id`, otherwise 0. This matches the server payload
  /// keys used elsewhere in the app.
  int get id {
    final raw = data['delivery_id'] ?? data['notification_id'];
    if (raw == null) return 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }
}

class NotificationCenter {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();

  final ValueNotifier<int> _version = ValueNotifier<int>(0);
  final Map<String, List<ReceivedNotification>> _byUser = {};
  String? _currentUserId;
  final StreamController<ReceivedNotification> _incomingController =
      StreamController<ReceivedNotification>.broadcast();

  /// Emits every notification added via [add]. Useful for reacting immediately
  /// to specific events (e.g. recharge confirmations).
  Stream<ReceivedNotification> get incoming => _incomingController.stream;

  UnmodifiableListView<ReceivedNotification> get unreadItems =>
      UnmodifiableListView(
        (_currentList ?? const [])
            .where((notification) => !notification.read)
            .toList(),
      );

  UnmodifiableListView<ReceivedNotification> get historyItems =>
      UnmodifiableListView(
        (_currentList ?? const [])
            .where((notification) => notification.read)
            .toList(),
      );

  UnmodifiableListView<ReceivedNotification> get items =>
      UnmodifiableListView(_currentList ?? const []);

  ValueListenable<int> get version => _version;
  String? get currentUserId => _currentUserId;

  int get unreadCount =>
      _currentList?.where((notification) => !notification.read).length ?? 0;

  int unreadCountFor(String userId) {
    final list = _byUser[userId];
    if (list == null || list.isEmpty) return 0;
    return list.where((n) => !n.read).length;
  }

  void replaceCurrent(List<ReceivedNotification> items) {
    if (_currentUserId == null) return;
    _byUser[_currentUserId!] = List<ReceivedNotification>.from(items);
    _notify();
  }

  void setCurrentUser(String? userId, {bool resetHistory = false}) {
    _currentUserId = userId;
    if (userId != null) {
      if (resetHistory) {
        _byUser[userId] = [];
      } else {
        _byUser.putIfAbsent(userId, () => []);
      }
    }
    _notify();
  }

  void add({
    required String title,
    required String body,
    required DateTime timestamp,
    required Map<String, dynamic> data,
    String? forUserId,
  }) {
    final userId = forUserId ?? _currentUserId;
    if (userId == null) return;

    final list = _byUser.putIfAbsent(userId, () => []);
    final notification = ReceivedNotification(
      userId: userId,
      title: title,
      body: body,
      timestamp: timestamp,
      data: data,
    );
    list.insert(
      0,
      notification,
    );
    if (!_incomingController.isClosed) {
      _incomingController.add(notification);
    }
    _notify();
  }

  void markRead(ReceivedNotification notification) {
    if (notification.read) return;
    notification.read = true;
    _notify();
  }

  void markAllRead() {
    final list = _currentList;
    if (list == null || list.isEmpty) return;

    var changed = false;
    for (final item in list) {
      if (!item.read) {
        item.read = true;
        changed = true;
      }
    }
    if (changed) _notify();
  }

  void clearAll() {
    _byUser.clear();
    _currentUserId = null;
    _notify();
  }

  List<ReceivedNotification>? get _currentList =>
      _currentUserId == null ? null : _byUser[_currentUserId!];

  void _notify() => _version.value++;
}
