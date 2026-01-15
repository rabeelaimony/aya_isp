import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/notification_center.dart';
import '../../services/notification_service.dart';
import '../../core/error_handler.dart';
import '../../core/ui.dart';
import '../../services/session_manager.dart';
import '../../services/notification_prefetcher.dart';
import '../../cubits/userinfo_cubit.dart';
import '../../cubits/adsl_traffic_cubit.dart';
import '../../core/user_mobile_cache.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _error;
  bool _needsNotificationPermission = false;
  String? _permissionDebugStatus;
  final _service = NotificationService();
  final ScrollController _scrollController = ScrollController();
  static const int _perPage = 10;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({int page = 1, bool append = false}) async {
    if (append) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _needsNotificationPermission = false;
        _permissionDebugStatus = null;
        _hasMore = true;
        _currentPage = 1;
        _lastPage = 1;
        _total = 0;
      });
    }

    try {
      final existingItems = NotificationCenter.instance.items.toList();
      final readOverrides = <int, bool>{};
      for (final item in existingItems) {
        final id = item.id;
        if (id != 0 && item.read) {
          readOverrides[id] = true;
        }
      }

      final allowed = await _ensureNotificationPermission();
      if (!allowed) {
        setState(() {
          _needsNotificationPermission = true;
        });
      }

      final active = await SessionManager.getActiveAccount();
      if (active == null ||
          active.token.isEmpty ||
          active.userId == 0 ||
          active.username.isEmpty) {
        setState(() {
          _error =
              'لم نتمكن من تحديد الحساب النشط. حاول تسجيل الخروج والدخول مرة أخرى.';
        });
        return;
      }

      NotificationCenter.instance.setCurrentUser(
        active.userId.toString(),
        resetHistory: false,
      );

      final identifier = await _resolveNotificationIdentifier(active);

      final response = await _service.fetchNotifications(
        userId: active.userId,
        userIdentifier: identifier,
        bearerToken: active.token,
        page: page,
        perPage: _perPage,
      );

      final mapped = response.items
          .map(
            (n) => ReceivedNotification(
              userId: active.userId.toString(),
              title: n.title,
              body: n.body,
              timestamp: n.sentAt ?? DateTime.now(),
              data: {
                'delivery_id': n.id,
                'notification_id': n.notificationId,
                'user_id': active.userId,
                'user_name': n.userName,
              },
              read: n.read || (readOverrides[n.id] ?? false),
            ),
          )
          .toList();

      final existing = append ? existingItems : <ReceivedNotification>[];

      final combined = <ReceivedNotification>[]
        ..addAll(existing)
        ..addAll(mapped);

      final merged = _dedupeById(combined)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      NotificationCenter.instance.replaceCurrent(merged);

      final totalFromResponse = response.total;
      final computedLastPage = response.lastPage == 0
          ? response.currentPage
          : response.lastPage;
      final hasMore =
          response.hasMore ||
          (totalFromResponse > 0 && merged.length < totalFromResponse);

      if (mounted) {
        setState(() {
          _currentPage = response.currentPage;
          _lastPage = computedLastPage;
          _total = totalFromResponse;
          _hasMore = hasMore;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (append) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
          }
        });
      }
    }
  }

  List<ReceivedNotification> _dedupeById(List<ReceivedNotification> items) {
    final seen = <int>{};
    final deduped = <ReceivedNotification>[];
    for (final item in items) {
      final id = item.id;
      if (id != 0 && seen.contains(id)) continue;
      deduped.add(item);
      if (id != 0) seen.add(id);
    }
    return deduped;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final loadedCount = NotificationCenter.instance.items.length;
    if (_total > 0 && loadedCount >= _total) {
      _hasMore = false;
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNotifications(page: _currentPage + 1, append: true);
    }
  }

  Future<void> _markAsRead(ReceivedNotification n) async {
    final notificationId = _extractNotificationId(n);
    if (notificationId == null || notificationId == 0) return;
    final active = await SessionManager.getActiveAccount();
    final token = active?.token;
    if (token == null || token.isEmpty) return;
    try {
      await _service.markAsRead(
        notificationId: notificationId,
        bearerToken: token,
      );
    } catch (e) {
      final msg = ErrorHandler.getErrorMessage(e);
      if (mounted) {
        showAppMessage(context, msg, type: AppMessageType.error);
      }
    }
  }

  Future<void> _handleNotificationTap(ReceivedNotification notification) async {
    if (!notification.read) {
      NotificationCenter.instance.markRead(notification);
    }

    final targetUserId = _extractUserIdFromNotification(notification);
    var switched = false;
    var canMarkRemotely = false;

    if (targetUserId != null) {
      final active = await SessionManager.getActiveAccount();
      final alreadyActive = active?.userId == targetUserId;
      if (alreadyActive) {
        canMarkRemotely = true;
        switched = true;
      } else {
        switched = await _switchToUser(targetUserId);
        if (!mounted) return;
        canMarkRemotely = switched;
      }
    }

    if (canMarkRemotely) {
      await _markAsRead(notification);
      if (!mounted) return;
    }

    if (!switched && mounted) {
      showAppMessage(
        context,
        "تعذر فتح حساب الإشعار. يرجى تسجيل الدخول مرة أخرى.",
        type: AppMessageType.error,
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  int? _extractNotificationId(ReceivedNotification notification) {
    int? parseId(dynamic raw) {
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is double) return raw.toInt();
      return int.tryParse(raw.toString());
    }

    final candidates = [
      notification.data['notification_id'],
      notification.data['delivery_id'],
      notification.data['id'],
    ];

    for (final raw in candidates) {
      final parsed = parseId(raw);
      if (parsed != null && parsed != 0) return parsed;
    }

    final nested = notification.data['data'];
    if (nested is Map) {
      for (final key in ['notification_id', 'delivery_id', 'id']) {
        final parsed = parseId(nested[key]);
        if (parsed != null && parsed != 0) return parsed;
      }
    }

    return null;
  }

  int? _extractUserIdFromNotification(ReceivedNotification notification) {
    final keys = [
      'user_id',
      'userId',
      'userid',
      'uid',
      'userID',
      'user_id_fk',
      'id',
    ];

    dynamic raw;
    for (final key in keys) {
      raw = notification.data[key];
      if (raw != null) break;
    }

    if (raw == null && notification.data['data'] is Map) {
      final inner = notification.data['data'] as Map;
      for (final key in keys) {
        raw = inner[key];
        if (raw != null) break;
      }
    }

    raw ??= notification.userId;
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return int.tryParse(raw.toString().split('.').first);
  }

  Future<bool> _switchToUser(int userId) async {
    final accounts = await SessionManager.loadAccounts();
    final active = await SessionManager.getActiveAccount();
    StoredAccount? account;
    try {
      account = accounts.firstWhere((a) => a.userId == userId);
    } catch (_) {}

    if (account == null) return false;

    final alreadyActive = active?.userId == account.userId;
    if (!alreadyActive) {
      await SessionManager.setActiveAccount(account);
      NotificationCenter.instance.setCurrentUser(
        account.userId.toString(),
        resetHistory: false,
      );
      await NotificationPrefetcher.fetchOncePerSession(force: true);
    }

    if (mounted) {
      try {
        await context.read<UserInfoCubit>().fetchUserInfo(
          account.token,
          account.username,
        );
        await context.read<AdslTrafficCubit>().fetchTraffic(
          account.username,
          token: account.token,
        );
      } catch (e) {
        // Best-effort refresh; ignore fetch errors here.
        try {
          showAppMessage(
            context,
            ErrorHandler.getErrorMessage(e),
            type: AppMessageType.error,
          );
        } catch (_) {}
      }
    }

    return true;
  }

  Future<String> _resolveNotificationIdentifier(StoredAccount active) async {
    final cached = await UserMobileCache.read(active.username);
    if (cached != null) return cached;

    final userInfoCubit = context.read<UserInfoCubit>();
    String? mobile;
    if (userInfoCubit.state is UserInfoLoaded) {
      final state = userInfoCubit.state as UserInfoLoaded;
      mobile = state.userInfo.data?.user?.personal?.mobile;
    }

    if (mobile == null || mobile.trim().isEmpty) {
      final fetched = await userInfoCubit.fetchUserInfo(
        active.token,
        active.username,
      );
      if (fetched && userInfoCubit.state is UserInfoLoaded) {
        final refreshed = userInfoCubit.state as UserInfoLoaded;
        mobile = refreshed.userInfo.data?.user?.personal?.mobile;
      }
    }

    final normalized = UserMobileCache.normalize(mobile);
    if (normalized != null) {
      await UserMobileCache.save(active.username, mobile);
      return normalized;
    }

    final fallback = await UserMobileCache.read(active.username);
    return fallback ?? active.userId.toString();
  }

  Future<bool> _ensureNotificationPermission() async {
    if (Platform.isIOS) {
      final messaging = FirebaseMessaging.instance;
      final status = await messaging.getNotificationSettings();
      if (_isMessagingAuthorized(status)) {
        _permissionDebugStatus = null;
        return true;
      }
      final requested = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (_isMessagingAuthorized(requested)) {
        _permissionDebugStatus = null;
        return true;
      }
      _permissionDebugStatus =
          'iOS status: ${requested.authorizationStatus.toString()}';
      if (requested.authorizationStatus == AuthorizationStatus.denied) {
        await openAppSettings();
      }
      return false;
    }

    final status = await Permission.notification.status;
    if (status.isGranted || status == PermissionStatus.provisional) {
      _permissionDebugStatus = null;
      return true;
    }
    final result = await Permission.notification.request();
    if (result.isGranted || result == PermissionStatus.provisional) {
      _permissionDebugStatus = null;
      return true;
    }
    _permissionDebugStatus = 'Status: ${result.toString()}';
    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  bool _isMessagingAuthorized(NotificationSettings settings) {
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('HH:mm - yyyy/MM/dd');

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            collapsedHeight: 140,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  navigator.pushNamedAndRemoveUntil('/home', (route) => false);
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                bottom: 12,
              ),
              title: Text(
                "الاشعارات",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, bottom: 16),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      size: 56,
                      color: theme.colorScheme.onPrimary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ValueListenableBuilder(
              valueListenable: NotificationCenter.instance.version,
              builder: (context, _, __) {
                // Combine unread first then history, but don't show separate sections
                final unread = NotificationCenter.instance.unreadItems.toList();
                final history = NotificationCenter.instance.historyItems
                    .toList();
                final combined = <ReceivedNotification>[]
                  ..addAll(unread)
                  ..addAll(
                    history.where((h) => !unread.any((u) => u.id == h.id)),
                  );

                if (_isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (_error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        if (_needsNotificationPermission)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await openAppSettings();
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('فتح إعدادات التطبيق'),
                          )
                        else
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            child: const Text('إعادة المحاولة'),
                          ),
                      ],
                    ),
                  );
                }

                if (combined.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withOpacity(0.08),
                          ),
                          child: Icon(
                            Icons.notifications_off_outlined,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "لا توجد إشعارات في الوقت الحالي",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "سنرسل لك إشعارات عند توفر محتوى جديد.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Build a single list (RTL) with unread first.
                return Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Column(
                    children: [
                      if (_needsNotificationPermission)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Enable notifications for alerts.',
                                      ),
                                      if (_permissionDebugStatus != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _permissionDebugStatus!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.hintColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await openAppSettings();
                                  },
                                  child: const Text('Settings'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ...List.generate(combined.length, (index) {
                        final notification = combined[index];
                        final isUnread = unread.any(
                          (u) => u.id == notification.id,
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: _NotificationCard(
                            notification: notification,
                            isUnread: isUnread,
                            dateFormat: dateFormat,
                            onTap: () async {
                              await _handleNotificationTap(notification);
                            },
                          ),
                        );
                      }),
                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isUnread,
    required this.dateFormat,
    required this.onTap,
  });

  final ReceivedNotification notification;
  final bool isUnread;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isUnread ? Colors.red : Colors.green).withOpacity(0.12),
          ),
          child: Icon(
            Icons.notifications,
            color: isUnread ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          notification.title.isNotEmpty ? notification.title : "بدون عنوان",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notification.body.isNotEmpty
                  ? notification.body
                  : "لا يوجد محتوى للإشعار.",
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
            const SizedBox(height: 8),
            if (notification.data['user_name'] != null &&
                notification.data['user_name'].toString().trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  notification.data['user_name'].toString().trim(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: theme.hintColor),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(notification.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: isUnread ? onTap : null,
        enabled: isUnread,
      ),
    );
  }
}
