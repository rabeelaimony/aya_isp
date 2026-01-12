import 'package:dio/dio.dart';

import '../core/api_config.dart';
import '../models/notification_item.dart';

class NotificationPage {
  NotificationPage({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final List<FcmNotificationItem> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasMore {
    if (lastPage > 0) return currentPage < lastPage;
    if (total > 0 && perPage > 0) {
      return currentPage * perPage < total;
    }
    return items.length >= perPage;
  }
}

class NotificationService {
  final Dio _dio = ApiConfig.createDio(
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
  );

  Future<NotificationPage> fetchNotifications({
    required int userId,
    required String userIdentifier,
    int page = 1,
    int perPage = 10,
    String? bearerToken,
  }) async {
    final form = FormData.fromMap({
      "user_id": userId.toString(),
      "mobile": userIdentifier,
      "per_page": perPage.toString(),
      "page": page.toString(),
    });
    final resp = await _dio.post(
      '/get-fcm-notification',
      data: form,
      options: Options(
        headers: bearerToken != null && bearerToken.isNotEmpty
            ? {"Authorization": "Bearer $bearerToken"}
            : null,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    dynamic payload = resp.data;
    List<dynamic> listData = [];
    Map<String, dynamic> meta = {};
    if (payload is List) {
      listData = payload;
    } else if (payload is Map) {
      final mapPayload = Map<String, dynamic>.from(payload);
      meta = _extractMeta(mapPayload);

      if (mapPayload['notifications'] is List) {
        listData = mapPayload['notifications'];
      } else if (mapPayload['notifications'] is Map &&
          (mapPayload['notifications']['data'] is List)) {
        final nested = Map<String, dynamic>.from(
          mapPayload['notifications'] as Map,
        );
        listData = List<dynamic>.from(nested['data'] as List);
        if (meta.isEmpty) {
          meta = _extractMeta(nested);
        }
      } else if (mapPayload['data'] is List) {
        listData = mapPayload['data'];
      } else if (mapPayload['result'] is List) {
        listData = mapPayload['result'];
      } else {
        for (final v in mapPayload.values) {
          if (v is List) {
            listData = v;
            break;
          }
          if (v is Map && v['data'] is List) {
            listData = List<dynamic>.from(v['data'] as List);
            if (meta.isEmpty) {
              meta = _extractMeta(Map<String, dynamic>.from(v));
            }
            break;
          }
        }
      }
    }

    final items = <FcmNotificationItem>[];
    for (final d in listData) {
      try {
        if (d is Map<String, dynamic>) {
          items.add(FcmNotificationItem.fromJson(d));
        } else if (d is Map) {
          items.add(FcmNotificationItem.fromJson(Map<String, dynamic>.from(d)));
        }
      } catch (_) {}
    }

    final currentPage = _asInt(meta['current_page']) != 0
        ? _asInt(meta['current_page'])
        : page;
    final parsedPerPage = _asInt(meta['per_page']) != 0
        ? _asInt(meta['per_page'])
        : perPage;
    final total = _asInt(meta['total']) != 0 ? _asInt(meta['total']) : items.length;
    var lastPage = _asInt(meta['last_page']);
    if (lastPage == 0 && total > 0 && parsedPerPage > 0) {
      lastPage = ((total + parsedPerPage - 1) ~/ parsedPerPage);
    }

    return NotificationPage(
      items: items,
      currentPage: currentPage,
      perPage: parsedPerPage,
      total: total,
      lastPage: lastPage,
    );
  }

  Future<bool> markAsRead({
    required int notificationId,
    String? bearerToken,
  }) async {
    final form = FormData.fromMap({
      "notificationId": notificationId.toString(),
    });
    final resp = await _dio.post(
      '/update-fcm-notification',
      data: form,
      options: Options(
        headers: bearerToken != null && bearerToken.isNotEmpty
            ? {"Authorization": "Bearer $bearerToken"}
            : null,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    return resp.statusCode == 200;
  }
}

Map<String, dynamic> _extractMeta(Map<String, dynamic> payload) {
  final candidates = [
    payload['meta'],
    payload['pagination'],
    payload['page'],
  ];
  for (final candidate in candidates) {
    if (candidate is Map<String, dynamic>) return candidate;
    if (candidate is Map) return Map<String, dynamic>.from(candidate);
  }

  for (final value in payload.values) {
    if (value is Map && value.isNotEmpty) {
      final nested = _extractMeta(Map<String, dynamic>.from(value));
      if (nested.isNotEmpty) return nested;
    }
  }

  return {};
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}
