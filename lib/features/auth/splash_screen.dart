import 'package:flutter/material.dart';

import '../../widgets/brand_logo.dart';
import '../../widgets/gradient_background.dart';

/// Shown while the persisted session is being validated at app start.
/// The router redirects away from here as soon as auth resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        dark: true,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 120, bright: true),
                const SizedBox(height: 24),
                const BrandWordmark(fontSize: 28),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
