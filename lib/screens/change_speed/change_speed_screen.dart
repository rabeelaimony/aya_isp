import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error_handler.dart';
import '../../core/logger.dart';
import '../../core/ui.dart';
import '../../cubits/speed_change_cubit.dart';
import '../../cubits/userinfo_cubit.dart';
import '../../services/speed_service.dart';

class SpeedChangeScreen extends StatefulWidget {
  const SpeedChangeScreen({super.key});

  @override
  State<SpeedChangeScreen> createState() => _SpeedChangeScreenState();
}

class _SpeedChangeScreenState extends State<SpeedChangeScreen> {
  final _cubit = SpeedChangeCubit(service: SpeedService());
  SpeedPackage? _selectedPackage;
  int? _currentSpeedValue;
  bool _isIncreasing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPackages());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<int> _getBalance() async {
    try {
      final u = context.read<UserInfoCubit>();
      final state = u.state;
      if (state is UserInfoLoaded) {
        return state.userInfo.data?.balance ?? 0;
      }
    } catch (e, st) {
      AppLogger.e('UserInfo not available from Bloc', e, st);
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('balance') ?? 0;
  }

  int? _parseSpeedValue(String? value) {
    if (value == null) return null;
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  String _formatPrice(String price) {
    final normalized = price.replaceAll(',', '');
    final value = num.tryParse(normalized);
    if (value == null) return price;
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<void> _fetchPackages() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      if (!mounted) return;
      showAppMessage(
        context,
        'يرجى إعادة تسجيل الدخول لإرسال الطلب.',
        type: AppMessageType.error,
      );
      return;
    }

    final userInfoCubit = context.read<UserInfoCubit>();
    final uState = userInfoCubit.state;
    String? accType;
    String? currentSpeedText;
    if (uState is UserInfoLoaded) {
      accType = uState.userInfo.data?.user?.account?.accType;
      currentSpeedText = uState.userInfo.data?.user?.account?.speed;
    }

    final parsedCurrent = _parseSpeedValue(currentSpeedText);
    setState(() {
      _currentSpeedValue = parsedCurrent;
    });

    if (accType == null || accType.isEmpty) {
      if (!mounted) return;
      showAppMessage(
        context,
        'لا يوجد نوع حساب لتحميل الباقات.',
        type: AppMessageType.error,
      );
      return;
    }

    try {
      await _cubit.loadPackages(
        accType: accType,
        bearerToken: token,
        currentSpeed: parsedCurrent,
      );
    } catch (e) {
      if (!mounted) return;
      final m = ErrorHandler.getErrorMessage(e);
      showAppMessage(context, m, type: AppMessageType.error);
    }
  }

  void _handlePackageTap(SpeedPackage pkg) {
    final current = _currentSpeedValue;
    final isUp = current == null ? true : pkg.speedVal > current;
    setState(() {
      _selectedPackage = pkg;
      _isIncreasing = isUp;
    });
  }

  Future<void> _submit() async {
    if (_selectedPackage == null) {
      showAppMessage(
        context,
        'اختر باقة السرعة أولاً.',
        type: AppMessageType.error,
      );
      return;
    }

    final speedId = int.tryParse(_selectedPackage!.id);
    if (speedId == null) {
      showAppMessage(
        context,
        'معرف الباقة غير صالح.',
        type: AppMessageType.error,
      );
      return;
    }

    final balance = await _getBalance();
    final required = _isIncreasing ? 60 : 80;
    if (balance < required) {
      showAppMessage(
        context,
        'الحد الأدنى للرصيد المطلوب: $required',
        type: AppMessageType.error,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final username = prefs.getString('username') ?? '';
    if (token.isEmpty || username.isEmpty) {
      showAppMessage(
        context,
        'يرجى تسجيل الدخول أولاً.',
        type: AppMessageType.error,
      );
      return;
    }

    try {
      await _cubit.changeSpeed(
        username: username,
        speedId: speedId,
        speedVal: _selectedPackage!.speedVal,
        bearerToken: token,
      );
      final msg = _cubit.state.message ?? 'تم إرسال طلب تغيير السرعة.';
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('باقات السرعة'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      final m = ErrorHandler.getErrorMessage(e);
      if (!mounted) return;
      showAppMessage(context, m, type: AppMessageType.error);
    }
  }

  Widget _buildPackagesGrid(BuildContext context, SpeedChangeState state) {
    if (state.packagesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.packages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('لا توجد باقات متاحة حالياً')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final childAspectRatio = isCompact ? 1.05 : 1.3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: state.packages.length,
      itemBuilder: (context, index) {
        final pkg = state.packages[index];
        final selected = _selectedPackage?.id == pkg.id;
        return InkWell(
          onTap: () => _handlePackageTap(pkg),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${pkg.speedVal}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'Mbps',
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? Colors.white70 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatPrice(pkg.price)} ل.س',
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selected) ...[
                  const SizedBox(height: 6),
                  Icon(
                    _isIncreasing ? Icons.trending_up : Icons.trending_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoCubit = context.watch<UserInfoCubit>();
    String? currentSpeed;
    int? balance;
    final uState = userInfoCubit.state;
    if (uState is UserInfoLoaded) {
      currentSpeed = uState.userInfo.data?.user?.account?.speed;
      balance = uState.userInfo.data?.balance;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<SpeedChangeCubit, SpeedChangeState>(
        bloc: _cubit,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('تغيير السرعة'), elevation: 0),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.speed, color: Colors.white, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'السرعة الحالية',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${currentSpeed ?? '-'} Mbps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'نوع الطلب (يُحدد تلقائياً حسب السرعة)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _isIncreasing
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: _isIncreasing
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'رفع السرعة',
                                  style: TextStyle(
                                    color: _isIncreasing
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: !_isIncreasing
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_down,
                                  color: !_isIncreasing
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تخفيض السرعة',
                                  style: TextStyle(
                                    color: !_isIncreasing
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.orange.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ملاحظات هامة:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '• طلب رفع السرعة يتطلب اضافة رصيد60 ل.س إلى المحفظة قبل تنفيذ الطلب.',
                              ),
                              Text(
                                '• طلب تخفيض السرعة يتطلب اضافة رصيد80 ل.س إلى المحفظة قبل تنفيذ الطلب.',
                              ),
                              Text(
                                '• في حال وجود فاتورة على الخط الأرضي لن يتم تنفيذ الطلب.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'اختر الباقة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPackagesGrid(context, state),
                  const SizedBox(height: 32),
                  if (balance != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الرصيد الحالي',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '$balance ل.س',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state.loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: state.loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_circle, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'إرسال الطلب',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
