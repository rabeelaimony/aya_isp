import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cubits/session_detail_cubit.dart';
import '../../models/session_detail_model.dart';

class SessionDetailsScreen extends StatefulWidget {
  final String username;
  const SessionDetailsScreen({super.key, required this.username});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  late DateTime _selectedMonth;
  List<DateTime> _availableMonths = const [];
  int _currentPage = 1;
  final int _perPage = 10;
  int _lastPage = 1;
  bool _isFetching = false;
  bool _isMonthChanging = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _availableMonths = List.generate(
      4,
      (i) => DateTime(now.year, now.month - i, 1),
    );
    _selectedMonth = _availableMonths.first;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadData(preferLastPage: true),
    );
  }

  Future<void> _loadData({int? page, bool preferLastPage = false}) async {
    if (_isFetching) return;
    if (preferLastPage) {
      if (mounted) setState(() => _isMonthChanging = true);
    }
    _isFetching = true;
    await Future.delayed(const Duration(milliseconds: 180));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final targetPage = (page ?? _currentPage).clamp(
      1,
      _lastPage > 0 ? _lastPage : 1,
    );
    _currentPage = targetPage;
    final now = DateTime.now();
    _availableMonths = List.generate(
      4,
      (i) => DateTime(now.year, now.month - i, 1),
    );

    if (!_availableMonths.contains(_selectedMonth)) {
      _selectedMonth = _availableMonths.first;
    }

    if (preferLastPage) {
      await context.read<SessionDetailCubit>().fetchSessions(
        username: widget.username,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
        page: _currentPage,
        perPage: _perPage,
        token: token,
      );

      final state = context.read<SessionDetailCubit>().state;
      if (state is SessionDetailLoaded) {
        final last = state.response.lastPage ?? _lastPage;
        if (last > 1 && _currentPage != last) {
          _currentPage = last;
          await context.read<SessionDetailCubit>().fetchSessions(
            username: widget.username,
            year: _selectedMonth.year,
            month: _selectedMonth.month,
            page: _currentPage,
            perPage: _perPage,
            token: token,
          );
        }
      }
    } else {
      await context.read<SessionDetailCubit>().fetchSessions(
        username: widget.username,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
        page: _currentPage,
        perPage: _perPage,
        token: token,
      );
    }

    _isFetching = false;
    if (preferLastPage) {
      if (mounted) setState(() => _isMonthChanging = false);
    }
  }

  String _monthLabel(DateTime date) {
    const months = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
    ];
    final name = months[date.month - 1];
    return '$name ${date.year}';
  }

  Map<String, String> _formatDateParts(DateTime? value) {
    if (value == null) {
      return {'time': '-', 'date': '-'};
    }
    final local = value.toLocal();
    return {
      'time': DateFormat('HH:mm:ss').format(local),
      'date': DateFormat('yyyy-MM-dd').format(local),
    };
  }

  String _formatDurationReadable(int? seconds) {
    if (seconds == null) return '-';
    final duration = Duration(seconds: seconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days يوم');
    if (hours > 0) parts.add('$hours ساعة');
    if (minutes > 0) parts.add('$minutes دقيقة');
    final hasLargerUnits = parts.isNotEmpty;
    if (!hasLargerUnits && secs >= 0) {
      parts.add('$secs ثانية');
    }
    return parts.isEmpty ? '0 ثانية' : parts.join(' ');
  }

  String _formatTrafficCompact(int? bytes) {
    if (bytes == null) return '-';
    final double d = bytes.toDouble();
    if (d >= 1024 * 1024 * 1024) {
      return 'GB ${(d / (1024 * 1024 * 1024)).toStringAsFixed(1)}';
    }
    if (d >= 1024 * 1024) {
      return 'MB ${(d / (1024 * 1024)).toStringAsFixed(1)}';
    }
    if (d >= 1024) {
      return 'KB ${(d / 1024).toStringAsFixed(1)}';
    }
    return '${d.toStringAsFixed(0)} B';
  }

  Color _trafficColor(int? bytes) {
    if (bytes == null) return Colors.black54;
    final double d = bytes.toDouble();
    if (d >= 1024 * 1024 * 1024) {
      return Colors.grey.shade700; // GB
    }
    if (d >= 1024 * 1024) {
      return const ui.Color.fromARGB(255, 13, 179, 24); // MB
    }
    return Colors.red.shade700; // KB / bytes
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final error = colorScheme.error;
    final surface = colorScheme.surface;
    final outline = colorScheme.outline;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الجلسة')),
        backgroundColor: surface,
        body: RefreshIndicator(
          onRefresh: () => _loadData(preferLastPage: true),
          child: BlocBuilder<SessionDetailCubit, SessionDetailState>(
            builder: (context, state) {
              if (state is SessionDetailLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is SessionDetailError) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: outline.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: error, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.right,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (state is SessionDetailLoaded) {
                if (_isMonthChanging) {
                  return const Center(child: CircularProgressIndicator());
                }
                final total =
                    state.response.total ?? state.response.sessions.length;
                final perPage = state.response.perPage ?? _perPage;
                final totalPages =
                    (state.response.lastPage ?? (total / perPage).ceil()).clamp(
                      1,
                      1000000,
                    );
                final stateCurrentPage =
                    (state.response.currentPage ?? _currentPage).clamp(
                      1,
                      totalPages,
                    );
                _currentPage = stateCurrentPage;
                _lastPage = totalPages;

                final items = List<SessionEntry>.from(state.response.sessions)
                  ..sort((a, b) {
                    final aTime =
                        a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final bTime =
                        b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return bTime.compareTo(aTime);
                  });

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [_buildFilter(colorScheme)]),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: items.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: outline.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.hourglass_empty,
                                        color: Colors.grey,
                                        size: 32,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'لا توجد جلسات لعرضها في هذا الشهر.',

                                        textAlign: TextAlign.right,
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final s = items[index];
                                return _sessionCard(
                                  s: s,
                                  primary: primary,
                                  error: error,
                                  surface: surface,
                                  outline: outline,
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
                              onPressed: _currentPage > 1
                                  ? () => _loadData(page: _currentPage - 1)
                                  : null,
                              icon: Container(
                                decoration: BoxDecoration(
                                  color: _currentPage > 1
                                      ? Colors.grey.shade200
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.chevron_left,
                                  color: _currentPage > 1
                                      ? Colors.black87
                                      : Colors.grey,
                                  size: 26,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 44),

                          Text(
                            'صفحة $_currentPage من $totalPages',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          if (totalPages > 1)
                            IconButton(
                              tooltip: 'التالي',
                              onPressed: _currentPage < totalPages
                                  ? () => _loadData(page: _currentPage + 1)
                                  : null,
                              icon: Container(
                                decoration: BoxDecoration(
                                  color: _currentPage < totalPages
                                      ? Colors.grey.shade200
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.chevron_right,
                                  color: _currentPage < totalPages
                                      ? Colors.black87
                                      : Colors.grey,
                                  size: 26,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 44),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilter(ColorScheme colorScheme) {
    final accent = colorScheme.primary;
    final surface = colorScheme.surface;
    final outline = colorScheme.outline;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: ui.TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'فلترة الجلسات',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: ui.TextDirection.rtl,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'اختر الشهر لعرض الجلسات',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: ui.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<DateTime>(
                    isExpanded: true,
                    value: _selectedMonth,
                    dropdownColor: colorScheme.surface,
                    items: _availableMonths
                        .map(
                          (date) => DropdownMenuItem<DateTime>(
                            value: date,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _monthLabel(date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                          _currentPage = 1;
                          _lastPage = 1;
                        });
                        _loadData(preferLastPage: true);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sessionCard({
    required SessionEntry s,
    required Color primary,
    required Color error,
    required Color surface,
    required Color outline,
  }) {
    final startParts = _formatDateParts(s.startTime);
    final stopParts = _formatDateParts(s.stopTime);
    final traffic = _formatTrafficCompact(s.trafficBytes);
    final trafficColor = _trafficColor(s.trafficBytes);
    final scheme = Theme.of(context).colorScheme;

    TextStyle lineStyle({Color? color, FontWeight? weight, double? size}) {
      return Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: color ?? scheme.onSurface,
        fontWeight: weight,
        fontSize: size,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: ui.TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وقت البدء',
                  style: lineStyle(color: Colors.grey.shade600, size: 11),
                ),
                Text(
                  '${startParts['time'] ?? '-'} ${startParts['date'] ?? '-'}',
                  style: lineStyle(
                    color: primary,
                    weight: FontWeight.w700,
                    size: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'وقت الانتهاء',
                  style: lineStyle(color: Colors.grey.shade600, size: 11),
                ),
                Text(
                  '${stopParts['time'] ?? '-'} ${stopParts['date'] ?? '-'}',
                  style: lineStyle(
                    color: error,
                    weight: FontWeight.w700,
                    size: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _pill(
                  text: _formatDurationReadable(s.sessionSeconds),
                  textColor: primary,
                ),
                const SizedBox(height: 8),
                _pill(
                  text: traffic,
                  textColor: trafficColor,
                  icon: Icons.download_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String text,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
