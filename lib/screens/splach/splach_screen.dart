import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aya_isp/services/notification_center.dart';
import 'package:aya_isp/services/session_manager.dart';
import 'package:aya_isp/screens/login/login_screen.dart';
import 'package:aya_isp/screens/home/home_screen.dart';
import 'package:aya_isp/cubits/userinfo_cubit.dart';
import 'package:aya_isp/cubits/adsl_traffic_cubit.dart';
import 'package:aya_isp/screens/settings/settings_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isInitializing = false;
  String _statusMessage = 'جارٍ تهيئة التطبيق';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startInitialization();
  }

  Future<void> _startInitialization() async {
    if (_isInitializing) return;
    _isInitializing = true;

    setState(() {
      _hasError = false;
      _isLoading = true;
      _statusMessage = 'جارٍ تحميل البيانات';
    });

    final startTime = DateTime.now();

    try {
      final activeAccount = await SessionManager.getActiveAccount();
      if (activeAccount != null) {
        NotificationCenter.instance.setCurrentUser(
          activeAccount.userId.toString(),
          resetHistory: false,
        );
      }
      if (!mounted) return;

      if (activeAccount == null ||
          activeAccount.token.isEmpty ||
          activeAccount.username.isEmpty) {
        final elapsed = DateTime.now().difference(startTime);
        final remaining = const Duration(seconds: 2) - elapsed;
        if (remaining > Duration.zero) {
          await Future.delayed(remaining);
        }
        if (!mounted) return;
        _navigateToLogin();
        return;
      }

      setState(() {
        _statusMessage = 'جارٍ جلب بيانات المستخدم';
      });

      final userCubit = context.read<UserInfoCubit>();
      final trafficCubit = context.read<AdslTrafficCubit>();
      final userInfoFuture = userCubit.fetchUserInfo(
        activeAccount.token,
        activeAccount.username,
      );
      final trafficFuture = trafficCubit.fetchTraffic(
        activeAccount.username,
        token: activeAccount.token,
      );

      final gotUserInfo = await userInfoFuture;
      if (!mounted) return;

      if (!gotUserInfo) {
        final state = userCubit.state;
        final message = state is UserInfoError
            ? state.message
            : 'تعذر جلب بيانات المستخدم.';
        _showError(message);
        return;
      }

      setState(() {
        _statusMessage = 'جارٍ تحميل الاستهلاك';
      });

      final gotTraffic = await trafficFuture;
      if (!mounted) return;

      if (!gotTraffic) {
        final state = trafficCubit.state;
        final message = state is AdslTrafficError
            ? state.message
            : 'تعذر جلب بيانات الاستهلاك.';
        _showError(message);
        return;
      }
      final elapsed = DateTime.now().difference(startTime);
      final remaining = const Duration(seconds: 2) - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
      if (!mounted) return;
      _navigateToHome();
    } finally {
      _isInitializing = false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _isLoading = false;
      _statusMessage = message;
    });
  }

  void _navigateToHome() {
    _controller.stop();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToLogin() {
    _controller.stop();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final logoSize = (size.width * 0.6).clamp(180.0, 280.0);
    final logoPadding = size.width < 360 ? 18.0 : 28.0;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.95),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
                  theme.colorScheme.secondary.withValues(alpha: 0.9),
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.2, 0.45, 0.75, 1.0],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: size, painter: GridPainter(progress)),
                CustomPaint(size: size, painter: StarsPainter(progress)),
                ...List.generate(3, (i) {
                  final rippleProgress = ((progress + i * 0.3) % 1.0);
                  final radius = 120.0 + (rippleProgress * 150);
                  final opacity = (1 - rippleProgress).clamp(0.0, 1.0);

                  return Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35 * opacity,
                        ),
                        width: 2,
                      ),
                    ),
                  );
                }),
                Transform.scale(
                  scale: 1.0 + (sin(progress * 2 * pi) * 0.05),
                  child: ClipOval(
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      padding: EdgeInsets.all(logoPadding),
                      color: Colors.transparent,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: _buildStatusCard(theme),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Container(
          key: ValueKey('$_hasError-$_statusMessage'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hasError
                  ? theme.colorScheme.error.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isLoading && !_hasError)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  else
                    Icon(
                      _hasError ? Icons.wifi_off : Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (_hasError) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _startInitialization(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _navigateToSettings,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('الإعدادات'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _navigateToLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('تسجيل الدخول'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double progress;
  GridPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x + (progress * 10), 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(
        Offset(0, y + (progress * 10)),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => true;
}

class StarsPainter extends CustomPainter {
  final double progress;
  StarsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint();

    for (int i = 0; i < 50; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;

      final twinkle = (sin(progress * 2 * pi + i) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: 0.3 + twinkle * 0.7);

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => true;
}

