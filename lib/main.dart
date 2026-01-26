import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:convert';
import 'dart:ui';

import 'services/notification_center.dart';
import 'core/app_navigator.dart';
import 'core/theme.dart';
import 'services/session_manager.dart';
import 'services/notification_prefetcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_info.dart';

// الشاشات
import 'screens/splach/splach_screen.dart';
import 'screens/login/login_screen.dart';

import 'package:aya_isp/screens/settings/accounts_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/simple_app/simple_app_home_screen.dart';

// Cubits
import 'cubits/auth_cubit.dart';
import 'cubits/userinfo_cubit.dart';
import 'cubits/adsl_traffic_cubit.dart';
import 'cubits/traffic_package_cubit.dart';
import 'cubits/traffic_charge_cubit.dart';
import 'cubits/change_password_cubit.dart';
import 'cubits/financial_cubit.dart';
import 'cubits/session_detail_cubit.dart';
import 'cubits/expand_traffic_cubit.dart';
import 'cubits/extend_validity_cubit.dart';

// Services
import 'services/auth_service.dart';
import 'services/userinfo_service.dart';
import 'services/adsl_traffic_service.dart';
import 'services/traffic_packages_service.dart';
import 'services/traffic_charge_service.dart';
import 'services/change_password_service.dart';
import 'services/financial_service.dart';
import 'services/expand_traffic_service.dart';
import 'services/extend_validity_service.dart';
import 'services/session_detail_service.dart';
import 'services/recharge_adsl_service.dart';
import 'services/change_account_service.dart';
import 'services/notification_service.dart';

// Repositories
import 'repositories/traffic_packages_repository.dart';
import 'repositories/traffic_charge_repository.dart';
import 'repositories/change_password_repository.dart';
import 'repositories/financial_repository.dart';
import 'repositories/extend_validity_repository.dart';

// Cubits (additional)
import 'cubits/recharge_adsl_cubit.dart';
import 'cubits/change_account_cubit.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'aya_notifications',
  'إشعارات Aya ISP',
  description: 'قناة التنبيهات الرئيسية لتطبيق Aya ISP',
  importance: Importance.high,
);

const String _pendingNotificationStorageKey = 'pending_notification_payload';
Map<String, dynamic>? _pendingNotificationData;
bool _processingNotificationNav = false;

Map<String, dynamic> _enrichNotificationData(Map<String, dynamic> data) {
  final enriched = Map<String, dynamic>.from(data);
  final inferredUserId = _extractUserIdFromData(enriched);
  if (inferredUserId != null) {
    enriched['user_id'] ??= inferredUserId;
  }
  return enriched;
}

@pragma('vm:entry-point')
Future<void> onDidReceiveBackgroundNotificationResponse(
  NotificationResponse details,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  final payload = details.payload;
  if (payload == null || payload.isEmpty) return;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      final data = _enrichNotificationData(decoded);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingNotificationStorageKey, jsonEncode(data));
    }
  } catch (e) {
    print('[LocalNotification-bg] payload parse error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.initialize();
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _setupFirebaseMessaging();

  // Services
  final authService = AuthService();
  final userInfoService = UserInfoService();
  final adslTrafficService = AdslTrafficService();
  final trafficPackagesService = TrafficPackagesService();
  final trafficChargeService = TrafficChargeService();
  final changePasswordService = ChangePasswordService();
  final sessionDetailService = SessionDetailService();
  final expandTrafficService = ExpandTrafficService();
  final extendValidityService = ExtendValidityService();
  final financialService = FinancialService();
  final rechargeAdslService = RechargeAdslService();
  final changeAccountService = ChangeAccountService();

  // Repositories
  final trafficPackagesRepository = TrafficPackagesRepository(
    trafficPackagesService,
  );
  final trafficChargeRepository = TrafficChargeRepository(trafficChargeService);
  final changePasswordRepository = ChangePasswordRepository(
    changePasswordService,
  );
  final extendValidityRepository = ExtendValidityRepository(
    extendValidityService,
  );
  final financialRepository = FinancialRepository(financialService);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authService)),
        BlocProvider(create: (_) => UserInfoCubit(userInfoService)),
        BlocProvider(create: (_) => AdslTrafficCubit(adslTrafficService)),
        BlocProvider(
          create: (_) => TrafficPackagesCubit(trafficPackagesRepository),
        ),
        BlocProvider(
          create: (_) => TrafficChargeCubit(trafficChargeRepository),
        ),
        BlocProvider(
          create: (_) => ExtendValidityCubit(extendValidityRepository),
        ),
        BlocProvider(create: (_) => ExpandTrafficCubit(expandTrafficService)),
        BlocProvider(create: (_) => RechargeAdslCubit(rechargeAdslService)),
        BlocProvider(create: (_) => ChangeAccountCubit(changeAccountService)),
        BlocProvider(
          create: (_) => ChangePasswordCubit(changePasswordRepository),
        ),
        BlocProvider(create: (_) => FinancialCubit(financialRepository)),
        BlocProvider(create: (_) => SessionDetailCubit(sessionDetailService)),
      ],
      child: const MyApp(),
    ),
  );

  _initLocalNotifications();
  await _restorePendingNotificationFromStorage();
  // لمعالجة أي تنقل معلق من الإشعارات بعد تهيئة الـ Navigator.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => _processPendingNotificationNavigation(),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data.isNotEmpty) {
    _enrichNotificationData(message.data);
  }
}

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) async {
      final payload = details.payload;
      if (payload == null || payload.isEmpty) return;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          final data = _enrichNotificationData(decoded);
          await _handleNotificationTapData(data);
        }
      } catch (e) {
        print('[LocalNotification] payload parse error: $e');
      }
    },
    onDidReceiveBackgroundNotificationResponse:
        onDidReceiveBackgroundNotificationResponse,
  );

  final androidImpl = _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidImpl?.createNotificationChannel(_androidChannel);
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title']?.toString() ?? '';
  final body = notification?.body ?? message.data['body']?.toString() ?? '';

  if (title.isEmpty && body.isEmpty) return;

  final androidDetails = AndroidNotificationDetails(
    _androidChannel.id,
    _androidChannel.name,
    channelDescription: _androidChannel.description,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  final details = NotificationDetails(android: androidDetails);
  final enrichedData = message.data.isNotEmpty
      ? _enrichNotificationData(message.data)
      : <String, dynamic>{};

  await _localNotifications.show(
    message.hashCode,
    title,
    body,
    details,
    payload: enrichedData.isNotEmpty ? jsonEncode(enrichedData) : null,
  );
}

