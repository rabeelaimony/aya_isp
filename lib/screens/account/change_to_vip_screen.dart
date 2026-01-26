import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/change_account_cubit.dart';
import '../../cubits/change_account_state.dart';
import '../../core/ui.dart';

class ChangeToVipScreen extends StatefulWidget {
  const ChangeToVipScreen({super.key});

  @override
  State<ChangeToVipScreen> createState() => _ChangeToVipScreenState();
}

class _ChangeToVipScreenState extends State<ChangeToVipScreen> {
  String? _username;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadCreds();
  }

  Future<void> _loadCreds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
      _token = prefs.getString('token');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلب تعديل الحساب إلى VIP')),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                radius: 24,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                child: Icon(
                                  Icons.workspace_premium_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'اسم المستخدم',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _username ?? '-',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ الملاحظة المطلوبة
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: const Text(
                      'سجّل طلبك للحصول على خدمة الـ VIP مع تشاركية بنسبة 1/2، '
                      'وسيتم التواصل معك قريباً.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  BlocConsumer<ChangeAccountCubit, ChangeAccountState>(
                    listener: (context, state) {
                      if (state is ChangeAccountSuccess) {
                        showAppMessage(
                          context,
                          state.message,
                          type: AppMessageType.success,
                        );
                        Navigator.of(context).maybePop(true);
                      } else if (state is ChangeAccountError) {
                        showAppMessage(
                          context,
                          state.message,
                          type: AppMessageType.error,
                        );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is ChangeAccountLoading;
                      final canSubmit =
                          _username != null && _token != null && !isLoading;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.star_rate_rounded),
                            onPressed: canSubmit
                                ? () => context
                                      .read<ChangeAccountCubit>()
                                      .changeToVip(
                                        username: _username!,
                                        token: _token!,
                                      )
                                : null,
                            label: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('تقديم طلب تعديل الحساب الى VIP'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
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

