import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_background.dart';
import 'admin_controller.dart';
import 'admin_shell.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(adminControllerProvider.notifier).login(
            _emailCtl.text.trim(),
            _passCtl.text,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        dark: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentDark],
                        ),
                        boxShadow: AppColors.elevatedShadow,
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Text(
                      'Bina Admin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _emailCtl,
                            label: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            autofocus: true,
                            validator: (v) {
                              if ((v == null || v.trim().isEmpty)) {
                                return 'الرجاء إدخال البريد الإلكتروني';
                              }
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                                return 'بريد إلكتروني غير صالح';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimensions.md),
                          AppTextField(
                            controller: _passCtl,
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'الرجاء إدخال كلمة المرور';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submit(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppDimensions.md),
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.sm),
                              decoration: BoxDecoration(
                                color: AppColors.dangerSurface,
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusSm),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.danger, size: 18),
                                  const SizedBox(width: AppDimensions.sm),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppDimensions.lg),
                          AppPrimaryButton(
                            label: 'دخول الإدارة',
                            icon: Icons.login,
                            loading: _busy,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white70),
                      label: const Text(
                        'العودة لتطبيق الطالب',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
