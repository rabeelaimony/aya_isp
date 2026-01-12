import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/ui.dart';
import '../../cubits/change_account_cubit.dart';
import '../../cubits/change_account_state.dart';
import '../../cubits/userinfo_cubit.dart';

class ChangeToNakabaScreen extends StatefulWidget {
  const ChangeToNakabaScreen({super.key});

  @override
  State<ChangeToNakabaScreen> createState() => _ChangeToNakabaScreenState();
}

class _ChangeToNakabaScreenState extends State<ChangeToNakabaScreen> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _isPicking = false;
  String? _username;
  String? _token;
  final _nakabaController = TextEditingController();
  int? _selectedNakabaId;

  final List<Map<String, dynamic>> _nakabas = [
    {'id': 4, 'name': ' نقابة المهندسين'},
    {'id': 5, 'name': ' نقابة الصيادلة'},
    {'id': 6, 'name': ' نقاية الأطباء'},
    {'id': 7, 'name': ' نقابة المحاميين'},
    {'id': 8, 'name': ' نقابة أطباء الأسنان'},
    {'id': 9, 'name': ' نقابة المعلمين'},
    {'id': 12, 'name': 'نقابة العمال'},
    {'id': 13, 'name': 'نقابة المهن المالية والمصرفية'},
    {'id': 14, 'name': 'نقابة الفنانيين'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCreds();
  }

  Future<void> _loadCreds() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString('username');
      _token = prefs.getString('token');
    });
  }

  Future<void> _pickImage() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final allowed = await _ensureGalleryPermission();
      if (!allowed) return;

      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (!mounted) return;
      if (picked != null) {
        setState(() => _image = picked);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'تعذر اختيار الصورة: ${e.message ?? 'إذن غير متوفر'}',
          type: AppMessageType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'خطأ غير متوقع: $e',
          type: AppMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    PermissionStatus status;
    try {
      status = await Permission.photos.request();
    } catch (_) {
      status = PermissionStatus.denied;
    }

    if (!status.isGranted && Platform.isAndroid) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('مطلوب إذن المعرض'),
          content: const Text(
            'يرجى فتح إعدادات التطبيق وتفعيل إذن الوصول للمعرض للمتابعة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ليس الآن'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('فتح الإعدادات'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        openAppSettings();
      }
      return false;
    }

    if (mounted) {
      showAppMessage(
        context,
        'إذن المعرض مطلوب لإرفاق الصورة.',
        type: AppMessageType.error,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userState = context.watch<UserInfoCubit>().state;
    int balance = 0;
    String? expiryRaw;

    if (userState is UserInfoLoaded) {
      balance = userState.userInfo.data?.balance ?? 0;
      expiryRaw = userState.userInfo.data?.user?.account?.expireDate;
    }

    final remainingDays = _daysRemaining(expiryRaw);
    final expiryOk = remainingDays >= 0 && remainingDays < 15;
    final balanceOk = balance >= 10;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تحويل إلى نقابة')),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.primary.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                child: Icon(
                                  Icons.groups_2_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      _username ?? '-',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text('الرصيد: $balance'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text('تاريخ الانتهاء: ${expiryRaw ?? '-'}'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'يجب ان تكون صلاحية الحساب أقل من 15 يوم وتوفر  10 ل.س في المحفظة ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر النقابة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedNakabaId,
                          hint: const Text('حدد النقابة  '),
                          items: _nakabas
                              .map(
                                (n) => DropdownMenuItem<int>(
                                  value: n['id'] as int,
                                  child: Text(n['name'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedNakabaId = v),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nakabaController,
                          decoration: const InputDecoration(
                            labelText: 'الرقم النقابي',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رفع هوية النقابية ',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo),
                            label: const Text('اختر صورة من المعرض'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _image == null
                              ? 'لم يتم اختيار صورة بعد'
                              : 'تم اختيار صورة',
                        ),
                        if (_image != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_image!.path),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'تأكد من أن جميع البيانات صحيحة قبل إرسال الطلب.',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  BlocConsumer<ChangeAccountCubit, ChangeAccountState>(
                    listener: (context, state) {
                      if (!mounted) return;
                      if (state is ChangeAccountSuccess) {
                        showAppMessage(
                          context,
                          state.message,
                          type: AppMessageType.success,
                        );
                        Navigator.of(context).pop(true);
                      } else if (state is ChangeAccountError) {
                        showAppMessage(
                          context,
                          state.message,
                          type: AppMessageType.error,
                        );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is ChangeAccountLoading;
                      final canSubmit =
                          _username != null &&
                          _token != null &&
                          _selectedNakabaId != null &&
                          _image != null &&
                          _nakabaController.text.trim().isNotEmpty &&
                          expiryOk &&
                          balanceOk &&
                          !isLoading;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canSubmit
                              ? () => context
                                    .read<ChangeAccountCubit>()
                                    .changeToNakaba(
                                      username: _username!,
                                      token: _token!,
                                      nakabaNumber: _nakabaController.text
                                          .trim(),
                                      nakabaId: _selectedNakabaId!,
                                      imagePath: _image!.path,
                                    )
                              : null,
                          child: isLoading
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
                              : const Text('إرسال الطلب'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _daysRemaining(String? expDate) {
    if (expDate == null) return -1;
    try {
      final expiry = DateTime.parse(expDate);
      final now = DateTime.now();
      return expiry.difference(now).inDays;
    } catch (_) {
      return -1;
    }
  }
}
