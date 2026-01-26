import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/recharge_adsl_cubit.dart';
import '../../cubits/recharge_adsl_state.dart';
import '../../cubits/userinfo_cubit.dart';
import '../../widgets/recharge_processing_dialog.dart';
import '../../core/ui.dart';

class RechargeAccountScreen extends StatefulWidget {
  const RechargeAccountScreen({super.key});

  @override
  State<RechargeAccountScreen> createState() => _RechargeAccountScreenState();
}

class _RechargeAccountScreenState extends State<RechargeAccountScreen> {
  int _months = 1;
  String? _username;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    setState(() {
      _token = token;
      _username = username;
    });

    if (token != null && username != null) {
      final userCubit = context.read<UserInfoCubit>();
      if (userCubit.state is! UserInfoLoaded) {
        await userCubit.fetchUserInfo(token, username);
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userState = context.watch<UserInfoCubit>().state;
    int balance = 0;
    int monthlyPrice = 0;

    if (userState is UserInfoLoaded) {
      final data = userState.userInfo.data;
      balance = data?.balance ?? 0;

      final speedList = data?.user?.account?.speedPrice;
      if (speedList != null && speedList.isNotEmpty) {
        final raw = speedList[0].price?.toString() ?? '';
        monthlyPrice = double.tryParse(raw)?.toInt() ?? int.tryParse(raw) ?? 0;
      }
    }

    if (monthlyPrice == 0 && userState is UserInfoLoaded) {
      final data = userState.userInfo.data;
      final speedList = data?.user?.account?.speedPrice;
      if (speedList != null && speedList.isNotEmpty) {
        final rawCandidate =
            speedList[0].packagename ?? speedList[0].quota ?? '';
        final parsed =
            double.tryParse(rawCandidate)?.toInt() ??
            int.tryParse(rawCandidate);
        if (parsed != null && parsed > 0) monthlyPrice = parsed;
      }
    }

    final total = monthlyPrice * _months;
    final insufficient = total > balance;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تجديد الاشتراك')),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.primary.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'رصيد الحساب',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('$balance ل.س'),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'سعر الشهر',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    monthlyPrice > 0
                                        ? '$monthlyPrice ل.س'
                                        : '- ل.س',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.06,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'عدد الأشهر',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'الإجمالي: $total ل.س',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: _months > 1
                                            ? () => setState(() => _months--)
                                            : null,
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          '$_months',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _months < 6
                                            ? () => setState(() => _months++)
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (insufficient) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'الرصيد غير كافٍ لإتمام عملية التجديد.',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  BlocConsumer<RechargeAdslCubit, RechargeAdslState>(
                    listener: (context, state) async {
                      if (state is RechargeAdslSuccess) {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const RechargeProcessingDialog(
                            seconds: 60,
                            message:
                                'تم استلام طلب التجديد وسيتم تنفيذ العملية خلال لحظات. يرجى الانتظار... سيتم تحديث البيانات تلقائياً.',
                          ),
                        );
                        if (!mounted) return;
                        // Allow the dialog route to fully pop before popping this screen.
                        await Future<void>.delayed(
                          const Duration(milliseconds: 150),
                        );
                        if (mounted) Navigator.of(context).maybePop(true);
                      } else if (state is RechargeAdslError) {
                        showAppMessage(
                          context,
                          state.message,
                          type: AppMessageType.error,
                        );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is RechargeAdslLoading;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (insufficient ||
                                  _username == null ||
                                  _token == null ||
                                  isLoading)
                              ? null
                              : () async {
                                  await context
                                      .read<RechargeAdslCubit>()
                                      .recharge(
                                        username: _username!,
                                        duration: _months,
                                        token: _token!,
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'تجديد الاشتراك',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

