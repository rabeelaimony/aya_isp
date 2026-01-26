import 'package:flutter/material.dart';

class OffersNotificationsScreen extends StatelessWidget {
  const OffersNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E2E2E),
        elevation: 0.5,
        title: const Text('الإعلانات والتنبيهات العامة'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          children: const [
            _SectionHeader(title: 'العروض'),
            _NotificationCard(
              title: 'عرض باقات WiFi الجديدة',
              body: 'تم تحديث باقات الإنترنت اللاسلكي وأسعارها لهذا الشهر.',
              date: 'اليوم',
            ),
            _NotificationCard(
              title: 'خصم على الاشتراكات السنوية',
              body: 'خصم خاص عند تجديد الاشتراك السنوي لفترة محدودة.',
              date: 'قبل يومين',
            ),
            SizedBox(height: 20),
            _SectionHeader(title: 'الإشعارات العامة'),
            _NotificationCard(
              title: 'أوقات الدعم الفني',
              body: 'الدعم الفني متاح على مدار الساعة مع تحديثات جديدة للخدمة.',
              date: 'قبل أسبوع',
            ),
            _NotificationCard(
              title: 'تنبيه صيانة مجدولة',
              body: 'قد يحدث انقطاع قصير بسبب أعمال صيانة دورية.',
              date: 'قبل أسبوعين',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: const Color(0xFF1E5B1E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String date;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF2E2E2E),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4A4A4A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
