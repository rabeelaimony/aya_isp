import '../change_speed/change_speed_screen.dart';
import '../extend_traffic/extend_traffic_screen.dart';
import '../session_details/session_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aya_isp/services/session_manager.dart';
import 'package:aya_isp/services/notification_prefetcher.dart';

import '../../cubits/adsl_traffic_cubit.dart';
import '../../cubits/userinfo_cubit.dart';
import 'package:aya_isp/models/adsl_traffic_model.dart';
import '../../models/userinfo_model.dart';
import '../../core/ui.dart';
import 'widgets/account_card.dart';
import 'widgets/adsl_traffic.dart';
import 'widgets/appbar_user.dart';
import 'widgets/user_details_sheet.dart';
import 'widgets/extend_validity_sheet.dart';

import '../charge_extra_traffic/packages_list_screen.dart';
import '../charge_account/recharge_account_screen.dart';
import '../account/change_to_vip_screen.dart';
import '../account/change_to_nakaba_screen.dart';
import '../financial/financial_statement_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _extraPackagesTitle = 'شحن ترافيك إضافي';
  static const _financialStatementTitle = 'البيان المالي';
  static const _extendTrafficTitle = 'تمديد ترافيك';
  static const _extendValidityTitle = 'تمديد صلاحية';
  static const _sessionDetailsTitle =
      '\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u062f\u062e\u0648\u0644';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPrefetcher.fetchOncePerSession(force: true);
    });
  }

  Future<void> _loadUserInfo() async {
    final active = await SessionManager.getActiveAccount();

    if (active != null && mounted) {
      await context.read<UserInfoCubit>().fetchUserInfo(
        active.token,
        active.username,
      );
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _navigateToPage(BuildContext context, String title) async {
    if (title == _extraPackagesTitle) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PackagesListScreen()),
      );
    } else if (title == _financialStatementTitle) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FinancialStatementScreen()),
      );
    } else if (title == _sessionDetailsTitle) {
      final active = await SessionManager.getActiveAccount();
      final username = active?.username;
      if (!context.mounted) return;
      if (username != null && username.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailsScreen(username: username),
          ),
        );
      } else {
        showAppMessage(
          context,
          'اسم المستخدم غير متوفر',
          type: AppMessageType.error,
        );
      }
    } else if (title == _extendTrafficTitle) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const ExtendTrafficScreen()),
      );

      if (result == true) {
        await _loadUserInfo();
      }
    } else {
      if (title == 'تعديل السرعة') {
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpeedChangeScreen()),
        );
        return;
      }
      if (title == 'شحن الحساب') {
        final result = await Navigator.push<bool?>(
          context,
          MaterialPageRoute(builder: (_) => const RechargeAccountScreen()),
        );

        // If recharge succeeded, refresh user info (dialog is shown in the recharge screen)
        if (result == true) {
          await _loadUserInfo();
        }
      } else if (title == 'تغيير نوع الحساب') {
        // Prevent changing account type for non-normal accounts
        final userState = context.read<UserInfoCubit>().state;
        String? accType;
        if (userState is UserInfoLoaded) {
          accType = userState.userInfo.data?.user?.account?.accType;
        }

        final accTypeLower = accType?.toString().toLowerCase() ?? '';

        // Allow changing account type only when server reports accType == 'A'
        final allowed = accTypeLower == 'a';

        if (!allowed) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تنبيه'),
                content: const Text(
                  'لا يمكنك تغيير نوع الحساب. لمزيد من التفاصيل يرجى التواصل على 0119806',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).maybePop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          );
          return;
        }
        final choice = await showDialog<String?>(
          context: context,
          builder: (ctx) {
            String? selected;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                // title: const Text('اختر نوع الحساب'),
                content: StatefulBuilder(
                  builder: (c, setStateDialog) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selected,
                          hint: const Text('اختر نوع الحساب'),
                          items: const [
                            DropdownMenuItem(value: 'vip', child: Text('VIP')),
                            DropdownMenuItem(
                              value: 'nakaba',
                              child: Text('نقابة'),
                            ),
                          ],
                          onChanged: (v) => setStateDialog(() => selected = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).maybePop(null),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selected == null
                                  ? null
                                  : () => Navigator.of(ctx).maybePop(selected),
                              child: const Text('تأكيد'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
        if (!context.mounted) return;
        if (choice == 'vip') {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangeToVipScreen()),
          );
        } else if (choice == 'nakaba') {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangeToNakabaScreen()),
          );
        }
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ComingSoonPage(title: title)),
        );
      }
    }
  }

  void _openExtendValiditySheet(UserData? data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ExtendValiditySheet(
        data: data,
        rootContext: context,
        onSuccessRefresh: _loadUserInfo,
      ),
    );
  }

  String _renewalMessage(String? rawDate) {
    const rtl = '\u202B'; // Force RTL

    if (rawDate == null || rawDate.isEmpty) {
      return '$rtl سيتم تجديد الباقة تلقائياً عند بداية الصلاحية الجديدة عند الساعة 11:00 صباحاً.';
    }

    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      final formatted =
          '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';

      return '$rtl سيتم تجديد الباقة تلقائياً في $formatted عند الساعة 11:00 صباحاً.';
    } catch (_) {
      return '$rtl سيتم تجديد الباقة تلقائياً عند بداية الصلاحية الجديدة عند الساعة 11:00 صباحاً.';
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatTrafficBytes(double bytes) {
    const units = ['KB', 'MB', 'GB'];
    double v = bytes / 1024;
    String unit = 'KB';

    for (int i = 1; i < units.length; i++) {
      if (v < 1024) {
        unit = units[i - 1];
        break;
      }
      v = v / 1024;
      unit = units[i];
    }

    final int precision = v >= 100
        ? 0
        : v >= 10
        ? 1
        : 2;
    return '${v.toStringAsFixed(precision)} $unit';
  }

  String _formatMonthlyUsage(AdslData? trafficData, Account? account) {
    if (trafficData == null) return '-';

    final double accountAvailable = _toDouble(account?.availableTraffic) ?? 0.0;
    final double accountExtra = _toDouble(account?.extraTraffic) ?? 0.0;
    final double total =
        trafficData.totalTrafficPackage ?? (accountAvailable + accountExtra);
    final double available = accountAvailable > 0
        ? accountAvailable
        : (trafficData.availableTraffic ?? 0.0);

    final double totalBytes = total * 1024 * 1024 * 1024;
    final double consumedBytes = (totalBytes - available).clamp(0, totalBytes);

    if (consumedBytes < 1024 * 1024 * 1024) {
      return _formatTrafficBytes(consumedBytes);
    }

    final double monthlyGb = trafficData.monthTotalTrafficUsage ?? 0;
    return '${monthlyGb.toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<UserInfoCubit, UserInfoState>(
        listener: (context, state) {
          if (state is UserInfoLoaded) {
            final username = state.userInfo.data?.user?.personal?.username;
            if (username != null && username.isNotEmpty) {
              SessionManager.getActiveAccount()
                  .then((active) {
                    final token = active?.token;
                    try {
                      // ignore: use_build_context_synchronously
                      context.read<AdslTrafficCubit>().fetchTraffic(
                        username,
                        token: token,
                      );
                    } catch (_) {}
                  })
                  .catchError((_) {});
            }
          }
        },
        child: BlocBuilder<UserInfoCubit, UserInfoState>(
          builder: (context, state) {
            if (state is UserInfoError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppErrorCard(
                        title: 'حدث خطأ',
                        message: state.message,
                        actionLabel: 'إعادة المحاولة',
                        onAction: _loadUserInfo,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openSettings,
                          icon: const Icon(Icons.settings),
                          label: const Text('فتح الإعدادات'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is UserInfoLoaded) {
              final data = state.userInfo.data;
              final account = data?.user?.account;

              return WillPopScope(
                onWillPop: () async {
                  final shouldPop = await showDialog<bool>(
                    context: context,
                    builder: (context) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        title: const Text('تأكيد الخروج'),
                        content: const Text('هل تريد الخروج من التطبيق؟'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).maybePop(false),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).maybePop(true),
                            child: const Text('نعم'),
                          ),
                        ],
                      ),
                    ),
                  );
                  return shouldPop ?? false;
                },
                child: RefreshIndicator(
                  onRefresh: _loadUserInfo,
                  child: CustomScrollView(
                    slivers: [
                      AppBarUser(
                        data: data,
                        onTap: () => showUserDetailsSheet(
                          context,
                          data?.user?.personal,
                          data,
                        ),
                        onNotifications: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        onSettings: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BlocBuilder<AdslTrafficCubit, AdslTrafficState>(
                              builder: (context, trafficState) {
                                final trafficData =
                                    trafficState is AdslTrafficLoaded
                                    ? trafficState.response?.data
                                    : null;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AccountCard(
                                      account: account,
                                      data: data,
                                      trafficData: trafficData,
                                    ),
                                    const SizedBox(height: 12),

                                    // Monthly total consumption box (under account card)
                                    if (trafficData?.monthTotalTrafficUsage !=
                                        null)
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Left: small info button (replaces previous 'تفصيل التجديد')
                                            IconButton(
                                              onPressed: () async {
                                                final msg = _renewalMessage(
                                                  trafficData?.trafficRenewedAt,
                                                );
                                                if (!mounted) return;
                                                showDialog<void>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: Center(
                                                      child: const Text(
                                                        'إغلاق',
                                                      ),
                                                    ),
                                                    content: Text(
                                                      msg,
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).maybePop(),
                                                        child: const Text(
                                                          'إغلاق',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.info_outline,
                                              ),
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              tooltip: 'تفصيل التجديد',
                                            ),

                                            const SizedBox(width: 8),

                                            // Right: monthly consumption (aligned to the right)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'الاستهلاك الكلي الشهري(من تاريخ تجديد الباقة)',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _formatMonthlyUsage(
                                                      trafficData,
                                                      account,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              },
                            ),
                            if (data?.user?.personal?.username != null)
                              AdslTrafficWidget(
                                username: data!.user!.personal!.username!,
                                account: data.user?.account,
                              ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'خدمات الحساب',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxWidth = constraints.maxWidth;
                                // نحافظ على 4 ازرار في الصف على الشاشات العادية والكبيرة
                                // ونخفضها الى 3 او 2 فقط عند الشاشات الصغيرة جدا
                                // حتى يبقى العنوان داخل الزر واضحا وغير مكتوم.
                                int crossAxisCount;
                                if (maxWidth < 320) {
                                  crossAxisCount = 2;
                                } else if (maxWidth < 420) {
                                  crossAxisCount = 3;
                                } else {
                                  crossAxisCount = 4;
                                }

                                final totalWidth = maxWidth;
                                final itemWidth = totalWidth / crossAxisCount;
                                final itemHeight = itemWidth * 1.05;
                                final childAspectRatio = itemWidth / itemHeight;

                                return GridView.count(
                                  crossAxisCount: crossAxisCount,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: childAspectRatio,
                                  children: [
                                    _buildControlItem(
                                      context,
                                      Icons.bar_chart,
                                      'بيانات الدخول',
                                    ),
                                    _buildControlItem(
                                      context,
                                      Icons.receipt_outlined,
                                      _financialStatementTitle,
                                    ),
                                    _buildControlItem(
                                      context,
                                      Icons.credit_card_outlined,
                                      'شحن الحساب',
                                    ),
                                    _buildControlItem(
                                      context,
                                      Icons.refresh,
                                      'تغيير نوع الحساب',
                                    ),
                                    _buildControlItem(
                                      context,
                                      Icons.speed,
                                      'تعديل السرعة',
                                    ),
                                    _buildControlItem(
                                      context,
                                      Icons.north_east,
                                      _extraPackagesTitle,
                                    ),
                                    _buildControlItem(
                                      context,
                                      Icons.add_box_outlined,
                                      _extendTrafficTitle,
                                    ),
                                    _buildControlItem(
                                      context,
                                      Icons.auto_fix_high,
                                      _extendValidityTitle,
                                      onTap: () =>
                                          _openExtendValiditySheet(data),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: Text('جاري التحميل'));
          },
        ),
      ),
    );
  }

  Widget _buildControlItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withValues(alpha: 0.10),
              Colors.green.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withValues(alpha: 0.50)),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap ?? () => _navigateToPage(context, title),
          borderRadius: BorderRadius.circular(14),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 5,
                  child: FittedBox(child: Icon(icon, color: Colors.green)),
                ),
                const SizedBox(height: 6),
                Flexible(
                  flex: 4,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ComingSoonPage extends StatelessWidget {
  final String title;
  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text(
          'الخدمة قيد التحضير...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
