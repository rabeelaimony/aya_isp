// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/traffic_package_cubit.dart';
import '../../cubits/traffic_package_state.dart';
import '../../models/traffic_package_model.dart';
import '../../cubits/userinfo_cubit.dart';
import '../../cubits/traffic_charge_cubit.dart';
import '../../widgets/recharge_processing_dialog.dart';
import '../../core/ui.dart';

class PackagesListScreen extends StatefulWidget {
  const PackagesListScreen({super.key});

  @override
  State<PackagesListScreen> createState() => _PackagesListScreenState();
}

class _PackagesListScreenState extends State<PackagesListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TrafficPackagesCubit>().fetchPackages();
  }

  String formatPrice(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return value;
    return NumberFormat('#,##0', 'en_US').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قائمة باقات الشحن')),
        body: BlocBuilder<TrafficPackagesCubit, TrafficPackagesState>(
          builder: (context, state) {
            if (state is TrafficPackagesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TrafficPackagesError) {
              return Center(child: Text('خطأ: ${state.message}'));
            }
            if (state is TrafficPackagesLoaded) {
              final List<TrafficPackage> packages = state.packages;
              if (packages.isEmpty) {
                return const Center(child: Text('لا توجد باقات'));
              }

              // Wrap the list with a Stack so we can show fixed buttons on top
              // (right: renewal details, left: monthly total usage)
              return Stack(
                children: [
                  ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: packages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final pkg = packages[index];
                      final price = double.tryParse(pkg.price) ?? 0.0;

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // تفاصيل الباقة
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pkg.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'السعر: ${formatPrice(pkg.price)} ل.س',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),

                              // زر الشحن
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('شحن'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChargeExtraTrafficScreen(
                                        packageId: pkg.id,
                                        packagePrice: price,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Buttons removed: renewal and monthly usage removed from this screen
                ],
              );
            }

            return const Center(child: Text('اضغط للتحديث'));
          },
        ),
      ),
    );
  }
}

/// شاشة شحن الترافيك الإضافي (مضمّنة هنا لتفادي مشاكل الاستيراد)
class ChargeExtraTrafficScreen extends StatefulWidget {
  final double packagePrice; // سعر الباقة
  final String packageId; // معرف الباقة المطلوب شحنها

  const ChargeExtraTrafficScreen({
    super.key,
    required this.packagePrice,
    required this.packageId,
  });

  @override
  State<ChargeExtraTrafficScreen> createState() =>
      _ChargeExtraTrafficScreenState();
}

class _ChargeExtraTrafficScreenState extends State<ChargeExtraTrafficScreen> {
  bool _isCharging = false; // للتحكم بزر الشحن

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl, // ✅ دعم اتجاه عربي
      child: Scaffold(
        appBar: AppBar(title: const Text('شحن باقة إضافية'), centerTitle: true),
        body: BlocBuilder<UserInfoCubit, UserInfoState>(
          builder: (context, state) {
            if (state is UserInfoLoaded) {
              final int rawBalance = state.userInfo.data?.balance ?? 0;
              final double balance = rawBalance.toDouble();
              final bool canAfford = balance >= widget.packagePrice;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'رصيدك الحالي: ${balance.toStringAsFixed(2)} ل.س',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'سعر الباقة: ${widget.packagePrice.toStringAsFixed(2)} ل.س',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: (!canAfford || _isCharging)
                          ? null
                          : () async {
                              setState(() {
                                _isCharging = true;
                              });

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final storedToken = prefs.getString('token');
                              final storedUsername =
                                  state.userInfo.data?.user?.personal?.username;

                              if (storedUsername == null ||
                                  storedToken == null) {
                                showAppMessage(
                                  context,
                                  'المستخدم غير مسجل ',
                                  type: AppMessageType.error,
                                );
                                setState(() => _isCharging = false);
                                return;
                              }

                              try {
                                final msg = await context
                                    .read<TrafficChargeCubit>()
                                    .chargePackage(
                                      username: storedUsername,
                                      packageId: widget.packageId,
                                      token: storedToken,
                                    );

                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const RechargeProcessingDialog(
                                    seconds: 60,
                                    message:
                                        'تم استلام طلب شحن الباقة الإضافية وسيتم تنفيذ العملية خلال لحظات. يرجى الانتظار... سيتم تحديث البيانات تلقائياً.',
                                  ),
                                );

                                if (!mounted) return;
                                // Allow the dialog route to fully pop before popping this screen.
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 150),
                                );
                                if (!mounted) return;
                                showAppMessage(
                                  context,
                                  msg,
                                  type: AppMessageType.success,
                                );
                                Navigator.of(context).maybePop();
                              } catch (e) {
                                String text;
                                if (e is Exception) {
                                  text = e.toString().replaceFirst(': ', '');
                                } else {
                                  text = e.toString();
                                }

                                showAppMessage(
                                  context,
                                  text,
                                  type: AppMessageType.error,
                                );
                              } finally {
                                setState(() {
                                  _isCharging = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isCharging
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'شحن الباقة',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

