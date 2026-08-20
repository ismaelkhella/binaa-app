import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/admin_dashboard.dart';
import '../../data/repositories/admin_repository.dart';
import '../../providers.dart';
import '../../widgets/info_cards.dart';
import '../../widgets/status_views.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Future<AdminDashboardStats> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AdminDashboardStats> _load() {
    return ref.read(adminRepositoryProvider).dashboard();
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<AdminDashboardStats>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.lg),
              children: const [
                ShimmerBlock(height: 120, radius: 14),
                SizedBox(height: AppDimensions.md),
                ShimmerBlock(height: 120, radius: 14),
              ],
            );
          }
          if (snap.hasError) {
            return ErrorView(
              title: 'تعذّر تحميل لوحة الإدارة',
              message: (snap.error as ApiException).message,
              onRetry: _reload,
            );
          }
          final s = snap.data!;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.horizontalPadding,
            ),
            children: [
              const SizedBox(height: AppDimensions.lg),
              _KpiHero(stats: s),
              const SizedBox(height: AppDimensions.lg),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'اشتراكات هذا الشهر',
                      value: s.subscriptions.thisMonth.toString(),
                      icon: Icons.local_offer_outlined,
                      accent: AppColors.primary,
                      subtitle: 'الشهر الماضي: ${s.subscriptions.lastMonth}',
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: StatCard(
                      title: 'المحتوى المنشور',
                      value: s.content.totalVideos.toString(),
                      icon: Icons.video_library_outlined,
                      accent: AppColors.success,
                      subtitle: 'نسبة الإكمال ${s.content.completionRate}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),
              const _SectionLabel('آخر الطلاب'),
              const SizedBox(height: AppDimensions.sm),
              if (s.recentStudents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimensions.lg),
                  child: EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'لا يوجد طلاب جدد',
                  ),
                )
              else
                ...s.recentStudents.map((st) => _RecentStudentTile(student: st)),
              const SizedBox(height: AppDimensions.lg),
              const _SectionLabel('أعلى الفيديوهات مشاهدةً'),
              const SizedBox(height: AppDimensions.sm),
              if (s.topVideos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimensions.lg),
                  child: EmptyState(
                    icon: Icons.bar_chart_outlined,
                    title: 'لا توجد بيانات',
                  ),
                )
              else
                ...s.topVideos.map((v) => _TopVideoTile(video: v)),
              const SizedBox(height: AppDimensions.xxl),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String t;
  const _SectionLabel(this.t);
  @override
  Widget build(BuildContext context) {
    return Text(
      t,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _KpiHero extends StatelessWidget {
  final AdminDashboardStats stats;
  const _KpiHero({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cosmicGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إيرادات هذا الشهر',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency(stats.revenue.thisMonth),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
              PillTag(
                label: stats.revenue.currency,
                color: AppColors.accent,
                textColor: Colors.black,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  icon: Icons.people_alt_outlined,
                  label: 'إجمالي الطلاب',
                  value: '${stats.students.total}',
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _HeroPill(
                  icon: Icons.verified_user_outlined,
                  label: 'الفعّالون',
                  value: '${stats.students.active}',
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _HeroPill(
                  icon: Icons.science_outlined,
                  label: 'تجريبي',
                  value: '${stats.students.trial}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeroPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentStudentTile extends StatelessWidget {
  final RecentStudent student;
  const _RecentStudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: t.colorScheme.outline.withOpacity(0.4)),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name?.isNotEmpty == true ? student.name! : 'بدون اسم',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  Formatters.phone(student.phone),
                  style: TextStyle(
                    color: t.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.date(student.createdAt.toIso8601String()),
            style: TextStyle(
              fontSize: 12,
              color: t.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopVideoTile extends StatelessWidget {
  final TopVideo video;
  const _TopVideoTile({required this.video});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: t.colorScheme.outline.withOpacity(0.4)),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  video.subject,
                  style: TextStyle(
                    fontSize: 12,
                    color: t.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  Formatters.compact(video.views),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
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
