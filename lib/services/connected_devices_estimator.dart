import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

class ConnectedDevicesEstimate {
  final List<String> ips;
  final String source;
  final Map<String, String> hostnames;

  const ConnectedDevicesEstimate({
    required this.ips,
    required this.source,
    this.hostnames = const {},
  });

  int get count => ips.length;
}

class ConnectedDevicesEstimator {
  final NetworkInfo _networkInfo;

  ConnectedDevicesEstimator({NetworkInfo? networkInfo})
    : _networkInfo = networkInfo ?? NetworkInfo();

  Future<ConnectedDevicesEstimate> estimate({
    Duration connectTimeout = const Duration(milliseconds: 250),
    int concurrency = 50,
  }) async {
    final wifiIp = await _networkInfo.getWifiIP();
    final gatewayIp = await _networkInfo.getWifiGatewayIP();
    if (wifiIp == null || wifiIp.trim().isEmpty) {
      return const ConnectedDevicesEstimate(ips: [], source: 'no_wifi_ip');
    }

    // Delegate to the IP-based estimator which is isolate-friendly.
    return estimateForIp(
      wifiIp.trim(),
      gatewayIp?.trim(),
      connectTimeout: connectTimeout,
      concurrency: concurrency,
    );
  }

  /// Estimate using the provided wifi IP and optional gateway IP.
  /// This method is safe to call from background isolates because it
  /// does not access Flutter platform channels.
  Future<ConnectedDevicesEstimate> estimateForIp(
    String wifiIp,
    String? gatewayIp, {
    Duration connectTimeout = const Duration(milliseconds: 250),
    int concurrency = 50,
  }) async {
    // Fast path on Android: prefer ARP (أدق) قبل TCP لتجنب عناوين خاطئة.
    if (Platform.isAndroid) {
      final arpPreferred = await _tryArpFirst(
        wifiIp.trim(),
        gatewayIp?.trim(),
        concurrency,
      );
      if (arpPreferred != null) {
        final hostnames = await _resolveHostnames(arpPreferred.ips);
        return ConnectedDevicesEstimate(
          ips: arpPreferred.ips,
          source: arpPreferred.source,
          hostnames: hostnames,
        );
      }
    }

    // Fallback: quick TCP scan of /24 subnet (approximate).
    final base = _to24SubnetBase(wifiIp.trim());
    if (base == null) {
      return const ConnectedDevicesEstimate(ips: [], source: 'bad_ip');
    }

    final scanner = _TcpLanScanner(
      timeout: connectTimeout,
      concurrency: concurrency,
    );
    final alive = await scanner.scan24(
      base,
      excludeIps: {wifiIp.trim(), gatewayIp},
    );
    final hostnames = await _resolveHostnames(alive);
    return ConnectedDevicesEstimate(
      ips: alive,
      source: 'tcp_scan',
      hostnames: hostnames,
    );
  }

  /// Top-level worker used with `compute` to run the scan in an isolate.
  /// Call `compute(estimateForIpCompute, {...})` from UI.
  static Future<Map<String, dynamic>> estimateForIpCompute(
    Map<String, dynamic> args,
  ) async {
    final wifiIp = (args['wifiIp'] as String?) ?? '';
    final gatewayIp = args['gatewayIp'] as String?;
    final connectTimeoutMs = (args['connectTimeoutMs'] as int?) ?? 250;
    final concurrency = (args['concurrency'] as int?) ?? 50;

    if (wifiIp.trim().isEmpty) {
      return {
        'ips': <String>[],
        'source': 'no_wifi_ip',
        'hostnames': <String, String>{},
      };
    }

    final estimator = ConnectedDevicesEstimator();
    final result = await estimator.estimateForIp(
      wifiIp.trim(),
      gatewayIp?.trim(),
      connectTimeout: Duration(milliseconds: connectTimeoutMs),
      concurrency: concurrency,
    );

    return {
      'ips': result.ips,
      'source': result.source,
      'hostnames': result.hostnames,
    };
  }

