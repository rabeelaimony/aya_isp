import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_navigator.dart';
import 'ui.dart';

class ForceUpdateInfo {
  ForceUpdateInfo({
    required this.force,
    this.message,
    this.storeUrl,
    this.latestVersion,
    this.minVersion,
  });

  final bool force;
  final String? message;
  final String? storeUrl;
  final String? latestVersion;
  final String? minVersion;

  bool get hasStoreLink => storeUrl != null && storeUrl!.trim().isNotEmpty;
}

class ForceUpdateService {
  ForceUpdateService._();
  static final instance = ForceUpdateService._();

  ForceUpdateInfo? _pendingInfo;
  bool _dialogScheduled = false;
  bool _dialogVisible = false;

  void notify(ForceUpdateInfo info) {
    if (!info.force || _dialogVisible || _pendingInfo != null) return;
    _pendingInfo = info;
    _scheduleDialog();
  }

  void _scheduleDialog() {
    if (_dialogScheduled) return;
    _dialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dialogScheduled = false;
      _showDialogIfNeeded();
    });
  }

  Future<void> _showDialogIfNeeded() async {
    final info = _pendingInfo;
    if (info == null || _dialogVisible) return;

    final navigator = appNavigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return _showDialogIfNeeded();
    }

    _dialogVisible = true;
    try {
      await showDialog<void>(
        context: navigator.context,
        barrierDismissible: false,
        builder: (ctx) =>
            _ForceUpdateDialog(info: info, onExit: () => SystemNavigator.pop()),
      );
    } finally {
      _dialogVisible = false;
      _pendingInfo = null;
    }
  }
}

class _ForceUpdateDialog extends StatelessWidget {
  const _ForceUpdateDialog({required this.info, required this.onExit});

  final ForceUpdateInfo info;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final title = 'تحديث مهم';

    final message = info.message?.trim().isNotEmpty == true
        ? info.message!
        : 'يتطلب التطبيق التحديث إلى أحدث إصدار للاستمرار. يرجى تحديث التطبيق من المتجر.';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(message, textAlign: TextAlign.right)],
        ),
        actions: [
          if (info.hasStoreLink)
            ElevatedButton.icon(
              onPressed: () => _launchStore(context, info.storeUrl!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('تحديث الآن'),
            ),
          TextButton(onPressed: onExit, child: const Text('إغلاق التطبيق')),
        ],
      ),
    );
  }

  Future<void> _launchStore(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      _showError(context, 'رابط التحديث غير صالح.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('Launch failed');
    } catch (_) {
      _showError(context, 'تعذر فتح صفحة التحديث. يرجى المحاولة لاحقاً.');
    }
  }

  void _showError(BuildContext context, String message) {
    showAppMessage(context, message, type: AppMessageType.error);
  }
}

