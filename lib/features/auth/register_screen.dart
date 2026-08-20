import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../data/models/api_enums.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _agree = false;
  Grade? _selectedGrade;
  Branch? _selectedBranch;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (name.isEmpty) {
      _showError('الرجاء إدخال الاسم الكامل');
      return;
    }
    if (phone.isEmpty) {
      _showError('الرجاء إدخال رقم الهاتف');
      return;
    }
    if (_selectedGrade == null) {
      _showError('الرجاء اختيار الصف الدراسي');
      return;
    }
    if (_selectedBranch == null) {
      _showError('الرجاء اختيار الفرع');
      return;
    }
    if (password.isEmpty) {
      _showError('الرجاء إدخال كلمة المرور');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            phone: phone,
            password: password,
            name: name,
            grade: _selectedGrade!,
            branch: _selectedBranch!,
          );
      // GoRouter handles redirection
    } catch (e) {
      _showError('خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bina Academy',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إنشاء حساب جديد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'انضم إلى مجتمعنا الأكاديمي وابدأ رحلة التميز اليوم.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(AppDimensions.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'الاسم الكامل',
                    hint: 'أدخل اسمك الثلاثي',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  AppTextField(
                    controller: _phoneCtrl,
                    label: 'رقم الهاتف',
                    hint: '05XXXXXXXX',
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  const Text(
                    'الصف الدراسي',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Grade>(
                    value: _selectedGrade,
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'اختر سنتك الدراسية',
                      prefixIcon:
                          const Icon(Icons.school_outlined, color: AppColors.primary),
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      filled: true,
                    ),
                    items: Grade.values
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.labelAr, textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGrade = v),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  const Text(
                    'الفرع',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Branch>(
                    value: _selectedBranch,
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'اختر الفرع',
                      prefixIcon:
                          const Icon(Icons.account_tree_outlined, color: AppColors.primary),
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      filled: true,
                    ),
                    items: Branch.values
                        .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.labelAr, textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBranch = v),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  const Text(
                    'كلمة المرور',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: '********',
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const Text(
                    'يجب أن تحتوي على 8 أحرف على الأقل',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Checkbox(
                        value: _agree,
                        onChanged: (v) => setState(() => _agree = v ?? false),
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'أوافق على '),
                              const TextSpan(
                                text: 'الشروط والأحكام',
                                style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' و '),
                              const TextSpan(
                                text: 'سياسة الخصوصية',
                                style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' الخاصة بأكاديمية بناء.'),
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                          style:
                              TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'إنشاء حساب',
                    icon: Icons.person_add_outlined,
                    loading: _loading,
                    onPressed: _agree ? _submit : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text('لديك حساب بالفعل؟ ', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
