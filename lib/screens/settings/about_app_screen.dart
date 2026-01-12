import 'package:flutter/material.dart';
import 'package:aya_isp/core/legal_texts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حول التطبيق')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تطبيق مزود الإنترنت آية مصمم ليمنحك تحكمًا كاملاً بخدمات الإنترنت الخاصة بك بسهولة وأمان.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              _FeatureItem(
                icon: Icons.account_circle_outlined,
                title: 'إدارة الحسابات',
                subtitle:
                    'أضف حسابات جديدة، بدّل بينها دون تسجيل خروج، واطّلع على تفاصيل كل حساب نشط.',
              ),
              _FeatureItem(
                icon: Icons.speed_outlined,
                title: 'متابعة الاستهلاك',
                subtitle:
                    'اطّلع على استخدام الترافيك الشهري، وتتبع جلسات الاتصال وتفاصيل السرعة.',
              ),
              _FeatureItem(
                icon: Icons.add_shopping_cart_outlined,
                title: 'شحن وتمديد الخدمة',
                subtitle:
                    'اشحن ترافيك إضافي، أو مدد الترافيك أو الصلاحية حسب احتياجك بخطوات بسيطة.',
              ),
              _FeatureItem(
                icon: Icons.receipt_long_outlined,
                title: 'البيان المالي',
                subtitle:
                    'راجع الفواتير، المدفوعات، والرصيد المتبقي مع إشعارات دورية بالتحديثات.',
              ),
              _FeatureItem(
                icon: Icons.notifications_active_outlined,
                title: 'الإشعارات الفورية',
                subtitle:
                    'استلم تنبيهات بمواعيد الاستحقاق، التغييرات المهمة، وأخبار الصيانة أو الأعطال.',
              ),
              _FeatureItem(
                icon: Icons.security_outlined,
                title: 'الأمان والخصوصية',
                subtitle:
                    'غيّر كلمة المرور، وأدر الأجهزة المتصلة، واضبط إعدادات المودم لتأمين شبكتك.',
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _openLegalUrl(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('عرض سياسة الخصوصية'),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'لأي استفسار أو دعم فني، يمكنك التواصل عبر الرقم 0119806.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openLegalUrl(BuildContext context) async {
  final uri = Uri.parse(privacyText);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showLaunchError(context);
    }
  } catch (_) {
    _showLaunchError(context);
  }
}

void _showLaunchError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('تعذر فتح صفحة سياسة الخصوصية. يرجى المحاولة لاحقًا.'),
    ),
  );
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
