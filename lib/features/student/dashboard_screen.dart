import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../data/models/student_stats.dart';
import '../../providers.dart';
import '../../widgets/status_views.dart';
import 'available_subjects_screen.dart';
import 'cart_screen.dart';

import 'subject_videos_screen.dart';
import 'lesson_details_screen.dart';
import 'qb/qb_subjects_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مساري التعليمي'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          tooltip: 'سلة التسوق',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () => context.push('/downloads'),
            tooltip: 'تحميلاتي',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: ErrorView(
            title: 'تعذر تحميل البيانات',
            onRetry: () => ref.refresh(dashboardDataProvider),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(dashboardDataProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            children: [
              _GreetingCard(
                name: data.studentName,
                progress: data.generalProgress,
              ),
              if (data.continueLearning != null) ...[
                const SizedBox(height: AppDimensions.xl),
                _ContinueLearningCard(data: data.continueLearning!),
              ],
              const SizedBox(height: AppDimensions.xl),
              const _QbShortcutCard(),
              const SizedBox(height: AppDimensions.xl),
              _GoalsCard(data: data.todayGoals),
              const SizedBox(height: AppDimensions.xl),
              _AvailableSubjectsSection(subjects: data.subjectShopping),
              const SizedBox(height: AppDimensions.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _QbShortcutCard extends StatelessWidget {
  const _QbShortcutCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QbSubjectsScreen()),
      ),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.quiz_outlined, color: Colors.white),
            ),
            SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بنك الأسئلة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'اختبر معلوماتك مع مئات الأسئلة المتنوعة',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  final int progress;

  const _GreetingCard({required this.name, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أهلاً بك، $name!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'لقد أحرزت تقدماً رائعاً هذا الأسبوع. استمر في العمل الجيد!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'التقدم العام',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '$progress%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.success),
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

class _ContinueLearningCard extends StatelessWidget {
  final ContinueLearning data;
  const _ContinueLearningCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تابع التعلم',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: AppDimensions.md),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LessonDetailsScreen(
                  videoId: data.videoId,
                  initialPosition: Duration(
                    seconds: (data.durationSec * data.progressPercent / 100).toInt(),
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: AppColors.softShadow,
              border: Border.all(color: AppColors.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(Icons.play_circle_filled, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.videoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${data.subjectName} • متبقي ${data.timeLeftMin} دقيقة',
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: data.progressPercent / 100,
                          backgroundColor: AppColors.surfaceAlt,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  final TodayGoals data;
  const _GoalsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أهداف اليوم',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: AppDimensions.md),
        Container(
          padding: const EdgeInsets.all(AppDimensions.xl),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: data.percentage / 100,
                      strokeWidth: 10,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.success),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${data.completedCount}/${data.totalCount}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
              Text(
                data.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailableSubjectsSection extends StatelessWidget {
  final List<SubjectShoppingItem> subjects;
  const _AvailableSubjectsSection({required this.subjects});

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'تسوق الان',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AvailableSubjectsScreen(subjects: subjects),
                  ),
                );
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length.clamp(0, 5),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.md),
            itemBuilder: (context, i) => _DashboardShoppingCard(item: subjects[i]),
          ),
        ),
      ],
    );
  }
}

class _DashboardShoppingCard extends ConsumerWidget {
  final SubjectShoppingItem item;
  const _DashboardShoppingCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.outline.withOpacity(0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectVideosScreen(
                  subjectId: item.id,
                  name: item.name,
                  isLocked: !item.isSubscribed,
                  price: item.priceIls,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.primary.withOpacity(0.02)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.school_outlined, color: AppColors.primary, size: 32),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      item.teacher?.name ?? 'بدون معلم',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.priceIls} ₪',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                        if (item.isSubscribed)
                          const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981))
                        else if (item.isInCart)
                          const Icon(Icons.shopping_cart, size: 16, color: AppColors.primary)
                        else
                          GestureDetector(
                            onTap: () async {
                              try {
                                await ref.read(cartRepositoryProvider).addToCart(item.id);
                                ref.invalidate(dashboardDataProvider);
                              } catch (_) {}
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