Future<void> _persistIncomingNotification(
  RemoteMessage message, {
  bool persistForNav = false,
}) async {
  try {
    final targetUserId =
        _extractUserId(message) ??
        (await SessionManager.getActiveAccount())?.userId;
    if (targetUserId == null) return;

    NotificationCenter.instance.setCurrentUser(
      targetUserId.toString(),
      resetHistory: false,
    );

    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    final data = message.data.isNotEmpty
        ? _enrichNotificationData(message.data)
        : <String, dynamic>{};

    // Ensure we persist the resolved user id with the notification payload so
    // taps can switch to the right account even if the raw data lacked it.
    data['user_id'] ??= targetUserId;

    NotificationCenter.instance.add(
      title: title,
      body: body,
      timestamp: DateTime.now(),
      data: data,
      forUserId: targetUserId.toString(),
    );
    if (persistForNav) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingNotificationStorageKey, jsonEncode(data));
    }

    // جهّز التنقل بناءً على الإشعار الوارد
    _queueNotificationNavigation(data);
  } catch (e) {
    print('[FirebaseMessaging] persist incoming error: $e');
  }
}

int? _extractUserId(RemoteMessage message) {
  return _extractUserIdFromData(message.data);
}

int? _extractUserIdFromData(Map<String, dynamic> data) {
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
    raw = data[key];
    if (raw != null) break;
  }

  // Sometimes nested in a "data" object
  if (raw == null && data['data'] is Map<String, dynamic>) {
    final inner = data['data'] as Map<String, dynamic>;
    for (final key in keys) {
      raw = inner[key];
      if (raw != null) break;
    }
  }

  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is double) return raw.toInt();
  final parsed = int.tryParse(raw.toString().split('.').first);
  return parsed;
}

int? _extractNotificationIdFromData(Map<String, dynamic> data) {
  int? parseId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  final candidates = [data['notification_id'], data['delivery_id'], data['id']];

  for (final raw in candidates) {
    final parsed = parseId(raw);
    if (parsed != null && parsed != 0) return parsed;
  }

  final nested = data['data'];
  if (nested is Map<String, dynamic>) {
    for (final key in ['notification_id', 'delivery_id', 'id']) {
      final parsed = parseId(nested[key]);
      if (parsed != null && parsed != 0) return parsed;
    }
  }

  return null;
}

Future<void> _refreshActiveAccountData({StoredAccount? account}) async {
  final active = account ?? await SessionManager.getActiveAccount();
  if (active == null) return;

  final ctx = appNavigatorKey.currentContext;
  try {
    if (ctx != null && ctx.mounted) {
      await ctx.read<UserInfoCubit>().fetchUserInfo(
        active.token,
        active.username,
      );
      await ctx.read<AdslTrafficCubit>().fetchTraffic(
        active.username,
        token: active.token,
      );
    } else {
      // إذا لم يكن لدينا BuildContext جاهز (مثلاً أثناء الإقلاع) نجلب البيانات مرة واحدة.
      await NotificationPrefetcher.fetchOncePerSession(force: true);
    }
  } catch (e) {
    print('[NotificationNav] refresh data failed: $e');
  }
}

Future<bool> _switchAccountFromNotification(
  int userId, {
  List<StoredAccount>? accounts,
}) async {
  final accountsList = accounts ?? await SessionManager.loadAccounts();
  final active = await SessionManager.getActiveAccount();
  StoredAccount? account;
  try {
    account = accountsList.firstWhere((a) => a.userId == userId);
  } catch (_) {
    return false;
  }

  if (active != null && active.userId == account.userId) {
    return true;
  }

  await SessionManager.setActiveAccount(account);
  NotificationCenter.instance.setCurrentUser(
    account.userId.toString(),
    resetHistory: false,
  );
  await NotificationPrefetcher.fetchOncePerSession(force: true);

  await _refreshActiveAccountData(account: account);
  return true;
}

