import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/api_enums.dart';
import '../../features/auth/auth_controller.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/info_cards.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _parentCtl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _parentCtl.dispose();
    super.dispose();
  }

  void _initParent(String? initial) {
    if (!_initialized) {
      _parentCtl.text = initial ?? '';
      _initialized = true;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final raw = _parentCtl.text.trim();
      if (raw.isEmpty) return;
      if (Validators.parentPhone(raw) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم هاتف غير صالح')),
        );
        return;
      }
      await ref.read(authControllerProvider.notifier).updateParentPhone(raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث رقم ولي الأمر'),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.valueOrNull;
    _initParent(user?.parentPhone);

    return RefreshIndicator(
      onRefresh: () => ref.read(authControllerProvider.notifier).refreshUser(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: AppDimensions.xxl),
          if (user != null) _HeaderCard(user: user),
          const SizedBox(height: AppDimensions.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.horizontalPadding),
            child: Text(
              'رقم هاتف ولي الأمر',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.horizontalPadding),
            child: AppTextField(
              controller: _parentCtl,
              label: 'رقم التواصل مع الأب/الأم',
              hint: '05XXXXXXXX',
              icon: Icons.phone_iphone,
              keyboardType: TextInputType.number,
              maxLength: 10,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.horizontalPadding),
            child: AppPrimaryButton(
              label: 'حفظ رقم ولي الأمر',
              loading: _saving,
              onPressed: _save,
              icon: Icons.save_outlined,
            ),
          ),
          const SizedBox(height: AppDimensions.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.horizontalPadding),
            child: _MetaCard(user: user),
          ),
          const SizedBox(height: AppDimensions.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.horizontalPadding),
            child: OutlinedButton.icon(
              onPressed: () => _showSignOutConfirm(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }

  void _showSignOutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'تسجيل الخروج؟',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'ستحتاج لإعادة إدخال رقمك ورمز التحقق.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final dynamic user;
  const _HeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (user.displayName ?? user.phone).toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.horizontalPadding),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          gradient: AppColors.cosmicGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.warmGradient,
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.phone(user.phone.toString()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (user.grade != null)
                        PillTag(
                          label: (user.grade as Grade).labelAr,
                          color: AppColors.primary,
                        ),
                      if (user.branch != null) ...[
                        const SizedBox(width: 6),
                        PillTag(
                          label: (user.branch as Branch).shortAr,
                          color: AppColors.accent,
                          textColor: Colors.black,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final s = name.trim();
    if (s.isEmpty) return '?';
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length >= 2) return parts[0][0] + parts[1][0];
    return parts[0][0];
  }
}

class _MetaCard extends StatelessWidget {
  final dynamic user;
  const _MetaCard({this.user});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          _MetaRow(
            label: 'تاريخ الانضمام',
            value: Formatters.date(user?.createdAt?.toIso8601String()),
            icon: Icons.calendar_today_outlined,
          ),
          const Divider(height: AppDimensions.xl),
          _MetaRow(
            label: 'الدور',
            value: (user?.role as UserRole?)?.labelAr ?? 'طالب',
            icon: Icons.badge_outlined,
          ),
          const Divider(height: AppDimensions.xl),
          _MetaRow(
            label: 'إصدار التطبيق',
            value: '1.0.0',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetaRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
