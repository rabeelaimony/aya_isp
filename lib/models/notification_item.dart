class FcmNotificationItem {
  final int id;
  final int notificationId;
  final int userId;
  final String title;
  final String body;
  final String userName;
  final DateTime? sentAt;
  final DateTime? openedAt;
  final String? status;

  bool get read => openedAt != null;

  FcmNotificationItem({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.userName,
    this.sentAt,
    this.openedAt,
    this.status,
  });

  factory FcmNotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final inner = json['notification'] is Map<String, dynamic>
        ? (json['notification'] as Map<String, dynamic>)
        : <String, dynamic>{};

    return FcmNotificationItem(
      id: _toInt(json['id']),
      notificationId: _toInt(json['notification_id']),
      userId: _toInt(json['user_id']),
      title: inner['title']?.toString() ?? '',
      body: inner['body']?.toString() ?? '',
      userName: _extractUserName(json),
      sentAt: parseDate(json['sent_at']),
      openedAt: parseDate(json['opened_at']),
      status: json['status']?.toString(),
    );
  }

  static String _coerceToString(dynamic value) {
    if (value == null) return '';
    final asString = value.toString().trim();
    return asString.isEmpty ? '' : asString;
  }

  static String _extractUserName(Map<String, dynamic> json) {
    const keys = ['user_name', 'userName', 'username', 'name'];
    for (final key in keys) {
      final text = _coerceToString(json[key]);
      if (text.isNotEmpty) return text;
    }

    if (json['user'] is Map) {
      final userMap = Map<String, dynamic>.from(json['user'] as Map);
      for (final key in keys) {
        final text = _coerceToString(userMap[key]);
        if (text.isNotEmpty) return text;
      }
      if (userMap['personal'] is Map) {
        final personal = Map<String, dynamic>.from(userMap['personal'] as Map);
        final text = _coerceToString(personal['full_name']);
        if (text.isNotEmpty) return text;
      }
    }

    return '';
  }
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}
