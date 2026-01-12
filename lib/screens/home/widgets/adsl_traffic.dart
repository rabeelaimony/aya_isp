import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/adsl_traffic_cubit.dart';
import '../../../models/userinfo_model.dart';
import 'countdown_gauge.dart';

class AdslTrafficWidget extends StatelessWidget {
  final String username;
  final Account? account;
  const AdslTrafficWidget({super.key, required this.username, this.account});

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatTraffic(double? value) {
    if (value == null) return '-';
    double d = value;
    if (d < 0) d = 0;

    if (d >= 1024 * 1024 * 1024) {
      return '${(d / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (d >= 1024 * 1024) {
      return '${(d / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (d >= 1024) {
      return '${(d / 1024).toStringAsFixed(2)} KB';
    }
    return '${d.toStringAsFixed(0)} B';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdslTrafficCubit, AdslTrafficState>(
      builder: (context, state) {
        if (state is AdslTrafficLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdslTrafficError) {
          return Center(child: Text(state.message));
        }

        if (state is AdslTrafficLoaded) {
          final data = state.response?.data;

          final double accountAvailable =
              _toDouble(account?.availableTraffic) ?? 0.0;
          final double accountExtra = _toDouble(account?.extraTraffic) ?? 0.0;
          final double offerTraffic =
              _toDouble(account?.offerExtraTraffic) ?? 0.0;

          final double total =
              data?.totalTrafficPackage ?? (accountAvailable + accountExtra);
          final double available = accountAvailable > 0
              ? accountAvailable
              : data?.availableTraffic ?? 0.0;
          final double extra = accountExtra > 0
              ? accountExtra
              : data?.extraTraffic ?? 0.0;
          final String renewed = data?.trafficRenewedAt ?? '-';
          final double usagePercent = data?.percentageUsage ?? 0.0;

          final bool isBaseFinished = available <= 0;
          final bool hasExtra = extra > 0;
          final bool hasOffer = offerTraffic > 0;
          final bool isThrottled = isBaseFinished && !hasExtra && !hasOffer;

          final pages = <Widget>[];

          if (hasOffer) {
            pages.add(_buildOfferCard(context, offerTraffic));
          }

          if (isBaseFinished && (hasExtra || hasOffer)) {
            if (hasExtra) {
              pages.add(_buildExtraCard(context, extra));
            }
            pages.add(
              Center(
                child: CountdownGaugeWidget(
                  percent: usagePercent,
                  available: available,
                  total: total,
                  renewed: renewed,
                  isThrottled: isThrottled,
                ),
              ),
            );
          } else {
            pages.add(
              CountdownGaugeWidget(
                percent: usagePercent,
                available: available,
                total: total,
                renewed: renewed,
                isThrottled: isThrottled,
              ),
            );
            if (hasExtra) {
              pages.add(_buildExtraCard(context, extra));
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _GaugePager(pages: pages),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOfferCard(BuildContext context, double offer) {
    final theme = Theme.of(context);
    final offerLabel = _formatTraffic(offer);

    return Center(
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'المتبقي من باقة العروض',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              offerLabel,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraCard(BuildContext context, double extra) {
    final theme = Theme.of(context);
    final extraLabel = _formatTraffic(extra);

    return Center(
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'المتبقي من الباقة الإضافية',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              extraLabel,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePager extends StatefulWidget {
  final List<Widget> pages;
  const _GaugePager({required this.pages});

  @override
  State<_GaugePager> createState() => _GaugePagerState();
}

class _GaugePagerState extends State<_GaugePager> {
  late PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double finalHeight = math.min(
      screenWidth * 0.8,
      math.min(screenHeight * 0.5, 360.0),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: finalHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => widget.pages[index],
              ),
              if (widget.pages.length > 1) ...[
                Positioned(
                  left: 8,
                  child: IconButton(
                    onPressed: _index > 0
                        ? () => _controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.chevron_left,
                        color: _index > 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 28,
                      ),
                    ),
                    tooltip: 'السابق',
                  ),
                ),
                Positioned(
                  right: 8,
                  child: IconButton(
                    onPressed: _index < widget.pages.length - 1
                        ? () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.chevron_right,
                        color: _index < widget.pages.length - 1
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 28,
                      ),
                    ),
                    tooltip: 'التالي',
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pages.length, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _index == i ? 10 : 8,
              height: _index == i ? 10 : 8,
              decoration: BoxDecoration(
                color: _index == i
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}
