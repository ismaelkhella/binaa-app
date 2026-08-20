import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../data/models/student_stats.dart';
import '../../data/repositories/user_repository.dart';
import '../../providers.dart';
import '../../widgets/status_views.dart';

final performanceDataProvider = FutureProvider<PerformanceData>((ref) {
  return ref.read(userRepositoryProvider).getPerformance();
});

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performance = ref.watch(performanceDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مساري التعليمي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: performance.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: ErrorView(
            title: 'تعذر تحميل بيانات الأداء',
            onRetry: () => ref.refresh(performanceDataProvider),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.refresh(performanceDataProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            children: [
              const Text(
                'نظرة عامة على الأداء',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const Text(
                'نتتبع تقدمك الأسبوعي ونحقق أهدافك الأكاديمية.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: AppDimensions.xl),
              _AchievementCard(percent: data.goalsAchievementPercent),
              const SizedBox(height: AppDimensions.md),
              _ComparisonCard(percent: data.peerComparisonPercent),
              const SizedBox(height: AppDimensions.xl),
              _StudyHoursChart(hours: data.weeklyStudyHours),
              const SizedBox(height: AppDimensions.xl),
              _SubjectProgressList(progress: data.subjectProgress),
              const SizedBox(height: AppDimensions.xl),
              _RecentQuizzesList(quizzes: data.recentQuizzes),
              const SizedBox(height: AppDimensions.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final int percent;
  const _AchievementCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFFC6F6D5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: Color(0xFF38A169), size: 30),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تحقيق الأهداف',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F855A),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F855A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'من أهداف هذا الأسبوع',
                      style: TextStyle(fontSize: 12, color: Color(0xFF38A169)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Colors.white,
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF38A169)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final int percent;
  const _ComparisonCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: AppColors.primary, size: 30),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مقارنة بالأقران',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '+$percent%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
                const Text(
                  'أعلى من متوسط الصف',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'أداؤك العام يضعك في الربع الأول من الطلاب.',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyHoursChart extends StatelessWidget {
  final List<WeeklyStudyHours> hours;
  const _StudyHoursChart({required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.textPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'ساعات الدراسة الأسبوعية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: hours.map((h) => _Bar(data: h)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final WeeklyStudyHours data;
  const _Bar({required this.data});

  @override
  Widget build(BuildContext context) {
    const maxHeight = 100.0;
    final height = (data.hours / 6) * maxHeight; // Assume 6h is max for scale

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (data.hours > 0)
          Text('${data.hours}h',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 25,
          height: height.clamp(4.0, maxHeight),
          decoration: BoxDecoration(
            color: data.hours > 0 ? AppColors.primary : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(data.day,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SubjectProgressList extends StatelessWidget {
  final List<SubjectProgress> progress;
  const _SubjectProgressList({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نسب الإنجاز في المواد',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppDimensions.xl),
          ...progress.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.subjectName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('${p.progressPercent}%',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: p.progressPercent / 100,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _RecentQuizzesList extends StatelessWidget {
  final List<RecentQuiz> quizzes;
  const _RecentQuizzesList({required this.quizzes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'نتائج الاختبارات القصيرة',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        ...quizzes.map((q) => Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.outline.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: q.score / q.totalQuestions >= 0.8
                          ? const Color(0xFFE6FFFA)
                          : const Color(0xFFFFF5F5),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      '${q.score}/${q.totalQuestions}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: q.score / q.totalQuestions >= 0.8
                            ? const Color(0xFF38A169)
                            : const Color(0xFFE53E3E),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(q.dateText,
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                        q.title.contains('كيمياء')
                            ? Icons.science_outlined
                            : Icons.calculate_outlined,
                        color: AppColors.textSecondary,
                        size: 20),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
