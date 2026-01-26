import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aya_isp/core/error_handler.dart';
import 'package:aya_isp/core/legal_texts.dart';
import 'package:aya_isp/core/ui.dart';
import 'package:aya_isp/cubits/adsl_traffic_cubit.dart';
import 'package:aya_isp/cubits/auth_cubit.dart';
import 'package:aya_isp/cubits/userinfo_cubit.dart';
import 'package:aya_isp/models/login_model.dart';
import 'package:aya_isp/screens/home/home_screen.dart';
import 'package:aya_isp/services/notification_center.dart';
import 'package:aya_isp/services/notification_prefetcher.dart';

import 'widgets/saved_credentials_field.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function(LoginData data, String username)? onLoggedIn;
  final bool showBackButton;

  const LoginScreen({super.key, this.onLoggedIn, this.showBackButton = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isPostLoginLoading = false;
  bool _acceptedTerms = false;

  String? _savedUsername;
  List<SavedCredential> _savedCredentials = [];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animationController.forward();
    _loadSavedUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUsername = prefs.getString('username');
    final credentialEntries =
        prefs.getStringList('user_credentials_history') ?? [];

    final parsed = credentialEntries
        .map(SavedCredential.fromStorage)
        .whereType<SavedCredential>()
        .toList();

    if (!mounted) return;
    setState(() {
      _savedUsername = cachedUsername;
      _savedCredentials = parsed;
    });
  }

  Future<void> _persistCredential({
    required SharedPreferences prefs,
    required String username,
    required String password,
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return;

    final entries = prefs.getStringList('user_credentials_history') ?? [];
    entries.removeWhere((entry) {
      final saved = SavedCredential.fromStorage(entry);
      return saved?.username == trimmed;
    });

    final savedCredential = SavedCredential(
      username: trimmed,
      password: password,
    );

    entries.insert(0, savedCredential.toStorage());
    await prefs.setStringList('user_credentials_history', entries);
  }

  Future<void> _openLegalPage() async {
    final uri = Uri.parse(privacyText);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) _showLaunchError();
    } catch (_) {
      _showLaunchError();
    }
  }

  Future<void> _callCustomerService() async {
    final uri = Uri(scheme: 'tel', path: '0119806');
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        throw Exception('لم يتم فتح تطبيق الهاتف');
      }
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        'خطأ أثناء فتح تطبيق الهاتف.',
        type: AppMessageType.error,
      );
    }
  }

  void _showLaunchError() {
    if (!mounted) return;
    showAppMessage(
      context,
      'تعذر فتح صفحة سياسة الخصوصية. يرجى المحاولة لاحقًا.',
      type: AppMessageType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isAddAccountFlow = widget.onLoggedIn != null;

    return Scaffold(
      body: Stack(
        children: [
          BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) async {
              if (state is AuthSuccess) {
                setState(() => _isPostLoginLoading = true);

                final username = _usernameController.text.trim();

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('username', username);
                await _persistCredential(
                  prefs: prefs,
                  username: username,
                  password: _passwordController.text,
                );

                NotificationCenter.instance.setCurrentUser(
                  state.user.userId.toString(),
                  resetHistory: true,
                );

                if (widget.onLoggedIn != null) {
                  await widget.onLoggedIn!(state.user, username);
                  return;
                }

                String? refreshError;
                try {
                  final token = state.user.token;
                  if (token.isNotEmpty && username.isNotEmpty) {
                    await context.read<UserInfoCubit>().fetchUserInfo(
                      token,
                      username,
                    );
                    await context.read<AdslTrafficCubit>().fetchTraffic(
                      username,
                      token: token,
                    );
                  }
                } catch (e) {
                  refreshError = ErrorHandler.getErrorMessage(e);
                }

                await NotificationPrefetcher.fetchOncePerSession(force: true);

                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );

                showAppMessage(
                  context,
                  'تم تسجيل الدخول بنجاح',
                  type: AppMessageType.success,
                );

                if (refreshError != null) {
                  showAppMessage(
                    context,
                    refreshError,
                    type: AppMessageType.error,
                  );
                }

                setState(() => _isPostLoginLoading = false);
              }

              if (state is AuthFailure) {
                showAppMessage(
                  context,
                  state.message,
                  type: AppMessageType.error,
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (widget.showBackButton)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),

                          const SizedBox(height: 30),

                          Container(
                            width: (size.width * 0.65).clamp(160.0, 240.0),
                            height: (size.width * 0.35).clamp(100.0, 160.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface, // أبيض
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                width:
                                    (size.width * 0.65).clamp(160.0, 240.0) *
                                    0.7,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          Text(
                            isAddAccountFlow
                                ? 'إضافة حساب جديد'
                                : 'مرحبًا بك ، قم بتسجيل الدخول إلى حسابك باستخدام حسابك الخاص بمزود انترنت آية',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    SavedCredentialsField(
                                      usernameController: _usernameController,
                                      passwordController: _passwordController,
                                      focusNode: _usernameFocusNode,
                                      savedUsername: _savedUsername,
                                      credentials: _savedCredentials,
                                    ),

                                    const SizedBox(height: 20),

                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      decoration: InputDecoration(
                                        labelText: 'كلمة المرور',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'يرجى إدخال كلمة المرور';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    CheckboxListTile(
                                      value: _acceptedTerms,
                                      onChanged: (v) {
                                        setState(() {
                                          _acceptedTerms = v ?? false;
                                        });
                                      },
                                      title: const Text(
                                        'أوافق على سياسة الخصوصية وشروط الاستخدام',
                                        textDirection: TextDirection.rtl,
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    ),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: _openLegalPage,
                                        icon: const Icon(Icons.link),
                                        label: const Text('عرض سياسة الخصوصية'),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              if (_formKey.currentState!
                                                      .validate() &&
                                                  _acceptedTerms) {
                                                context.read<AuthCubit>().login(
                                                  _usernameController.text
                                                      .trim(),
                                                  _passwordController.text,
                                                );
                                              }
                                            },
                                      child: isLoading
                                          ? const CircularProgressIndicator()
                                          : const Text('تسجيل الدخول'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          InkWell(
                            onTap: _callCustomerService,
                            child: Text(
                              'لمزيد من المعلومات اتصل بنا : 0119806',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_isPostLoginLoading) const _PostLoginLoader(),
        ],
      ),
    );
  }
}

class _PostLoginLoader extends StatelessWidget {
  const _PostLoginLoader();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
