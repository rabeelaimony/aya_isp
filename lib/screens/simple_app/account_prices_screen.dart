import 'package:flutter/material.dart';

class AccountPricesScreen extends StatelessWidget {
  const AccountPricesScreen({super.key});

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
          centerTitle: false,
          title: const Text('أسعار الباقات'),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Color(0xFF4A4A4A),
            indicatorColor: Color(0xFF2E7D32),
            tabs: [
              Tab(text: 'خدمة شهرية'),
              Tab(text: 'حساب VIP'),
              Tab(text: 'حساب قياسي'),
              Tab(text: 'سعات إضافية'),
            ],
          ),
        ),
        body: const Directionality(
          textDirection: TextDirection.rtl,
          child: TabBarView(
            children: [
              _MonthlyAccountTab(),
              _VipAccountTab(),
              _StandardAccountTab(),
              _ExtraRechargeTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyAccountTab extends StatelessWidget {
  const _MonthlyAccountTab();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'يتيح لك اشتراك شهري حسب السرعة وحجم الاستهلاك المخصص:',
      table: _PriceTable(
        headers: const ['السرعة', 'السعر الجديد', 'حجم الاستهلاك (غيغا)'],
        rows: const [
          ['512 Kbps (للمشتركين القدماء)', '140 ل.س', '35 غيغا بايت'],
          ['1 Mbps', '185 ل.س', '55 غيغا بايت'],
          ['2 Mbps', '240 ل.س', '90 غيغا بايت'],
          ['4 Mbps', '380 ل.س', '150 غيغا بايت'],
          ['8 Mbps', '640 ل.س', '185 غيغا بايت'],
          ['16 Mbps', '830 ل.س', '235 غيغا بايت'],
        ],
      ),
    );
  }
}

class _VipAccountTab extends StatelessWidget {
  const _VipAccountTab();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'تمنحك السرعة العالية والمستقرة ضمن ساعات الذروة بتشاركية أقل...',
      steps: const [
        '1- تقديم طلب للحصول على خط الـ VIP من بوابة لذكي المشترك، علماً أن تكلفة التحويل مجاناً.',
        '2- يتم دراسة الطلب، وقدرة الخط على تحمل هذه الخدمة ثم يتم التواصل مع المشترك بقبول أو رفض الطلب.',
      ],
      table: _PriceTable(
        headers: const ['السرعات المتاحة', 'حجم تبادل البيانات', 'السعر'],
        rows: const [
          ['2 Mbps', '90 GB', '350 S.P'],
          ['4 Mbps', '150 GB', '550 S.P'],
          ['8 Mbps', '185 GB', '850 S.P'],
        ],
      ),
    );
  }
}

class _StandardAccountTab extends StatelessWidget {
  const _StandardAccountTab();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'للإشتراك بهذه الشريحة يجب عليك إجراء الخطوات التالية:',
      steps: const [
        '1- السرعة المسموحة في هذه الشريحة فقط (1-2-4) Mbps.',
        '2- إحضار الأوراق المطلوبة (صورة عن هوية أو إخراج قيد حديثة).',
        '3- يحق هذه الشريحة نقل أصول وموجود صاحب الخط (أب أو أخ أو زوجة) مرفقة صورة عن بطاقة الهانة.',
        '4- يُجدد هذا النوع مرة واحدة فقط خلال السنة، وتكلفة تجديده هي 1000 ليرة سورية لدفعة واحدة.',
      ],
      table: _PriceTable(
        headers: const ['السرعة', 'السعر الجديد', 'حجم الاستهلاك (غيغا)'],
        rows: const [
          ['1 Mbps', '155 ل.س', '55 غيغا بايت'],
          ['2 Mbps', '210 ل.س', '90 غيغا بايت'],
          ['4 Mbps', '345 ل.س', '150 غيغا بايت'],
        ],
      ),
    );
  }
}

class _ExtraRechargeTab extends StatelessWidget {
  const _ExtraRechargeTab();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title:
          'يستطيع المشترك زيادة حجم تبادل البيانات الشهري دون زيادة صلاحية الحساب وهذه الزيادة غير قابلة للتدوير وتنقضي في موعد تجديد الباقة.',
      table: _PriceTable(
        headers: const ['الباقة', 'السعر الجديد'],
        rows: const [
          ['5 غيغا بايت', '18 ل.س'],
          ['10 غيغا بايت', '33 ل.س'],
          ['20 غيغا بايت', '57 ل.س'],
          ['30 غيغا بايت', '76 ل.س'],
          ['50 غيغا بايت', '115 ل.س'],
          ['75 غيغا بايت', '135 ل.س'],
          ['100 غيغا بايت', '190 ل.س'],
          ['200 غيغا بايت', '350 ل.س'],
          ['500 غيغا بايت', '835 ل.س'],
          ['1000 غيغا بايت', '1525 ل.س'],
          ['4.88 تيرا بايت', '7470 ل.س'],
        ],
      ),
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  final String title;
  final List<String> steps;
  final Widget table;

  const _SectionWrapper({
    required this.title,
    required this.table,
    this.steps = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFD73B2E),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                step,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        table,
      ],
    );
  }
}

class _PriceTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const _PriceTable({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF333333),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDEDEDE)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Table(
        columnWidths: {
          for (var i = 0; i < headers.length; i++)
            i: const FlexColumnWidth(),
        },
        border: TableBorder.symmetric(
          inside: const BorderSide(color: Color(0xFFBDBDBD)),
          outside: const BorderSide(color: Color(0xFFDEDEDE)),
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEE4035)),
            children: headers
                .map(
                  (text) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Center(
                      child: Text(text, style: headerStyle),
                    ),
                  ),
                )
                .toList(),
          ),
          ...rows.map(
            (row) => TableRow(
              children: row
                  .map(
                    (cell) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Center(child: Text(cell, style: cellStyle)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
