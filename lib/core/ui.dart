import 'package:flutter/material.dart';

enum AppMessageType { info, success, error }

/// Shows a unified snackbar across the app with consistent colors and shape.
void showAppMessage(
  BuildContext context,
  String message, {
  AppMessageType type = AppMessageType.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  Color background;
  IconData icon;

  switch (type) {
    case AppMessageType.success:
      background = colors.primary;
      icon = Icons.check_circle_rounded;
      break;
    case AppMessageType.error:
      background = colors.error;
      icon = Icons.error_rounded;
      break;
    case AppMessageType.info:
      background = colors.primaryContainer;
      icon = Icons.info_rounded;
      break;
  }

  final snackBar = SnackBar(
    backgroundColor: background,
    content: Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Icon(icon, color: colors.onPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    action: onAction != null
        ? SnackBarAction(
            label: actionLabel ?? 'إعادة المحاولة',
            textColor: colors.onPrimary,
            onPressed: onAction,
          )
        : null,
  );

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(snackBar);
}

void showSlowConnectionHint(
  BuildContext context, {
  String message = 'يرجى الانتظار، الاتصال ضعيف.',
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  final snackBar = SnackBar(
    backgroundColor: colors.surface.withOpacity(0.95),
    content: Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        message,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: colors.onSurface.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(snackBar);
}

void showRetryMessage(
  BuildContext context, {
  required VoidCallback onRetry,
  String? message,
}) {
  showAppMessage(
    context,
    message ?? 'يبدو الاتصال ضعيف. حاول مرة أخرى .',
    type: AppMessageType.error,
    actionLabel: 'إعادة المحاولة',
    onAction: onRetry,
  );
}

/// A reusable, modern error card used across the app for blocking errors.
class AppErrorCard extends StatelessWidget {
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppErrorCard({
    super.key,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.error.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.error.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.error_rounded, color: colors.error, size: 32),
            ),
            const SizedBox(height: 12),
            if (title != null && title!.isNotEmpty) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel ?? 'إعادة المحاولة'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
