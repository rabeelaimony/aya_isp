import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cubits/financial_cubit.dart';

class FinancialStatementScreen extends StatefulWidget {
  const FinancialStatementScreen({super.key});

  @override
  State<FinancialStatementScreen> createState() =>
      _FinancialStatementScreenState();
}

class _FinancialStatementScreenState extends State<FinancialStatementScreen> {
  int _page = 1;
  final int _perPage = 10;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    if (_isFetching) return;
    _isFetching = true;
    // تأخير بسيط لتقليل ضغط الطلبات على الخادم
    await Future.delayed(const Duration(milliseconds: 180));
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final token = prefs.getString('token');
      if (username != null && token != null) {
        await context.read<FinancialCubit>().fetch(
          username: username,
          token: token,
          perPage: _perPage,
          page: _page,
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('البيان المالي'), centerTitle: true),
        body: BlocBuilder<FinancialCubit, FinancialState>(
          builder: (context, state) {
            if (state is FinancialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is FinancialError) {
              return Center(child: Text('خطأ: ${state.message}'));
            }

            if (state is FinancialLoaded) {
              final items = state.items;
              final currentPage = state.page;
              final hasMore = state.hasMore;
              final totalPages =
                  (state.lastPage ?? (hasMore ? currentPage + 1 : currentPage))
                      .clamp(1, 1000000);
              final isRefreshing = state.isRefreshing == true;

              if (items.isEmpty) {
                return const Center(
                  child: Text('لا توجد قيود مالية لهذا الحساب.'),
                );
              }

              return Column(
                children: [
                  if (isRefreshing) const LinearProgressIndicator(minHeight: 3),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // نوع العملية
                                Text(
                                  "نوع العملية: ${item.burnType}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                _buildRow("تاريخ العملية", item.bd),
                                _buildRow("المبلغ المدفوع", item.typecard),
                                _buildRow("المبلغ المقتطع", item.paidMount),
                                // _buildRow("الرصيد السابق", item.lastBalance),
                                _buildRow(
                                  "الترافيك الجديد",
                                  item.newTraffic ?? "-",
                                ),
                                _buildRow("تاريخ الانتهاء القديم", item.bex),
                                _buildRow("تاريخ الانتهاء الجديد", item.nex),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (totalPages > 1)
                          IconButton(
                            tooltip: 'السابق',
                            onPressed: (!isRefreshing && currentPage > 1)
                                ? () {
                                    setState(() => _page = currentPage - 1);
                                    _loadAndFetch();
                                  }
                                : null,
                            icon: Container(
                              decoration: BoxDecoration(
                                color: currentPage > 1
                                    ? Theme.of(context).colorScheme.surface
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.chevron_left,
                                color: currentPage > 1
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                size: 28,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),

                        Text('صفحة $currentPage من $totalPages'),

                        if (totalPages > 1)
                          IconButton(
                            tooltip: 'التالي',
                            onPressed:
                                (!isRefreshing && currentPage < totalPages)
                                ? () {
                                    setState(() => _page = currentPage + 1);
                                    _loadAndFetch();
                                  }
                                : null,
                            icon: Container(
                              decoration: BoxDecoration(
                                color: currentPage < totalPages
                                    ? Theme.of(context).colorScheme.surface
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.chevron_right,
                                color: currentPage < totalPages
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                size: 28,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text('تعذر تحميل البيان المالي.'));
          },
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(value, textAlign: TextAlign.left)),
        ],
      ),
    );
  }
}
