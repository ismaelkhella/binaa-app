import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../data/models/api_enums.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/gradient_background.dart';
import 'auth_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  Grade _grade = Grade.twelve;
  Branch _branch = Branch.scientific;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).completeProfile(
            grade: _grade,
            branch: _branch,
          );
    } catch (_) {
      // error surfaced via state
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authControllerProvider.notifier).form;
    return Scaffold(
      body: GradientBackground(
        dark: true,
        withStars: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.md),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Material(
                      color: Colors.white.withOpacity(0.15),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_forward, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                const Center(child: BrandLogo(size: 70, bright: true)),
                const SizedBox(height: AppDimensions.lg),
                Text(
                  'أكمل ملفك',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'سيتم تخصيص المواد والمحتوى حسب صفك وفرعك.',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: AppDimensions.xl),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel(text: 'الصف'),
                      const SizedBox(height: AppDimensions.sm),
                      _SegmentedChoice(
                        options: const [
                          ('الحادي عشر', Grade.eleven),
                          ('الثاني عشر', Grade.twelve),
                        ],
                        selected: _grade,
                        onChanged: (v) => setState(() => _grade = v),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      const _SectionLabel(text: 'الفرع'),
                      const SizedBox(height: AppDimensions.sm),
                      _SegmentedChoice(
                        options: const [
                          ('الفرع العلمي', Branch.scientific),
                          ('الفرع الأدبي', Branch.literary),
                        ],
                        selected: _branch,
                        onChanged: (v) => setState(() => _branch = v),
                      ),
                      if (form.error != null) ...[
                        const SizedBox(height: AppDimensions.md),
                        Text(
                          form.error!,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.lg),
                      AppPrimaryButton(
                        label: 'ابدأ التعلّم',
                        icon: Icons.auto_stories,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.md),
                  child: Text(
                    'بمجرد اكتمال التسجيل ستحصل على اشتراك تجريبي تلقائي (إن وُجدت خطة تجريبية).',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
                  ),
                ),
                const SizedBox(height: AppDimensions.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
    );
  }
}

class _SegmentedChoice<T> extends StatelessWidget {
  final List<(String, T)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _SegmentedChoice({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        for (final opt in options) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt.$2),
              child: AnimatedContainer(
                duration: AppDimensions.shortAnim,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: selected == opt.$2
                      ? AppColors.brandGradient
                      : null,
                  color: selected == opt.$2 ? null : theme.colorScheme.surfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: selected == opt.$2
                        ? Colors.transparent
                        : theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    opt.$1,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: selected == opt.$2
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (opt != options.last) const SizedBox(width: AppDimensions.md),
        ],
      ],
    );
  }
}