  static String? _to24SubnetBase(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  Future<ConnectedDevicesEstimate?> _tryArpFirst(
    String wifiIp,
    String? gatewayIp,
    int concurrency,
  ) async {
    final base = _to24SubnetBase(wifiIp);
    String normalize(String ip) => ip.trim();
    final excludes = <String>{
      normalize(wifiIp),
      if (gatewayIp != null) normalize(gatewayIp),
      if (base != null) '$base.255',
      if (base != null) '$base.0',
    };

    ConnectedDevicesEstimate? build(List<String> arpIps, String source) {
      final unique = <String>{
        for (final ip in arpIps)
          if (ip.trim().isNotEmpty && !excludes.contains(ip.trim())) ip.trim(),
      };
      if (unique.isEmpty) return null;
      final list = unique.toList()..sort();
      return ConnectedDevicesEstimate(ips: list, source: source);
    }

    // 1) read ARP directly
    final arpImmediate = await _readArpTableIps();
    final immediate = build(arpImmediate, 'arp');
    if (immediate != null) return immediate;

    // 2) force ARP population by ping sweep then read again
    if (base != null) {
      await _pingSweep(base, excludeIp: wifiIp, concurrency: concurrency);
      final arpAfterPing = await _readArpTableIps();
      final after = build(arpAfterPing, 'arp_after_ping');
      if (after != null) return after;
    }
    return null;
  }

  Future<List<String>> _readArpTableIps() async {
    try {
      final file = File('/proc/net/arp');
      if (!await file.exists()) return const [];
      final lines = await file.readAsLines();
      if (lines.isEmpty) return const [];

      final ips = <String>[];
      for (final line in lines.skip(1)) {
        final normalized = line.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (normalized.isEmpty) continue;
        final columns = normalized.split(' ');
        if (columns.length < 4) continue;

        final ip = columns[0];
        final flags = columns[2];
        final mac = columns[3];

        // 0x2 indicates a complete ARP entry.
        final isComplete = flags.toLowerCase() == '0x2';
        final hasMac = mac != '00:00:00:00:00:00' && mac.contains(':');
        if (isComplete && hasMac) {
          ips.add(ip);
        }
      }
      return ips;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _pingSweep(
    String base, {
    String? excludeIp,
    required int concurrency,
  }) async {
    final hosts = List<String>.generate(254, (i) => '$base.${i + 1}');
    final sem = _Semaphore(concurrency);
    final futures = <Future<void>>[];

    for (final ip in hosts) {
      if (excludeIp != null && ip == excludeIp) continue;
      futures.add(() async {
        await sem.acquire();
        try {
          await _pingOnce(ip);
        } finally {
          sem.release();
        }
      }());
    }

    await Future.wait(futures);
  }

  Future<void> _pingOnce(String ip) async {
    try {
      // -c 1 : one packet, -W 1 : 1s timeout (busybox-compatible).
      await Process.run('ping', [
        '-c',
        '1',
        '-W',
        '1',
        ip,
      ]).timeout(const Duration(seconds: 2));
    } catch (_) {
      // ignore failures; goal is just to populate ARP.
    }
  }

  Future<Map<String, String>> _resolveHostnames(
    List<String> ips, {
    int maxLookups = 25,
    Duration perLookupTimeout = const Duration(seconds: 2),
  }) async {
    final Map<String, String> result = {};
    for (final ip in ips.take(maxLookups)) {
      try {
        final addr = InternetAddress.tryParse(ip);
        if (addr == null) continue;
        final reversed = await addr.reverse().timeout(perLookupTimeout);
        if (reversed.host.isNotEmpty && reversed.host != ip) {
          result[ip] = reversed.host;
        }
      } catch (_) {
        // ignore lookup failures
      }
    }
    return result;
  }
}

class _TcpLanScanner {
  // Broader port set to increase hit-rate on idle devices.
  static const List<int> _ports = [
    80,
    443,
    22,
    23,
    53,
    8080,
    8000,
    1900,
    554,
    135, // Windows RPC
    139, // NetBIOS
    445, // SMB
    3389, // RDP
    5357, // Windows HTTP service
  ];

  final Duration timeout;
  final int concurrency;

  _TcpLanScanner({required this.timeout, required this.concurrency});

  Future<List<String>> scan24(
    String base, {
    Set<String?> excludeIps = const {},
  }) async {
    final hosts = List<String>.generate(254, (i) => '$base.${i + 1}');
    final results = <String>[];
    final sem = _Semaphore(concurrency);

    final normalizedExcludes = excludeIps
        .map((e) => e?.trim())
        .whereType<String>()
        .toSet();

    final futures = <Future<void>>[];
    for (final ip in hosts) {
      if (normalizedExcludes.contains(ip)) continue;
      futures.add(() async {
        await sem.acquire();
        try {
          final up = await _isHostUp(ip);
          if (up) results.add(ip);
        } finally {
          sem.release();
        }
      }());
    }

    await Future.wait(futures);
    results.sort();
    return results;
  }

  Future<bool> _isHostUp(String ip) async {
    for (final port in _ports) {
      Socket? socket;
      try {
        socket = await Socket.connect(ip, port, timeout: timeout);
        return true;
      } catch (e) {
        if (e is SocketException && _isConnectionRefused(e)) {
          // Connection refused means host is reachable but port closed.
          return true;
        }
      } finally {
        socket?.destroy();
      }
    }
    return false;
  }

  bool _isConnectionRefused(SocketException e) {
    final code = e.osError?.errorCode;
    if (code == 111 || code == 10061) {
      return true;
    }
    final msg = e.message.toLowerCase();
    return msg.contains('refused');
  }
}

class _Semaphore {
  final int _max;
  int _current = 0;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  _Semaphore(this._max);

  Future<void> acquire() {
    if (_current < _max) {
      _current++;
      return Future.value();
    }
    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeFirst().complete();
      return;
    }
    _current--;
  }
}
