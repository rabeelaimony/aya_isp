import 'dart:async';
import 'package:flutter/material.dart';

import 'package:aya_isp/services/notification_center.dart';

class RechargeProcessingDialog extends StatefulWidget {
  final int seconds;
  final String message;
  final VoidCallback? onComplete;
  final bool closeOnNotification;
  final bool Function(ReceivedNotification notification)? notificationMatcher;

  const RechargeProcessingDialog({
    super.key,
    this.seconds = 60,
    this.message = 'تم العملية بنجاح، الرجاء الانتظار حتى تكتمل العملية',
    this.onComplete,
    this.closeOnNotification = true,
    this.notificationMatcher,
  });

  @override
  State<RechargeProcessingDialog> createState() =>
      _RechargeProcessingDialogState();
}

class _RechargeProcessingDialogState extends State<RechargeProcessingDialog> {
  late int _remaining;
  Timer? _timer;
  StreamSubscription<ReceivedNotification>? _incomingSub;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    // Debug
    // print('RechargeProcessingDialog: start $_remaining seconds');
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining -= 1);
      if (_remaining <= 0) {
        _complete();
      }
    });

    if (widget.closeOnNotification) {
      _incomingSub = NotificationCenter.instance.incoming.listen((n) {
        if (!mounted || _completed) return;
        final matcher = widget.notificationMatcher ?? _defaultMatcher;
        if (matcher(n)) _complete();
      });
    }
  }

  bool _defaultMatcher(ReceivedNotification notification) {
    // Default behavior: stop the countdown as soon as ANY FCM notification
    // arrives while this dialog is open. If you need to filter, provide
    // [notificationMatcher].
    return notification.title.isNotEmpty ||
        notification.body.isNotEmpty ||
        notification.data.isNotEmpty;
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    _timer?.cancel();
    _incomingSub?.cancel();

    try {
      widget.onComplete?.call();
    } catch (_) {}

    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _incomingSub?.cancel();
    super.dispose();
  }

  String _format(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Material(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  _format(_remaining),
                  style:
                      Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'الرجاء الانتظار  حتى تتم العملية',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
