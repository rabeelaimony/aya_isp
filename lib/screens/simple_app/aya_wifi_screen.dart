import 'package:flutter/material.dart';

class AyaWifiScreen extends StatelessWidget {
  const AyaWifiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = EdgeInsets.symmetric(
      horizontal: size.width < 380 ? 16 : 20,
      vertical: 16,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E2E2E),
        elevation: 0.5,
        title: const Text('AYA WiFi'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: padding,
          children: [
            _HeaderCard(padding: padding),
            const SizedBox(height: 10),
            const _DisclaimerNotice(),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: const [
                _WifiPlanCard(
                  title: 'باقات الإنترنت اللاسلكي حسب السرعة',
                  columns: ['السرعة', 'الباقة', 'السعر'],
                  rows: [
                    ['3M', '75G', 'ل.س 700'],
                    ['5M', '120G', 'ل.س 1200'],
                    ['8M', '200G', 'ل.س 1850'],
                    ['10M', '250G', 'ل.س 2200'],
                  ],
                ),
                _WifiPlanCard(
                  title: 'باقات إضافية',
                  columns: ['الباقة', 'السعر'],
                  rows: [
                    ['10G', 'ل.س 80'],
                    ['25G', 'ل.س 180'],
                    ['50G', 'ل.س 300'],
                    ['100G', 'ل.س 550'],
                    ['200G', 'ل.س 1000'],
                  ],
                ),
                _WifiPlanCard(
                  title: 'باقات غير محدودة',
                  columns: ['السرعة', 'السعر'],
                  rows: [
                    ['1M', 'ل.س 600'],
                    ['2M', 'ل.س 1000'],
                    ['3M', 'ل.س 1300'],
                    ['5M', 'ل.س 2000'],
                    ['8M', 'ل.س 2700'],
                    ['10M', 'ل.س 3150'],
                    ['15M', 'ل.س 3950'],
                  ],
                ),
                _WifiPlanCard(
                  title: 'سرعة غير محدودة - باقة من اختيارك',
                  columns: ['الباقة', 'السعر'],
                  rows: [
                    ['50G', 'ل.س 500'],
                    ['100G', 'ل.س 950'],
                    ['200G', 'ل.س 1850'],
                    ['300G', 'ل.س 2650'],
                    ['500G', 'ل.س 4000'],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerNotice extends StatelessWidget {
  const _DisclaimerNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7D4A3)),
      ),
      child: Text(
        'الأسعار والمعلومات المعروضة هي لأغراض تعريفية فقط.\n'
        'للتفعيل أو الاشتراك يرجى التواصل مع خدمة العملاء.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final EdgeInsets padding;

  const _HeaderCard({required this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'AYA Wi-Fi',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'خدمة الإنترنت اللاسلكي',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WifiPlanCard extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;

  const _WifiPlanCard({
    required this.title,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width < 640 ? width : (width - 64) / 2;
    final effectiveWidth = cardWidth.clamp(260.0, 360.0).toDouble();
    return Container(
      width: effectiveWidth,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBDE5B2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF1E5B1E),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.symmetric(
              inside: const BorderSide(color: Color(0xFFDCF1DA)),
            ),
            columnWidths: {
              for (var i = 0; i < columns.length; i++)
                i: const FlexColumnWidth(),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF188B3A)),
                children: columns
                    .map(
                      (label) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: Align(
                          alignment: label == 'السعر'
                              ? Alignment.centerLeft
                              : Alignment.center,
                          child: Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ...rows.map(
                (row) => TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF2FBF1)),
                  children: row.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cell = entry.value;
                    final isPrice = columns[index] == 'السعر';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 6,
                      ),
                      child: Align(
                        alignment:
                            isPrice ? Alignment.centerLeft : Alignment.center,
                        child: Text(
                          cell,
                          textDirection:
                              isPrice ? TextDirection.ltr : TextDirection.rtl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF1E5B1E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
