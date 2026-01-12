import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../cubits/extend_validity_cubit.dart';
import '../../../cubits/extend_validity_state.dart';
import '../../../models/userinfo_model.dart';
import '../../../core/ui.dart';

const Map<String, int> kExtendValidityPrices = {
  '512': 20,
  '1': 30,
  '2': 35,
  '4': 50,
  '8': 75,
  '16': 115,
  '24': 150,
};

const int kExtendValidityFallbackPrice = 6000;

class ExtendValiditySheet extends StatefulWidget {
  final UserData? data;
  final BuildContext rootContext;
  final Future<void> Function() onSuccessRefresh;

  const ExtendValiditySheet({
    super.key,
    required this.data,
    required this.rootContext,
    required this.onSuccessRefresh,
  });

  @override
  State<ExtendValiditySheet> createState() => _ExtendValiditySheetState();
}

class _ExtendValiditySheetState extends State<ExtendValiditySheet> {
  late final ExtendValidityCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ExtendValidityCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cubit.reset();
    });
  }

  @override
  void dispose() {
    _cubit.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.data?.user?.account;
    final speedLabel = account?.speed?.isNotEmpty == true
        ? account!.speed!
        : 'غير محددة';
    final priceResult = _resolveSpeedPrice(account?.speed);
    final expiryInfo = _evaluateExpiry(account?.expireDate);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<ExtendValidityCubit, ExtendValidityState>(
        bloc: _cubit,
        listenWhen: (previous, current) =>
            current is ExtendValiditySuccess || current is ExtendValidityError,
        listener: (ctx, state) async {
          if (!mounted) return;
          if (state is ExtendValiditySuccess) {
            await widget.onSuccessRefresh();
          }
        },
        builder: (ctx, state) {
          final isLoading = state is ExtendValidityLoading;
          final isSuccess = state is ExtendValiditySuccess;
          final isError = state is ExtendValidityError;
          final price = priceResult.price;

          Widget? statusBox;
          if (isSuccess) {
            statusBox = _StatusBox(
              icon: Icons.check_circle_outline,
              color: const Color(0xFF2E7D32),
              message: state.message,
            );
          } else if (isError) {
            statusBox = _StatusBox(
              icon: Icons.error_outline,
              color: Colors.red.shade700,
              message: state.message,
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const Text(
                  'تأكيد تمديد الصلاحية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                // Text(
                //   'سيتم تمديد الاشتراك لمدة 3 أيام.',
                //   style: const TextStyle(fontSize: 14.5),
                // ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.speed,
                      label: 'السرعة',
                      value: speedLabel,
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.price_check_outlined,
                      label: 'الكلفة',
                      value: '$price ل.س',
                    ),
                  ],
                ),
                if (priceResult.usedFallback) ...[
                  const SizedBox(height: 8),
                  // Text(
                  //   'لم نتمكن من تحديد السرعة بدقة، تم استخدام سعر افتراضي.',
                  //   style: TextStyle(
                  //     color: Colors.orange.shade800,
                  //     fontSize: 13,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                ],
                if (!expiryInfo.isEligible) ...[
                  const SizedBox(height: 12),
                  _StatusBox(
                    icon: Icons.info_outline,
                    color: Colors.orange.shade800,
                    message: expiryInfo.message,
                  ),
                ],
                if (statusBox != null) ...[
                  const SizedBox(height: 12),
                  statusBox,
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: (isLoading || isSuccess || !expiryInfo.isEligible)
                      ? null
                      : () => _submit(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
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
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    isLoading
                        ? 'جارٍ تنفيذ الطلب'
                        : isSuccess
                        ? 'تم تمديد الصلاحية'
                        : expiryInfo.isEligible
                        ? 'مدد 3 أيام مقابل $price ل.س'
                        : 'التمديد غير متاح حالياً',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');

    if (!mounted) return;
    if (token == null || username == null) {
      showAppMessage(
        widget.rootContext,
        'الرجاء تسجيل الدخول مجدداً.',
        type: AppMessageType.error,
      );
      return;
    }

    await _cubit.extendValidity(username: username, token: token);
  }

  _ExtendPriceResult _resolveSpeedPrice(String? rawSpeed) {
    final key = _extractSpeedKey(rawSpeed);
    if (key != null && kExtendValidityPrices.containsKey(key)) {
      return _ExtendPriceResult(
        price: kExtendValidityPrices[key]!,
        usedFallback: false,
      );
    }
    return _ExtendPriceResult(
      price: kExtendValidityFallbackPrice,
      usedFallback: true,
    );
  }

  String? _extractSpeedKey(String? rawSpeed) {
    if (rawSpeed == null) return null;
    final lower = rawSpeed.toLowerCase();

    if (lower.contains('512')) return '512';

    final match = RegExp(r'([0-9]+(?:\\.[0-9]+)?)').firstMatch(lower);
    if (match != null) {
      final value = double.tryParse(match.group(1)!);
      if (value != null) {
        double normalized = value;
        if (normalized >= 500) {
          normalized = normalized / 1024;
        }

        const allowed = [1, 2, 4, 8, 16, 24];
        for (final target in allowed) {
          if ((normalized - target).abs() < 0.2) {
            return target.toString();
          }
        }

        if (normalized % 1 == 0) return normalized.toInt().toString();
        return normalized.toString();
      }
    }
    return null;
  }

  _ExpiryInfo _evaluateExpiry(String? rawDate) {
    final expiry = _parseExpiryDate(rawDate);
    if (expiry == null) {
      return _ExpiryInfo(
        isEligible: false,
        message:
            'تعذر تحديد تاريخ الصلاحية، التمديد متاح بعد انتهاء الصلاحية خلال 24 ساعة.',
      );
    }

    final now = DateTime.now();
    if (now.isBefore(expiry)) {
      return _ExpiryInfo(
        isEligible: false,
        message: 'التمديد متاح بعد انتهاء الصلاحية.',
      );
    }

    return _ExpiryInfo(isEligible: true, message: '');
  }

  DateTime? _parseExpiryDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();

    final formats = [
      RegExp(r'^\\d{4}-\\d{2}-\\d{2}$'), // 2024-09-21
      RegExp(r'^\\d{4}/\\d{2}/\\d{2}$'), // 2024/09/21
      RegExp(r'^\\d{2}-\\d{2}-\\d{4}$'), // 21-09-2024
      RegExp(r'^\\d{2}/\\d{2}/\\d{4}$'), // 21/09/2024
    ];

    String normalized = text;
    if (formats.any((f) => f.hasMatch(text))) {
      final withDashes = text.replaceAll('/', '-');
      normalized = '$withDashes 12:00:00';
    }

    return DateTime.tryParse(normalized);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _StatusBox({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtendPriceResult {
  final int price;
  final bool usedFallback;

  _ExtendPriceResult({required this.price, required this.usedFallback});
}

class _ExpiryInfo {
  final bool isEligible;
  final String message;

  _ExpiryInfo({required this.isEligible, required this.message});
}
