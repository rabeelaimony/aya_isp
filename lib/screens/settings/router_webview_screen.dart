import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aya_isp/core/logger.dart';

class RouterWebViewScreen extends StatefulWidget {
  final List<String> candidateHosts;
  const RouterWebViewScreen({super.key, required this.candidateHosts});

  @override
  State<RouterWebViewScreen> createState() => _RouterWebViewScreenState();
}

class _RouterWebViewScreenState extends State<RouterWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool _triedHttpsFallback = false;
  int _currentIndex = 0;

  List<Uri> get _uris => widget.candidateHosts
      .map(
        (host) => Uri.parse(
          host.startsWith('http') ? host : 'http://$host/',
        ),
      )
      .toList();

  Uri get _currentUri => _uris[_currentIndex];

  Future<void> _loadUri(Uri uri) async {
    _errorMessage = null;
    setState(() {
      _isLoading = true;
    });
    await _controller.loadRequest(uri);
  }

  Future<void> _tryNextHost() async {
    if (_currentIndex < _uris.length - 1) {
      _currentIndex += 1;
      _triedHttpsFallback = false;
      await _loadUri(_currentUri);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage ??= 'لم يتم العثور على صفحة الراوتر عبر العناوين المتاحة.';
      });
    }
  }

  Future<void> _fitToWidth() async {
    try {
      await _controller.runJavaScript("""
        (function(){
          var doc = document.documentElement;
          var body = document.body;
          var contentWidth = Math.max((doc && doc.scrollWidth) || 0, (body && body.scrollWidth) || 0, (doc && doc.offsetWidth) || 0);
          var scale = 1;
          if (contentWidth > window.innerWidth && contentWidth > 0) {
            scale = window.innerWidth / contentWidth;
          }
          try { body.style.zoom = scale; } catch(e){}
          try { doc.style.transformOrigin = '0 0'; doc.style.transform = 'scale(' + scale + ')'; } catch(e){}
          try { doc.style.width = (100 / (scale || 1)) + '%'; } catch(e){}
        })();
      """);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    // Ensure there is at least one candidate host.
    if (widget.candidateHosts.isEmpty) {
      widget.candidateHosts.add('192.168.1.1');
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _fitToWidth();
          },
          onWebResourceError: (err) {
            AppLogger.w(
              'WebView error: ${err.description} (code ${err.errorCode})',
            );

            final desc = err.description.toLowerCase();

            // If cleartext is blocked, try HTTPS once for this host.
            if (!_triedHttpsFallback &&
                desc.contains('cleartext') &&
                _currentUri.scheme == 'http') {
              _triedHttpsFallback = true;
              final httpsUri = _currentUri.replace(scheme: 'https');
              _loadUri(httpsUri);
              return;
            }

            // If connection refused/unreachable, try next host.
            if (desc.contains('connection refused') ||
                desc.contains('name not resolved') ||
                desc.contains('host lookup') ||
                desc.contains('err_address_unreachable')) {
              _tryNextHost();
              return;
            }

            setState(() {
              _isLoading = false;
              _errorMessage = err.description;
            });
          },
        ),
      )
      ..loadRequest(_currentUri);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات الراوتر'),
          actions: [
            IconButton(
              tooltip: 'ملاءمة العرض',
              onPressed: _fitToWidth,
              icon: const Icon(Icons.fit_screen),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_errorMessage == null) ...[
              WebViewWidget(controller: _controller),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'تعذر تحميل صفحة الراوتر',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage ?? '', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final url = _currentUri.toString();
                          try {
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('تنبيه'),
                                content: Text(
                                  'تعذر فتح الرابط في المتصفح الخارجي: ${e.toString()}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('إغلاق'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('فتح في المتصفح'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
