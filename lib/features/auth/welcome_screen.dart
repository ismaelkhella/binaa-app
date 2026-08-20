import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/gradient_background.dart';
import '../admin/admin_login_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeIn = CurvedAnimation(
        parent: _entryCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        dark: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xxl),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppDimensions.xxl),
                    const Center(child: BrandLogo(size: 120, bright: true)),
                    const SizedBox(height: AppDimensions.lg),
                    const Center(child: BrandWordmark(fontSize: 32)),
                    const SizedBox(height: AppDimensions.xxl),
                    const _FeatureHighlights(),
                    const Spacer(),
                    _CtaGroup(onStart: _openLogin),
                    const SizedBox(height: AppDimensions.xl),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.admin_panel_settings_outlined,
                            color: Colors.white70),
                        label: const Text(
                          'دخول المشرفين',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
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

class _FeatureHighlights extends StatelessWidget {
  const _FeatureHighlights();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('محتوى منظّم لكل صف وفرع', Icons.layers_outlined),
      ('مدرّسون خبراء في التوجيهي', Icons.school_outlined),
      ('علامة مائية وحماية لكل فيديو', Icons.shield_outlined),
      ('مشاهدة بلا إنترنت بعد التنزيل', Icons.cloud_download_outlined),
    ];
    return Column(
      children: [
        for (final entry in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(entry.$2, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Text(
                    entry.$1,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CtaGroup extends StatelessWidget {
  final VoidCallback onStart;
  const _CtaGroup({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 0.4,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 20),
                SizedBox(width: 10),
                Text('ابدأ الآن'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        const Text(
          'بالضغط على "ابدأ الآن" أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
