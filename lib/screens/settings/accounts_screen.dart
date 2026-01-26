import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/adsl_traffic_cubit.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/userinfo_cubit.dart';
import '../../core/error_handler.dart';
import '../../core/ui.dart';
import '../../core/user_mobile_cache.dart';
import '../../models/login_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_center.dart';
import '../../services/notification_prefetcher.dart';
import '../../services/notification_service.dart';
import '../../services/session_manager.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<StoredAccount> _accounts = [];
  StoredAccount? _active;
  bool _isLoading = true;
  bool _isSwitching = false;
  bool _prefetchingNotifs = false;
  int? _switchingUserId;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await SessionManager.loadAccounts();
    final active = await SessionManager.getActiveAccount();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _active = active;
      _isLoading = false;
    });

    _prefetchNotificationsForAccounts(accounts);
  }

  void _openAddAccountSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          showBackButton: true,
          onLoggedIn: (data, username) => _onAccountAdded(data, username),
        ),
      ),
    );
  }

  Future<void> _prefetchNotificationsForAccounts(
    List<StoredAccount> accounts,
  ) async {
    if (_prefetchingNotifs || accounts.isEmpty) return;
    _prefetchingNotifs = true;
    final prevUserId = NotificationCenter.instance.currentUserId;
    final activeId = (await SessionManager.getActiveAccount())?.userId
        .toString();
    final service = NotificationService();

    try {
      for (final account in accounts) {
        if (account.token.isEmpty) continue;

        final identifier =
            await UserMobileCache.read(account.username) ??
            account.userId.toString();
        final page = await service.fetchNotifications(
          userId: account.userId,
          userIdentifier: identifier,
          bearerToken: account.token,
          perPage: 10,
        );

        final mapped =
            page.items
                .map(
                  (n) => ReceivedNotification(
                    userId: account.userId.toString(),
                    title: n.title,
                    body: n.body,
                    timestamp: n.sentAt ?? DateTime.now(),
                    data: {
                      'delivery_id': n.id,
                      'notification_id': n.notificationId,
                      'user_id': account.userId,
                      'user_name': n.userName,
                    },
                    read: n.read ?? false,
                  ),
                )
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        NotificationCenter.instance.setCurrentUser(
          account.userId.toString(),
          resetHistory: false,
        );
        NotificationCenter.instance.replaceCurrent(mapped);
      }
    } catch (_) {
      // تجاهل الأخطاء أثناء التحضير المسبق
    } finally {
      final restoreId = prevUserId ?? activeId;
      if (restoreId != null) {
        NotificationCenter.instance.setCurrentUser(
          restoreId,
          resetHistory: false,
        );
      }
      _prefetchingNotifs = false;
    }
  }

  Future<void> _refreshDataFor(StoredAccount account) async {
    setState(() {
      _isSwitching = true;
      _switchingUserId = account.userId;
    });
    await SessionManager.setActiveAccount(account);

    NotificationCenter.instance.setCurrentUser(
      account.userId.toString(),
      resetHistory: false,
    );

    String? error;
    try {
      await context.read<UserInfoCubit>().fetchUserInfo(
        account.token,
        account.username,
      );
      await context.read<AdslTrafficCubit>().fetchTraffic(
        account.username,
        token: account.token,
      );
      await NotificationPrefetcher.fetchOncePerSession(force: true);
    } catch (e) {
      error = ErrorHandler.getErrorMessage(e);
    }

    if (!mounted) return;

    setState(() {
      _active = account;
      _isSwitching = false;
      _switchingUserId = null;
    });

    if (error != null) {
      showAppMessage(context, error, type: AppMessageType.error);
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _onAccountAdded(LoginData data, String username) async {
    final account = StoredAccount(
      userId: data.userId,
      username: username,
      token: data.token,
      displayName: data.name,
      lastUsed: DateTime.now(),
    );

    await SessionManager.upsertAccount(account, setActive: true);
    await _loadAccounts();

    if (!mounted) return;

    await _refreshDataFor(account);

    if (!mounted) return;

    showAppMessage(
      context,
      'تمت إضافة الحساب بنجاح',
      type: AppMessageType.success,
    );
  }

  Future<LogoutResult> _logoutAccountWithMessage(StoredAccount account) async {
    try {
      final response = await AuthService().logout(
        userId: account.userId,
        name: account.username,
        token: account.token,
      );

      if (response.isSuccess) {
        return const LogoutResult(
          success: true,
          message: 'تم حذف الحساب بنجاح',
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return const LogoutResult(
          success: true,
          message: 'انتهت الجلسة. تمت إزالة الحساب من الجهاز',
        );
      } else if (response.statusCode >= 500) {
        return const LogoutResult(
          success: false,
          message: 'حدث خطأ. حاول لاحقاً',
        );
      } else {
        return const LogoutResult(success: false, message: 'تعذر حذف الحساب');
      }
    } catch (_) {
      return const LogoutResult(success: false, message: 'خطأ غير متوقع');
    }
  }

  Future<void> _confirmSwitchAccount(StoredAccount account) async {
    if (_active?.userId == account.userId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'تبديل الحساب',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل تريد الانتقال إلى الحساب ${account.displayName ?? account.username}؟',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.maybePop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _refreshDataFor(account);
    }
  }

  Future<void> _removeAccount(StoredAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'حذف الحساب',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل تريد حذف الحساب ${account.displayName ?? account.username}؟',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.maybePop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final wasActive = _active?.userId == account.userId;
    final result = await _logoutAccountWithMessage(account);

    await SessionManager.removeAccount(account.userId);

    if (wasActive) {
      final remaining = await SessionManager.loadAccounts();
      if (remaining.isEmpty) {
        await SessionManager.clearActiveSession();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      await _refreshDataFor(remaining.first);
      return;
    }

    await _loadAccounts();

    if (mounted) {
      showAppMessage(
        context,
        result.message,
        type: result.success ? AppMessageType.success : AppMessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.maybePop();
              } else {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          title: const Text('الحسابات'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddAccountSheet,
          icon: const Icon(Icons.add),
          label: const Text('إضافة حساب'),
        ),
        body: ValueListenableBuilder(
          valueListenable: NotificationCenter.instance.version,
          builder: (context, _, __) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_accounts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt,
                      size: 56,
                      color: theme.hintColor,
                    ),
                    const SizedBox(height: 12),
                    const Text('لا توجد حسابات محفوظة'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _openAddAccountSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة حساب'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                final isActive = _active?.userId == account.userId;
                final unread = NotificationCenter.instance.unreadCountFor(
                  account.userId.toString(),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minLeadingWidth: 0,
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.12),
                          child: Icon(
                            isActive ? Icons.check : Icons.person_outline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : unread.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'حذف الحساب',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeAccount(account),
                    ),
                    onTap: _isSwitching && _switchingUserId == account.userId
                        ? null
                        : () => _confirmSwitchAccount(account),
                    enabled: !_isSwitching,
                    subtitle: _switchingUserId == account.userId
                        ? Row(
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('جاري التبديل...'),
                            ],
                          )
                        : Text(
                            account.username,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

