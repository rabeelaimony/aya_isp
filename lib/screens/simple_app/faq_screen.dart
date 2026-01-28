import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'الكل';

  final List<Map<String, String>> _faqs = const [
    {
      'q': 'كيف أفعّل خدمة الإنترنت لأول مرة؟',
      'a': 'تواصل مع خدمة العملاء لتثبيت الخدمة وتفعيلها.',
      'c': 'الخدمة'
    },
    {
      'q': 'كيف أغيّر الباقة؟',
      'a': 'يمكنك تقديم طلب تغيير الباقة من خلال الدعم الفني.',
      'c': 'الباقات'
    },
    {
      'q': 'لماذا السرعة منخفضة؟',
      'a': 'قد يكون بسبب الضغط أو عدد الأجهزة. حاول إعادة تشغيل الراوتر.',
      'c': 'السرعة'
    },
    {
      'q': 'كيف أعرف استهلاكي الشهري؟',
      'a': 'يمكنك متابعة الاستهلاك من لوحة المشترك أو عبر الدعم.',
      'c': 'الاستهلاك'
    },
    {
      'q': 'هل يوجد دعم فني على مدار الساعة؟',
      'a': 'نعم، الدعم الفني متاح على مدار الساعة.',
      'c': 'الدعم'
    },
    {
      'q': 'هل يمكن نقل الخدمة إلى عنوان جديد؟',
      'a': 'نعم، يمكن طلب نقل الخدمة بعد التحقق من التغطية.',
      'c': 'الخدمة'
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _filteredFaqs() {
    return _faqs.where((faq) {
      final matchesCategory =
          _category == 'الكل' || faq['c'] == _category;
      final text = (faq['q'] ?? '') + (faq['a'] ?? '');
      final matchesQuery = _query.isEmpty ||
          text.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faqs = _filteredFaqs();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E2E2E),
        elevation: 0.5,
        title: const Text('مركز المساعدة'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن سؤال...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                'الكل',
                'الخدمة',
                'الباقات',
                'السرعة',
                'الاستهلاك',
                'الدعم'
              ].map((cat) {
                final selected = _category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: const Color(0xFF2E7D32),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'الأسئلة الشائعة',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1E5B1E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (faqs.isEmpty)
              const Text('لا توجد نتائج مطابقة لبحثك.')
            else
              ...faqs.map(
                (faq) => _FaqItem(
                  question: faq['q'] ?? '',
                  answer: faq['a'] ?? '',
                ),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB7D4A3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_outlined,
                      color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'إذا لم تجد إجابة، يمكنك إنشاء طلب دعم من صفحة الدعم الفني.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(widget.question),
        trailing: Icon(_open ? Icons.expand_less : Icons.expand_more),
        onExpansionChanged: (value) => setState(() => _open = value),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(widget.answer),
          ),
        ],
      ),
    );
  }
}
