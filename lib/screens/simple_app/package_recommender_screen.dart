import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PackageRecommenderScreen extends StatefulWidget {
  const PackageRecommenderScreen({super.key});

  @override
  State<PackageRecommenderScreen> createState() =>
      _PackageRecommenderScreenState();
}

class _PackageRecommenderScreenState extends State<PackageRecommenderScreen> {
  static const _storageKey = 'simple_app_package_recommendations';

  double _monthlyUsage = 120;
  int _devices = 3;
  String _usageType = 'استخدام منزلي';
  String? _recommendedPlan;
  String? _explanation;

  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _calculate();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _history = decoded.cast<Map<String, dynamic>>();
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveResult() async {
    if (_recommendedPlan == null || _explanation == null) return;
    final entry = {
      'date': DateTime.now().toIso8601String(),
      'usage': _monthlyUsage.round(),
      'devices': _devices,
      'usageType': _usageType,
      'plan': _recommendedPlan,
      'note': _explanation,
    };
    _history.insert(0, entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_history));
    if (!mounted) return;
    setState(() {});
  }

  void _calculate() {
    String plan;
    String note;

    if (_monthlyUsage <= 80) {
      plan = 'باقة 75GB بسرعة 3M';
      note = 'مناسبة للتصفح اليومي ومشاهدة الفيديو بدقة عادية.';
    } else if (_monthlyUsage <= 150) {
      plan = 'باقة 120GB بسرعة 5M';
      note = 'مناسبة للأسر الصغيرة وتصفح متعدد.';
    } else if (_monthlyUsage <= 220) {
      plan = 'باقة 200GB بسرعة 8M';
      note = 'خيار جيد للبث المتواصل والألعاب الخفيفة.';
    } else {
      plan = 'باقة 250GB بسرعة 10M';
      note = 'مناسبة للاستخدام المكثف وعدد أجهزة أكبر.';
    }

    if (_devices >= 5) {
      note += ' عدد الأجهزة كبير، يفضّل سرعة أعلى.';
    }
    if (_usageType == 'عمل عن بعد') {
      note += ' العمل عن بعد يحتاج ثبات أعلى.';
    } else if (_usageType == 'ألعاب وبث مباشر') {
      note += ' الألعاب والبث تحتاج سرعة أكبر واستقرار.';
    }

    setState(() {
      _recommendedPlan = plan;
      _explanation = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E2E2E),
        elevation: 0.5,
        title: const Text('حاسبة الباقة المناسبة'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          children: [
            _SectionCard(
              title: 'بيانات الاستخدام',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'حجم الاستخدام الشهري (GB)',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _monthlyUsage,
                    min: 40,
                    max: 350,
                    divisions: 62,
                    label: '${_monthlyUsage.round()} GB',
                    onChanged: (value) {
                      setState(() => _monthlyUsage = value);
                      _calculate();
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'عدد الأجهزة المتصلة',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  DropdownButtonFormField<int>(
                    value: _devices,
                    items: [1, 2, 3, 4, 5, 6, 7]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value أجهزة'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _devices = value);
                      _calculate();
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'نوع الاستخدام',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  DropdownButtonFormField<String>(
                    value: _usageType,
                    items: const [
                      'استخدام منزلي',
                      'تعليم وبحث',
                      'عمل عن بعد',
                      'ألعاب وبث مباشر',
                    ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _usageType = value);
                      _calculate();
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'التوصية',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _recommendedPlan ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1E5B1E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _explanation ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _saveResult,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('احفظ النتيجة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'النتائج المحفوظة',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1E5B1E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_history.isEmpty)
              const Text('لا توجد نتائج محفوظة بعد.')
            else
              ..._history.map((item) {
                return _HistoryCard(item: item);
              }),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF1E5B1E),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(item['date']?.toString() ?? '');
    final formatted = date != null
        ? '${date.year}/${date.month}/${date.day}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item['plan']?.toString() ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['note']?.toString() ?? '',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            'الاستخدام: ${item['usage']} GB • الأجهزة: ${item['devices']} • $formatted',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