Future<void> _markNotificationAsReadFromPayload(
  Map<String, dynamic> data, {
  int? targetUserId,
}) async {
  final notificationId = _extractNotificationIdFromData(data);
  if (notificationId == null || notificationId == 0) return;

  final targetId = targetUserId ?? _extractUserIdFromData(data);
  final accounts = await SessionManager.loadAccounts();
  StoredAccount? account;

  if (targetId != null) {
    try {
      account = accounts.firstWhere((a) => a.userId == targetId);
    } catch (_) {}
  }

  account ??= await SessionManager.getActiveAccount();
  if (account == null) return;
  if (targetId != null && account.userId != targetId) return;
  if (account.token.isEmpty) return;

  try {
    await NotificationService().markAsRead(
      notificationId: notificationId,
      bearerToken: account.token,
    );
  } catch (e) {
    print('[NotificationNav] mark as read failed: $e');
  }
}

Future<void> _handleNotificationTap(RemoteMessage message) async {
  await _persistIncomingNotification(message);
  // message.data may be missing user_id, so reuse the persisted map when possible.
  final data = message.data.isNotEmpty
      ? _enrichNotificationData(message.data)
      : <String, dynamic>{};
  _queueNotificationNavigation(data);
}

Future<void> _handleNotificationTapData(Map<String, dynamic> data) async {
  _queueNotificationNavigation(_enrichNotificationData(data));
}

void _queueNotificationNavigation(Map<String, dynamic> data) {
  _pendingNotificationData = Map<String, dynamic>.from(data);
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => _processPendingNotificationNavigation(),
  );
}

Future<void> _processPendingNotificationNavigation() async {
  if (_processingNotificationNav) return;
  if (_pendingNotificationData == null) return;
  _processingNotificationNav = true;
  final data = _pendingNotificationData!;
  _pendingNotificationData = null;

  final accounts = await SessionManager.loadAccounts();
  final hasMultipleAccounts = accounts.length > 1;
  final targetUserId = _extractUserIdFromData(data);
  final switched = targetUserId != null
      ? await _switchAccountFromNotification(targetUserId, accounts: accounts)
      : false;
  await _markNotificationAsReadFromPayload(data, targetUserId: targetUserId);
  if (hasMultipleAccounts) {
    await _navigateToAccountsSafely();
  } else {
    await _navigateToNotificationsSafely();
  }
  // بعد فتح شاشة الإشعارات/الحسابات، حدّث بيانات الحساب إن لم يتم التبديل.
  if (!switched) {
    await _refreshActiveAccountData();
  }
  _processingNotificationNav = false;
}

Future<void> _restorePendingNotificationFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_pendingNotificationStorageKey);
  if (raw == null || raw.isEmpty) return;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      _pendingNotificationData = decoded;
    }
  } catch (e) {
    print('[LocalNotification] restore pending parse error: $e');
  } finally {
    await prefs.remove(_pendingNotificationStorageKey);
  }
}

Future<void> _navigateToNotificationsSafely() async {
  await WidgetsBinding.instance.endOfFrame;

  for (var i = 0; i < 8; i++) {
    final navigator = appNavigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        (route) => false,
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
}

Future<void> _navigateToAccountsSafely() async {
  // انتظر حتى يصبح الـ Navigator جاهزاً قبل الانتقال لصفحة الحسابات.
  await WidgetsBinding.instance.endOfFrame;

  for (var i = 0; i < 8; i++) {
    final navigator = appNavigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccountsScreen()),
        (route) => false,
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
}

Future<void> _setupFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _showLocalNotification(message);
      await _persistIncomingNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _handleNotificationTap(message);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleNotificationTap(initialMessage);
    }
  } catch (e) {
    print('[FirebaseMessaging] فشل تهيئة الإشعارات: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      navigatorKey: appNavigatorKey,

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/simple': (context) => const SimpleAppHomeScreen(),
      },
      // ضبط الـ builder لتحسين الوصولية وتثبيت تكبير النص وإخفاء الزوايا السفلية.
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _processPendingNotificationNavigation(),
        );

        final mq = MediaQuery.of(context);
        final clampedScale = mq.textScaleFactor.clamp(1.0, 1.0);
        final safeChild = SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: child ?? const SizedBox.shrink(),
        );

        return MediaQuery(
          data: mq.copyWith(
            textScaleFactor: null,
            textScaler: TextScaler.linear(clampedScale),
            boldText: mq.boldText,
            highContrast: mq.highContrast,
            disableAnimations: mq.disableAnimations,
            accessibleNavigation: mq.accessibleNavigation,
            alwaysUse24HourFormat: mq.alwaysUse24HourFormat,
          ),
          child: safeChild,
        );
      },
    );
  }
}
