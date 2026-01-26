import 'package:flutter/material.dart';
import 'package:aya_isp/screens/simple_app/account_prices_screen.dart';
import 'package:aya_isp/screens/simple_app/hosting_service_screen.dart';
import 'package:aya_isp/screens/simple_app/aya_wifi_screen.dart';
import 'package:aya_isp/screens/simple_app/offers_notifications_screen.dart';

class SimpleAppHomeScreen extends StatelessWidget {
  const SimpleAppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: size.width < 380 ? 16 : 20,
      vertical: 18,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _TopHero(
              padding: contentPadding,
              onNotificationsTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OffersNotificationsScreen(),
                  ),
                );
              },
            ),
            Padding(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF7AC142).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'خدمات الاستضافة • خدمات ADSL • منافذ إنترنت',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1F4F1F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'خدماتنا ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1E5B1E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickLinkCard(
                        icon: Icons.wifi_outlined,
                        title: 'AYA WiFi',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AyaWifiScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickLinkCard(
                        icon: Icons.cloud_outlined,
                        title: 'خدمات الاستضافة',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HostingServiceScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickLinkCard(
                        icon: Icons.analytics_outlined,
                        title: 'أسعار الباقات',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AccountPricesScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickLinkCard(
                        icon: Icons.notifications_outlined,
                        title: 'الإشعارات العامة',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OffersNotificationsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _TopHero extends StatelessWidget {
  final EdgeInsets padding;
  final VoidCallback onNotificationsTap;

  const _TopHero({required this.padding, required this.onNotificationsTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.only(
        left: padding.horizontal / 2,
        right: padding.horizontal / 2,
        top: size.width < 380 ? 24 : 32,
        bottom: 22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF8BC34A),
            const Color(0xFFE7F5D7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'أول مزود إنترنت خاص في سوريا',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '20 سنة وأكثر..',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onNotificationsTap,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('الإشعارات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5B1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'خدمات Aya ISP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF1E5B1E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر الباقة الأنسب لك واستمتع بسرعة ثابتة وخدمة عملاء على مدار الساعة.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2E7D32),
                    height: 1.4,
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

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _QuickLinkCard({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width < 520 ? (width - 52) / 2 : 160.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF1E5B1E),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      color: const Color(0xFF3B3B3B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظرتنا:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يتطلع فريق مزود خدمة الإنترنت إلى أن يتخطى دور المعلومات في المجتمع السوري وبسرعة، ويساهم الوصول إلى مصادر المعلومات المتاحة، وخدمات الدول العالمية المستخدمة إلى تحقيق الاقتصاد والارتقاء بمستوى الخدمات.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اتصل بنا',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ContactRow(
                    icon: Icons.location_on_outlined,
                    text: 'سوق ساروجة - بناء عابدين',
                  ),
                  const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    text: ' 963119806 +  ',
                  ),
                  const SizedBox(height: 8),
                  _ContactRow(icon: Icons.email_outlined, text: 'info@aya.sy'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
