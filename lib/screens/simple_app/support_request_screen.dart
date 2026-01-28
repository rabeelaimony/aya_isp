import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupportRequestScreen extends StatefulWidget {
  const SupportRequestScreen({super.key});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  static const _storageKey = 'simple_app_support_requests';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subscriberController = TextEditingController();
  final _detailsController = TextEditingController();

  String _issueType = 'بطء في السرعة';
  bool _submitting = false;
  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subscriberController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _requests = decoded.cast<Map<String, dynamic>>();
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_requests));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final request = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text.trim(),
      'subscriber': _subscriberController.text.trim(),
      'type': _issueType,
      'details': _detailsController.text.trim(),
      'status': 'جديد',
      'date': DateTime.now().toIso8601String(),
    };

    _requests.insert(0, request);
    await _saveRequests();
    if (!mounted) return;

    _formKey.currentState!.reset();
    _nameController.clear();
    _subscriberController.clear();
    _detailsController.clear();
    setState(() => _submitting = false);
  }

  Future<void> _updateStatus(Map<String, dynamic> request) async {
    final current = request['status']?.toString() ?? 'جديد';
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديث الحالة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['جديد', 'قيد المراجعة', 'مغلق']
              .map(
                (status) => RadioListTile<String>(
                  value: status,
                  groupValue: current,
                  onChanged: (value) => Navigator.of(context).pop(value),
                  title: Text(status),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected == null) return;
    request['status'] = selected;
    await _saveRequests();
    if (!mounted) return;
    setState(() {});
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
        title: const Text('طلب خدمة أو دعم فني'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          children: [
            Text(
              'أرسل طلبك وسنسجلّه محليًا للتجربة.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Container(
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
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'الاسم الكامل'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'هذا الحقل مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subscriberController,
                      decoration:
                          const InputDecoration(labelText: 'رقم المشترك'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'هذا الحقل مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _issueType,
                      decoration:
                          const InputDecoration(labelText: 'نوع المشكلة'),
                      items: const [
                        'بطء في السرعة',
                        'انقطاع الخدمة',
                        'استفسار عن الفواتير',
                        'تغيير الباقة',
                        'أخرى',
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
                        setState(() => _issueType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _detailsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'تفاصيل إضافية',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: const Icon(Icons.send),
                      label: Text(_submitting ? 'جاري الإرسال' : 'إرسال الطلب'),
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
            ),
            const SizedBox(height: 18),
            Text(
              'طلباتك',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1E5B1E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_requests.isEmpty)
              const Text('لا توجد طلبات بعد.')
            else
              ..._requests.map((request) {
                return _RequestCard(
                  request: request,
                  onStatusTap: () => _updateStatus(request),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onStatusTap;

  const _RequestCard({required this.request, required this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(request['date']?.toString() ?? '');
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
            request['type']?.toString() ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request['details']?.toString().isNotEmpty == true
                ? request['details']?.toString() ?? ''
                : 'لا توجد تفاصيل إضافية.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            'رقم المشترك: ${request['subscriber']} • $formatted',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'الحالة: ${request['status']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1E5B1E),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onStatusTap,
                child: const Text('تحديث الحالة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
