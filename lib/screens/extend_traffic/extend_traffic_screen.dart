import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/adsl_traffic_cubit.dart';
import '../../cubits/userinfo_cubit.dart';
import '../../cubits/expand_traffic_cubit.dart';
import '../../cubits/expand_traffic_state.dart';
import '../../core/ui.dart';

class ExtendTrafficScreen extends StatefulWidget {
  const ExtendTrafficScreen({super.key});

  @override
  State<ExtendTrafficScreen> createState() => _ExtendTrafficScreenState();
}

class _ExtendTrafficScreenState extends State<ExtendTrafficScreen> {
  int _selectedReqSize = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    if (token == null || username == null) return;

    await context.read<UserInfoCubit>().fetchUserInfo(token, username);
    await context.read<AdslTrafficCubit>().fetchTraffic(username, token: token);
  }

  Future<void> _submitExtend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');

    if (token == null || username == null) {
      showAppMessage(
        context,
        'الرجاء تسجيل الدخول مجدداً',
        type: AppMessageType.error,
      );
      return;
    }

    await context.read<ExpandTrafficCubit>().extendTraffic(
      username: username,
      reqSize: _selectedReqSize,
      token: token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تمديد ترافيك')),
        body: BlocConsumer<ExpandTrafficCubit, ExpandTrafficState>(
          listener: (context, state) async {
            if (!mounted) return;
            if (state is ExpandTrafficSuccess) {
              showAppMessage(
                context,
                state.message,
                type: AppMessageType.success,
              );
              Navigator.of(context).maybePop(true);
            } else if (state is ExpandTrafficError) {
              showAppMessage(
                context,
                state.message,
                type: AppMessageType.error,
              );
            }
          },
          builder: (context, extendState) {
            final userState = context.watch<UserInfoCubit>().state;
            final trafficState = context.watch<AdslTrafficCubit>().state;

            if (userState is UserInfoError) {
              return _ErrorView(
                message: userState.message,
                onRetry: _refreshData,
              );
            }
            if (trafficState is AdslTrafficError) {
              return _ErrorView(
                message: trafficState.message,
                onRetry: _refreshData,
              );
            }
            if (userState is! UserInfoLoaded ||
                trafficState is! AdslTrafficLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final balance = (userState.userInfo.data?.balance ?? 0).toDouble();
            final available =
                trafficState.response?.data?.availableTraffic ?? 0.0;
            final extraTraffic =
                trafficState.response?.data?.extraTraffic ?? 0.0;

            final totalAvailable = available + extraTraffic;
            final packageFinished = totalAvailable <= 0;
            final hasNegativeBalance = balance < 0;
            final canExtend = packageFinished && !hasNegativeBalance;
            final isLoading = extendState is ExpandTrafficLoading;

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatusCard(
                    balance: balance,
                    availableTraffic: totalAvailable,
                    extraTraffic: extraTraffic,
                    packageFinished: packageFinished,
                    hasNegativeBalance: hasNegativeBalance,
                  ),
                  const SizedBox(height: 16),
                  _buildOptions(),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: (!canExtend || isLoading) ? null : _submitExtend,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      isLoading ? 'جاري الإرسال...' : 'تمديد الآن',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!canExtend)
                    Text(
                      'التمديد يحتاج لانتهاء الباقة الأساسية وعدم وجود رصيد سالب.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptions() {
    const items = [5, 10, 20];
    const prices = {5: '18 ل.س', 10: '33 ل.س', 20: '57 ل.س'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر حجم التمديد (GB)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((value) {
              final isSelected = value == _selectedReqSize;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedReqSize = value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 140,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$value GB',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prices[value] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Text(
                        //   'تمديد ${value == 20 ? "كبير" : value == 10 ? "متوسط" : "سريع"}',
                        //   style: TextStyle(color: Colors.grey.shade700),
                        // ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final double balance;
  final double availableTraffic;
  final double extraTraffic;
  final bool packageFinished;
  final bool hasNegativeBalance;

  const _StatusCard({
    required this.balance,
    required this.availableTraffic,
    required this.extraTraffic,
    required this.packageFinished,
    required this.hasNegativeBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'شروط التمديد',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _ConditionRow(
            title: 'انتهاء الباقة الأساسية',
            isValid: packageFinished,
            subtitle:
                'المتوفر (أساسي + إضافي): ${availableTraffic.toStringAsFixed(2)} GB',
          ),
          const SizedBox(height: 8),
          _ConditionRow(
            title: ' رصيد سالب',
            isValid: !hasNegativeBalance,
            subtitle: 'الرصيد الحالي: ${balance.toStringAsFixed(2)} ل.س',
          ),
          if (extraTraffic > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'لديك ترافيك إضافي: ${extraTraffic.toStringAsFixed(2)} GB',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isValid;

  const _ConditionRow({
    required this.title,
    required this.isValid,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = isValid ? const Color(0xFF2E7D32) : Colors.red.shade600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isValid ? Icons.check_circle : Icons.error_outline, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

