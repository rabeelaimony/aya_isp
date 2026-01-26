import 'package:flutter/material.dart';

import '../../../models/adsl_traffic_model.dart';

class AccountCard extends StatefulWidget {
  final dynamic account;
  final dynamic data;
  final AdslData? trafficData;

  const AccountCard({super.key, this.account, this.data, this.trafficData});

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _pulseActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    _updatePulse(_isDueSoon());
  }

  @override
  void didUpdateWidget(covariant AccountCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePulse(_isDueSoon());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updatePulse(bool shouldAnimate) {
    if (shouldAnimate && !_pulseActive) {
      _pulseController.repeat(reverse: true);
      _pulseActive = true;
    } else if (!shouldAnimate && _pulseActive) {
      _pulseController.stop();
      _pulseController.reset();
      _pulseActive = false;
    }
  }

  bool _isDueSoon() {
    final expDate = widget.account?.expireDate?.toString();
    if (expDate == null || expDate.isEmpty) return false;
    final remaining = _calculateRemainingDays(expDate);
    return remaining <= 5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusInfo = _getAccountStatus(widget.account?.deleted, theme);
    final accountType = _getAccountType(widget.account?.accType);

    final String monthlyPrice =
        (widget.account?.speedPrice != null &&
            widget.account.speedPrice is List &&
            widget.account.speedPrice.isNotEmpty)
        ? (double.tryParse(
                    widget.account.speedPrice[0].price.toString(),
                  )?.toInt() ??
                  widget.account.speedPrice[0].price)
              .toString()
        : '-';

    final rawBalance = widget.data?.balance;
    final double balanceNum = rawBalance is num
        ? rawBalance.toDouble()
        : double.tryParse(rawBalance?.toString() ?? '') ?? 0;
    final String balanceValue = balanceNum.toStringAsFixed(0);
    final int remainingDays = _calculateRemainingDays(
      widget.account?.expireDate?.toString(),
    );
    final bool isDueSoon = remainingDays <= 5;
    _updatePulse(isDueSoon);

    final backgroundGradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.35),
        theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: backgroundGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.05,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.wallet_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'معلومات الحساب',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        _StatusChip(
                          label: statusInfo["text"],
                          color: statusInfo["color"],
                          textColor: statusInfo["textColor"],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      theme,
                      rightTitle: 'قيمة الاشتراك',
                      rightValue: Text(
                        '$monthlyPrice ل.س',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leftTitle: 'المحفظة',
                      leftValue: Text(
                        '$balanceValue ل.س',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      theme,
                      rightTitle: 'السرعة',
                      rightValue: _buildSpeedValue(theme),
                      leftTitle: 'نوع الحساب',
                      leftValue: Text(
                        accountType,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      theme,
                      rightTitle: 'الأيام المتبقية',
                      rightValue: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$remainingDays يوم',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isDueSoon) const SizedBox(height: 6),
                          if (isDueSoon)
                            ScaleTransition(
                              scale: Tween<double>(
                                begin: 1.0,
                                end: 1.04,
                              ).animate(_pulse),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'تذكير بالدفع',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      leftTitle: ' تاريخ انتهاء الصلاحية ',
                      leftValue: Text(
                        widget.account?.expireDate ?? '-',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // reminder is now shown inline inside the 'الأيام المتبقية' field
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required String rightTitle,
    required Widget rightValue,
    required String leftTitle,
    required Widget leftValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItemNoIcon(
              title: rightTitle,
              value: rightValue,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoItemNoIcon(
              title: leftTitle,
              value: leftValue,
              theme: theme,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedValue(ThemeData theme) {
    final speedLabel = _resolveSpeedLabel();
    if (_isReducedSpeedMode()) {
      final reducedColor = Colors.pink.shade400;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showReducedSpeedInfo(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              speedLabel,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: reducedColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(reducedColor),
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      speedLabel,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  String _resolveSpeedLabel() {
    final rawSpeed = widget.account?.speed?.toString();
    if (rawSpeed != null && rawSpeed.isNotEmpty) return rawSpeed;

    final speedList = widget.account?.speedPrice;
    if (speedList is List && speedList.isNotEmpty) {
      final fallback = speedList[0]?.speed?.toString();
      if (fallback != null && fallback.isNotEmpty) return fallback;
    }

    return '-';
  }

  bool _isReducedSpeedMode() {
    final traffic = widget.trafficData;
    if (traffic == null) return false;
    final available = traffic.availableTraffic ?? 0;
    final extra = traffic.extraTraffic ?? 0;
    final hasTrafficLeft = (available + extra) > 0;
    final reducedPool = traffic.reducedSpeedTraffic ?? 0;
    final exhausted = (traffic.percentageRest ?? 0) <= 0;
    return !hasTrafficLeft && (reducedPool > 0 || exhausted);
  }

  void _showReducedSpeedInfo(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('أنت ضمن السرعة المخفضة'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  int _calculateRemainingDays(String? expDate) {
    try {
      if (expDate == null || expDate.isEmpty) return 0;
      final expiry = DateTime.parse(expDate);
      final now = DateTime.now();
      final diff = expiry.difference(now).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  String _getAccountType(String? accType) {
    switch (accType) {
      case '9':
        return 'حساب نقابي';
      case 'A':
        return 'حساب عادي';
      case 'D':
        return 'VIP';
      case '5':
        return 'حساب موظفين';
      default:
        return 'غير معروف';
    }
  }

  Map<String, dynamic> _getAccountStatus(String? deleted, ThemeData theme) {
    if (deleted == null || deleted.isEmpty) {
      return {'text': 'مفعل', 'color': Colors.green, 'textColor': Colors.white};
    }
    switch (deleted.toLowerCase()) {
      case 'd':
        return {
          'text': 'منتهي الصلاحية',
          'color': Colors.yellow.shade700,
          'textColor': Colors.black,
        };
      case 'h':
        return {
          'text': 'انتظار',
          'color': Colors.lightBlueAccent,
          'textColor': Colors.black,
        };
      case 's':
        return {
          'text': 'موقوف',
          'color': Colors.red,
          'textColor': Colors.white,
        };
      case 'f':
        return {
          'text': 'مجمد',
          'color': Colors.grey,
          'textColor': Colors.white,
        };
      default:
        return {
          'text': 'غير معروف',
          'color': Colors.grey,
          'textColor': Colors.white,
        };
    }
  }

  Widget _buildInfoItemNoIcon({
    required String title,
    required Widget value,
    required ThemeData theme,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
