import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/change_password_cubit.dart';
import '../../cubits/change_password_state.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirm = _confirmPassController.text.trim();

    if (newPass != confirm) {
      if (mounted) {
        showAppMessage(
          context,
          'كلمة المرور وتأكيدها غير متطابقين',
          type: AppMessageType.error,
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString('username');
    final storedToken = prefs.getString('token');

    if (storedUsername == null || storedToken == null) {
      if (mounted) {
        showAppMessage(
          context,
          'لم يتم تسجيل الدخول',
          type: AppMessageType.error,
        );
      }
      return;
    }

    context.read<ChangePasswordCubit>().changePassword(
      username: storedUsername,
      oldPass: oldPass,
      newPass: newPass,
      newPassConfirmation: confirm,
      token: storedToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("تغيير كلمة السر"), elevation: 0),
        body: BlocListener<ChangePasswordCubit, ChangePasswordState>(
          listener: (context, state) {
            if (state is ChangePasswordLoading) {
              // Loading state handled by button
            } else if (state is ChangePasswordSuccess) {
              if (mounted) {
                showAppMessage(
                  context,
                  state.message,
                  type: AppMessageType.success,
                );
                Navigator.pop(context); // رجوع بعد النجاح
              }
            } else if (state is ChangePasswordError) {
              if (mounted) {
                showAppMessage(
                  context,
                  state.message,
                  type: AppMessageType.error,
                );
              }
            }
          },
          child: BlocBuilder<ChangePasswordCubit, ChangePasswordState>(
            builder: (context, state) {
              final isLoading = state is ChangePasswordLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بطاقة معلومات
                      Card(
                        elevation: 2,
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
                                AppTheme.primaryDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'تغيير كلمة المرور',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'قم بإدخال كلمة المرور القديمة والجديدة',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // تنبيه مهم
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.orange.shade50,
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange.shade800,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تنبيه مهم',
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'هذه كلمة سر إعدادات الراوتر. في حال تم تغييرها، سيتوقف الإنترنت مباشرة حتى يتم تحديث الكلمة الجديدة من اعدادات الراوتر.',
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 14,
                                        height: 1.5,
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

                      // كلمة السر القديمة
                      Text(
                        'كلمة السر القديمة',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _oldPassController,
                        obscureText: _obscureOldPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: "أدخل كلمة السر القديمة",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureOldPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureOldPassword = !_obscureOldPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال كلمة السر القديمة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // كلمة السر الجديدة
                      Text(
                        'كلمة السر الجديدة',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newPassController,
                        obscureText: _obscureNewPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: "أدخل كلمة السر الجديدة",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال كلمة السر الجديدة';
                          }
                          if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // تأكيد كلمة السر
                      Text(
                        'تأكيد كلمة السر الجديدة',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPassController,
                        obscureText: _obscureConfirmPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: "أعد إدخال كلمة السر الجديدة",
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى تأكيد كلمة السر';
                          }
                          if (value != _newPassController.text) {
                            return 'كلمة المرور غير متطابقة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // زر التغيير
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'تغيير كلمة السر',
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

                      // نص توجيهي
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
