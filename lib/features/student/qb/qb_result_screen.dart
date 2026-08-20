import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class QbResultScreen extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final String unitId;
  final String unitName;

  const QbResultScreen({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.unitId,
    required this.unitName,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (correctCount / totalCount * 100).toInt();
    final isPass = percentage >= 50;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                isPass ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                size: 100,
                color: isPass ? Colors.amber : AppColors.danger,
              ),
              const SizedBox(height: AppDimensions.xl),
              Text(
                isPass ? 'عمل رائع!' : 'حاول مرة أخرى',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                'لقد أنهيت بنك أسئلة\n$unitName',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.xxl),
              Container(
                padding: const EdgeInsets.all(AppDimensions.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('الإجمالي', '$totalCount'),
                        _buildStat('صحيحة', '$correctCount'),
                        _buildStat('النسبة', '$percentage%'),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('رجوع للوحدات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppDimensions.md),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Since we used pushReplacement for QbResultScreen, we can't just pop to restart.
                  // But QbSolvingScreen is replaced. 
                  // The user can re-select the unit from QbUnitsScreen.
                },
                child: const Text('إعادة المحاولة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
        ),
      ],
    );
  }
}
