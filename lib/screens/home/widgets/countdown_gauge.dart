import 'dart:math' as math;
import 'package:flutter/material.dart';

String _formatTrafficValue(double bytes) {
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

class CountdownGaugeWidget extends StatefulWidget {
  final double percent;
  final double available;
  final double total;
  final String renewed;
  final bool isThrottled;

  const CountdownGaugeWidget({
    super.key,
    required this.percent,
    required this.available,
    required this.total,
    required this.renewed,
    required this.isThrottled,
  });

  String _twoDigits(int v) => v.toString().padLeft(2, '0');

  String _renewalMessage(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      final formatted =
          '${parsed.year}-${_twoDigits(parsed.month)}-${_twoDigits(parsed.day)}';
      return 'سيتم تجديد الباقة تلقائياً في $formatted عند الساعة 11:00 صباحاً.';
    } catch (_) {
      return 'سيتم تجديد الباقة تلقائياً عند بداية الصلاحية الجديدة عند الساعة 11:00 صباحاً.';
    }
  }

  void _showRenewalInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'تفاصيل تجديد الباقة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _renewalMessage(renewed),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'حسناً',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<CountdownGaugeWidget> createState() => _CountdownGaugeWidgetState();
}

class _CountdownGaugeWidgetState extends State<CountdownGaugeWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _hasInternalScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHasScroll());
  }

  void _syncHasScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final hasScroll = _scrollController.position.maxScrollExtent > 0;
    if (hasScroll != _hasInternalScroll) {
      setState(() => _hasInternalScroll = hasScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color mainColor = widget.isThrottled
        ? Colors.red
        : theme.colorScheme.primary;

    final double totalBytes = widget.total * 1024 * 1024 * 1024;
    final double availableBytes = widget.available;

    final double serverPercent = widget.percent.isFinite && widget.percent > 0
        ? widget.percent
        : 0;
    final double computedPercent = widget.total > 0
        ? ((widget.total - widget.available) / widget.total) * 100
        : 0;

    double usedPercent = math.max(serverPercent, computedPercent);

    if (widget.available <= 0.001 && widget.total > 0) {
      usedPercent = 100;
    }

    final double normalizedPercent =
        (usedPercent >= 99.5 || (widget.available <= 0.01 && widget.total > 0))
        ? 100
        : usedPercent.clamp(0, 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final double cardWidth = math.min(maxWidth, 420);
        final double gaugeDiameter = math.max(
          math.min(cardWidth * 0.72, 280),
          140,
        );
        final double gaugeThickness = gaugeDiameter * 0.1;

        final Color consumedColor = theme.colorScheme.primary;
        final Color remainingColor = theme.colorScheme.primary.withOpacity(0.2);

        final double consumedVal = (totalBytes - availableBytes).clamp(
          0,
          totalBytes,
        );

        final scrollbarTheme = ScrollbarThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            final base = theme.colorScheme.primary;
            if (states.contains(WidgetState.dragged) ||
                states.contains(WidgetState.hovered)) {
              return base.withValues(alpha: 0.95);
            }
            return base.withValues(alpha: 0.85);
          }),
          trackColor: WidgetStateProperty.all(
            theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          trackBorderColor: WidgetStateProperty.all(
            theme.colorScheme.onSurface.withValues(alpha: 0.18),
          ),
          thickness: WidgetStateProperty.all(10),
          radius: const Radius.circular(12),
          crossAxisMargin: 2,
          mainAxisMargin: 2,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Center(
            child: SizedBox(
              width: cardWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (notification) {
                      final hasScroll =
                          notification.metrics.maxScrollExtent > 0;
                      if (hasScroll != _hasInternalScroll && mounted) {
                        setState(() => _hasInternalScroll = hasScroll);
                      }
                      return false;
                    },
                    child: ScrollbarTheme(
                      data: scrollbarTheme,
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: _hasInternalScroll,
                        trackVisibility: _hasInternalScroll,
                        interactive: _hasInternalScroll,
                        scrollbarOrientation: ScrollbarOrientation.right,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'الباقة الأساسية',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: mainColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _SemiCircularGauge(
                                  diameter: gaugeDiameter,
                                  strokeWidth: gaugeThickness,
                                  percent: normalizedPercent,
                                  available: widget.available,
                                  total: widget.total,
                                  consumedColor: consumedColor,
                                  remainingColor: remainingColor,
                                  theme: theme,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 14,
                                  runSpacing: 6,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: consumedColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_formatTrafficValue(consumedVal)} مستهلك',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_formatTrafficValue(availableBytes)} متبقي',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: remainingColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SemiCircularGauge extends StatelessWidget {
  final double diameter;
  final double strokeWidth;
  final double percent;
  final double available;
  final double total;
  final Color consumedColor;
  final Color remainingColor;
  final ThemeData theme;

  const _SemiCircularGauge({
    required this.diameter,
    required this.strokeWidth,
    required this.percent,
    required this.available,
    required this.total,
    required this.consumedColor,
    required this.remainingColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final double height = diameter / 2 + strokeWidth * 0.7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: diameter,
          height: height,
          child: CustomPaint(
            size: Size(diameter, height),
            painter: _SemiGaugePainter(
              percent: percent,
              strokeWidth: strokeWidth,
              progressColor: consumedColor,
              backgroundColor: remainingColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Text(
                'GB الحزمة الكلية: ${total.truncate()} ',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SemiGaugePainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _SemiGaugePainter({
    required this.percent,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2 - strokeWidth / 2;
    final Offset center = Offset(size.width / 2, size.height);
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    const double startAngle = math.pi;
    const double sweepAngle = math.pi;

    final Paint basePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, basePaint);

    final Gradient gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [progressColor, progressColor],
    );

    final Paint progressPaint = Paint()
      ..shader = gradient.createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final bool nearlyFull = percent >= 99.5;
    final double progressStart = startAngle;
    final double progressSweep = nearlyFull
        ? sweepAngle
        : sweepAngle * (percent.clamp(0, 100) / 100);

    canvas.drawArc(arcRect, progressStart, progressSweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
