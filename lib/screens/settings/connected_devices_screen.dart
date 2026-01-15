import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:aya_isp/services/connected_devices_estimator.dart';

class ConnectedDevicesScreen extends StatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  static const String _iosLimitationNote = 'ملاحظة: iOS لا يسمح بعرض الأجهزة المتصلة بالشبكة مباشرةً. يمكن عرضها عبر الراوتر.';
  ConnectedDevicesEstimate? _estimate;
  String? _error;
  bool _loading = false;
  String? _myIp;
  String? _ssid;
  bool _requestingPermission = false;
  bool _hasLocationPermission = false;

  String get _ssidLabel {
    final normalized = _normalizeSsid(_ssid);
    return normalized.isNotEmpty ? normalized : '';
  }

  String _normalizeSsid(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll('"', '');
  }

  @override
  void initState() {
    super.initState();
    _loadSsidQuick();
    _refresh();
  }

  Future<void> _loadSsidQuick() async {
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) return;
      final info = NetworkInfo();
      final wifiName = _normalizeSsid(await info.getWifiName());
      if (mounted && wifiName.isNotEmpty) {
        setState(() => _ssid = wifiName);
      }
    } catch (_) {
      // ignore quick SSID fetch failures
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 60));

    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _error = 'صلاحية الموقع مطلوبة لإكمال البحث.';
            _loading = false;
          });
        }
        return;
      }

      final info = NetworkInfo();
      final myIp = await info.getWifiIP();
      final gateway = await info.getWifiGatewayIP();
      final wifiName = _normalizeSsid(await info.getWifiName());

      final result =
          await compute(ConnectedDevicesEstimator.estimateForIpCompute, {
            'wifiIp': myIp ?? '',
            'gatewayIp': gateway,
            'connectTimeoutMs': 250,
            'concurrency': 50,
          });

      final estimate = ConnectedDevicesEstimate(
        ips: List<String>.from(result['ips'] ?? const <String>[]),
        source: result['source'] ?? 'unknown',
        hostnames: Map<String, String>.from(result['hostnames'] ?? const {}),
      );

      if (mounted) {
        setState(() {
          _estimate = estimate;
          _myIp = myIp;
          if (wifiName.isNotEmpty) _ssid = wifiName;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<bool> _ensureLocationPermission() async {
    if (_requestingPermission) return _hasLocationPermission;
    _requestingPermission = true;
    try {
      final status = await Permission.locationWhenInUse.status;
      bool granted = status.isGranted;
      if (!granted) {
        final shouldRequest = await _showLocationDisclosure();
        if (!shouldRequest) {
          if (mounted && _hasLocationPermission != granted) {
            setState(() => _hasLocationPermission = false);
          } else {
            _hasLocationPermission = false;
          }
          return false;
        }
        final result = await Permission.locationWhenInUse.request();
        granted = result.isGranted;
        if (result.isPermanentlyDenied && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('صلاحية الموقع مطلوبة'),
              content: const Text(
                'نحتاج صلاحية الموقع لقراءة معلومات شبكة Wi-Fi وحساب عدد الأجهزة المتصلة. يمكنك تفعيل الصلاحية من الإعدادات.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    openAppSettings();
                  },
                  child: const Text('فتح الإعدادات'),
                ),
              ],
            ),
          );
        }
      }
      if (mounted && _hasLocationPermission != granted) {
        setState(() => _hasLocationPermission = granted);
      } else {
        _hasLocationPermission = granted;
      }
      return granted;
    } finally {
      _requestingPermission = false;
    }
  }

  Future<bool> _showLocationDisclosure() async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'هل تسمح بصلاحية الموقع؟',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        content: const Text(
          'نحتاج صلاحية الموقع لقراءة اسم الشبكة وحساب عدد الأجهزة المتصلة. لن نستخدم موقعك الفعلي.',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('موافقة'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _estimate;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTextStyle(
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الأجهزة المتصلة'),
            actions: [
              IconButton(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
              ),
            ],
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.devices_other_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'إجمالي الأجهزة المتصلة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_error != null && _hasLocationPermission)
                                    ElevatedButton.icon(
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              setState(() => _error = null);
                                              _refresh();
                                            },
                                      icon: const Icon(Icons.search),
                                      label: const Text('بحث'),
                                    )
                                  else if (_error != null)
                                    _ErrorMessage(
                                      message: _error!,
                                      onRetry: _refresh,
                                    )
                                  else if (_loading)
                                    _buildSearchingAnimation()
                                  else
                                    Text(
                                      '${_totalWithMe(estimate)} جهاز',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _WifiBadge(ssid: _ssidLabel),
                                  ),
                                  Text(
                                    'يعرض عدد الأجهزة المتصلة بالشبكة (قد يتغير حسب اتصال الأجهزة).',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قائمة الأجهزة',
                          // textAlign: TextAlign.right,
                          // textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildList(context, estimate)),
                  ],
                ),
              ),
              if (_loading) _ScanningOverlay(ssid: _ssidLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ConnectedDevicesEstimate? estimate) {
    if (_loading && estimate == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 56, width: 56, child: CircularProgressIndicator()),
            SizedBox(height: 12),
            Text('جارٍ البحث عن الأجهزة...'),
          ],
        ),
      );
    }

    if (_error != null && (estimate == null || estimate.ips.isEmpty)) {
      if (_hasLocationPermission) {
        return Center(
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.search),
            label: const Text('بحث'),
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? 'حدث خطأ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _requestingPermission
                      ? null
                      : () async {
                          setState(() => _error = null);
                          await _ensureLocationPermission();
                          if (mounted) await _refresh();
                        },
                  icon: const Icon(Icons.security),
                  label: const Text('طلب الصلاحية'),
                ),
                OutlinedButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('فتح الإعدادات'),
                ),
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final ips = estimate?.ips ?? const <String>[];
    final deviceIp = _myIp?.trim();
    final displayIps = <String>[
      if (deviceIp != null && deviceIp.isNotEmpty) deviceIp,
      ...ips.where((ip) => ip != deviceIp),
    ];
    if (displayIps.isEmpty) {
      if (Platform.isIOS) {
        return const Center(
          child: Text(
            _iosLimitationNote,
            textAlign: TextAlign.center,
          ),
        );
      }
      return const Center(child: Text('لا توجد أجهزة أخرى على الشبكة.'));
    }

    String sourceLabel(String src) {
      switch (src) {
        case 'arp':
          return 'ARP (من جدول الشبكة)';
        case 'arp_after_ping':
          return 'ARP بعد Ping';
        case 'tcp_scan':
          return '';
        default:
          return src;
      }
    }

    return ListView.separated(
      itemCount: displayIps.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ip = displayIps[index];
        final isMe = ip == deviceIp;
        final hostname = _estimate?.hostnames[ip];
        final source = sourceLabel(_estimate?.source ?? '');
        return ListTile(
          // textDirection: TextDirection.rtl,
          leading: const Icon(Icons.phone_android),
          title: Text(isMe ? ' (جهازي)' : ip),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hostname != null && hostname.isNotEmpty) Text(hostname),
              if (source.isNotEmpty) Text(source),
            ],
          ),
        );
      },
    );
  }

  int _totalWithMe(ConnectedDevicesEstimate? estimate) {
    return _totalWithParams(estimate, _myIp);
  }

  int _totalWithParams(ConnectedDevicesEstimate? estimate, String? currentIp) {
    final base = estimate?.count ?? 0;
    final hasMe = (currentIp?.isNotEmpty ?? false) ? 1 : 0;
    final alreadyCounted =
        (currentIp != null && estimate?.ips.contains(currentIp.trim()) == true)
        ? 1
        : 0;
    return base + hasMe - alreadyCounted;
  }

  Widget _buildSearchingAnimation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'جارٍ البحث عن الأجهزة على الشبكة...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'قد تحتاج لمنح إذن الموقع بسبب متطلبات Wi-Fi.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
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

class _WifiBadge extends StatelessWidget {
  final String ssid;
  const _WifiBadge({super.key, required this.ssid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            ssid,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorMessage({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعذر إكمال العملية',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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

class _ScanningOverlay extends StatefulWidget {
  final String ssid;
  const _ScanningOverlay({super.key, this.ssid = ''});

  @override
  State<_ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<_ScanningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: Container(
        color: Colors.black.withOpacity(0.22),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                final pulseOpacity = (1 - progress) * 0.4;
                final pulseScale = 1 + (progress * 0.35);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220 * pulseScale,
                      height: 220 * pulseScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(
                          (pulseOpacity.clamp(0.0, 1.0)) as double,
                        ),
                      ),
                    ),
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.9),
                            theme.colorScheme.primary.withOpacity(0.75),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.wifi,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'جارٍ البحث عن الأجهزة على الشبكة',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.ssid.isNotEmpty
                  ? widget.ssid
                  : 'قد تحتاج لتفعيل إذن الموقع لقراءة اسم الشبكة.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
