import 'package:flutter/material.dart';

class HostingServiceScreen extends StatelessWidget {
  const HostingServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E2E2E),
          elevation: 0.5,
          title: const Text('خدمات الاستضافة'),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Color(0xFF4A4A4A),
            indicatorColor: Color(0xFF2E7D32),
            tabs: [
              Tab(text: 'حجز الدومين'),
              Tab(text: 'أنواع الاستضافة'),
              Tab(text: 'Co-location Servers'),
              Tab(text: 'VPS'),
            ],
          ),
        ),
        body: const Directionality(
          textDirection: TextDirection.rtl,
          child: TabBarView(
            children: [
              _DomainReservationTab(),
              _HostingTypesTab(),
              _ColocationTab(),
              _VpsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DomainReservationTab extends StatelessWidget {
  const _DomainReservationTab();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'خدمات الاستضافة:',
      description:
          'يعمل مزود خدمة الإنترنت على توفير الدومينات بأسعار منافسة ومن خلال أشهر الشركات العالمية (Name & eNom).',
      bullets: const [
        'تأكد من توفر الدومين المطلوب عبر التواصل مع فريق الدعم.',
        'يمكن تسجيل الدومين وربطه بالاستضافة المناسبة لحاجتك.',
        'الدومينات المتاحة تشمل الامتدادات العالمية والمحلية.',
      ],
      note: 'للاستفسار عن تفاصيل الدومين يرجى التواصل معنا.',
    );
  }
}

class _HostingTypesTab extends StatelessWidget {
  const _HostingTypesTab();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'ميزات الاستضافة Linux:',
      bullets: const [
        'لوحة التحكم الخاصة بسيرفر Linux في Directadmin.',
        'دعم PHP multiple version و CGI و Fast CGI.',
        'يدعم MySQL.',
      ],
      extraTitle: 'ميزات الاستضافة Windows:',
      extraBullets: const [
        'لوحة التحكم الخاصة بسيرفر الويندوز في Plesk Control Panel 12.',
        'يدعم Asp .net 4.5 و Asp 3.0.',
        'يدعم PHP multiple version و CGI و Fast CGI.',
        'يدعم MySQL و MSSQL 2008.',
      ],
      footerTitle: 'ميزات الاستضافة Node.js:',
      footerBullets: const [
        'لوحة التحكم الخاصة في Plesk Control Panel.',
        'دعم Node.js 12.',
        'دعم MySQL و MS-SQL.',
        'مساحة تخزين تبدأ من 25GB.',
      ],
      note:
          'تتوفر خيارات Reseller بحسب حجم المساحة والتحكم الكامل بالمواقع والمساحات.',
    );
  }
}

class _ColocationTab extends StatelessWidget {
  const _ColocationTab();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'استضافة Co-location:',
      description: 'عوامل الأمان والميزات المتوفرة كالتالي:',
      bullets: const [
        'إمكانية المراقبة الدائمة server monitoring 24/7 للتأكد من استقرار العمل.',
        'تأمين التغذية الدائمة من الشبكة مع وحدة كهرباء احتياطية.',
        'إمكانية الدخول البعيد للسيرفر عبر SSH و Remote Desktop و Telnet.',
        'فلترة البيانات وتقديم جدران الحماية firewalls حسب الحاجة.',
        'ربط سريع ضمن الشبكات الخاصة مع الحفاظ على الحد الأدنى من الانقطاع.',
        'فريق دعم فني على مدار 24 ساعة.',
        'سرعة الوصلة الدولية للإنترنت 100 Mb/s.',
        'تنفيذ تركيب وصيانة بشكل كامل خلال الأسبوع الأول بعد توقيع العقد.',
        'حماية المعلومات والبيانات من خلال فريق الشركة المختص بالصيانة.',
      ],
      note: 'للتفاصيل الفنية والتجهيزات يرجى التواصل مع فريق الدعم.',
    );
  }
}

class _VpsTab extends StatelessWidget {
  const _VpsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: const [
        _InfoHeader(
          title: 'مخدم افتراضي VPS:',
          description:
              'هو جزء من مخدم حقيقي تم تقسيمه بشكل مستقل مع إدارة ذاتية، ويمتلك كامل موارد المعالج والذاكرة والتخزين لتشغيل المواقع والتطبيقات والخدمات بنجاح.',
        ),
        SizedBox(height: 16),
        _VpsGrid(),
      ],
    );
  }
}

class _VpsGrid extends StatelessWidget {
  const _VpsGrid();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width < 680 ? width : (width - 60) / 2;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        _VpsPlanCard(
          title: 'Plan 1',
          specs: [
            'CPU: 2CPU @2.10 GHz One cores',
            'Ram: 4GB',
            'Hard SAS: 30GB',
            'NIC: 10Mb/s',
            'Bandwidth/month: 200GB',
            'IP: 1',
          ],
        ),
        _VpsPlanCard(
          title: 'Plan 2',
          specs: [
            'CPU: 4 CPU @2.10 GHz Two cores',
            'Ram: 4GB',
            'Hard SAS: 50GB',
            'NIC: 10Mb/s',
            'Bandwidth/month: 300GB',
            'IP: 1',
          ],
        ),
        _VpsPlanCard(
          title: 'Plan 3',
          specs: [
            'CPU: 6CPU @2.10 GHz Three cores',
            'Ram: 8GB',
            'Hard SAS: 120GB',
            'NIC: 10Mb/s',
            'Bandwidth/month: 400GB',
            'IP: 1',
          ],
        ),
        _VpsPlanCard(
          title: 'Plan 4',
          specs: [
            'CPU: 6CPU @2.10 GHz Three cores',
            'Ram: 8GB',
            'Hard SAS: 160GB',
            'NIC: 10Mb/s',
            'Bandwidth/month: 500GB',
            'IP: 1',
          ],
        ),
        _VpsPlanCard(
          title: 'Plan 5',
          specs: [
            'CPU: 8CPU @2.10 GHz Four cores',
            'Ram: 8GB',
            'Hard SAS: 200GB',
            'NIC: 10Mb/s',
            'Bandwidth/month: 600GB',
            'IP: 1',
          ],
        ),
      ].map((card) {
        return SizedBox(width: cardWidth.clamp(280, 360), child: card);
      }).toList(),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  final String title;
  final String description;

  const _InfoHeader({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFFD73B2E),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  final String title;
  final String? description;
  final List<String> bullets;
  final String? extraTitle;
  final List<String> extraBullets;
  final String? footerTitle;
  final List<String> footerBullets;
  final String? note;

  const _SectionWrapper({
    required this.title,
    this.description,
    this.bullets = const [],
    this.extraTitle,
    this.extraBullets = const [],
    this.footerTitle,
    this.footerBullets = const [],
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFFD73B2E),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...bullets.map((bullet) => _BulletRow(text: bullet)),
        ],
        if (extraTitle != null) ...[
          const SizedBox(height: 18),
          Text(
            extraTitle!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFFD73B2E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (extraBullets.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...extraBullets.map((bullet) => _BulletRow(text: bullet)),
        ],
        if (footerTitle != null) ...[
          const SizedBox(height: 18),
          Text(
            footerTitle!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFFD73B2E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (footerBullets.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...footerBullets.map((bullet) => _BulletRow(text: bullet)),
        ],
        if (note != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFB7D4A3)),
            ),
            child: Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;

  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(height: 1.4)),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _VpsPlanCard extends StatelessWidget {
  final String title;
  final List<String> specs;

  const _VpsPlanCard({required this.title, required this.specs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF6FB319),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...specs.map(
            (spec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                spec,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
