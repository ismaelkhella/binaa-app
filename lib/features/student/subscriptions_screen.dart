import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/user.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../providers.dart';
import '../../widgets/info_cards.dart';
import '../../widgets/status_views.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  late Future<_PlansData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PlansData> _load() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final plans = await repo.listPlans();
    final current = await repo.currentSubscription();
    return _PlansData(plans: plans, current: current);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<_PlansData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.horizontalPadding,
                vertical: AppDimensions.xxl,
              ),
              children: const [
                ShimmerBlock(height: 240, radius: 16),
                SizedBox(height: AppDimensions.md),
                ShimmerBlock(height: 240, radius: 16),
              ],
            );
          }
          if (snap.hasError) {
            return ErrorView(
              title: 'تعذّر تحميل الخطط',
              message: (snap.error as ApiException).message,
              onRetry: _reload,
            );
          }
          final data = snap.data!;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.horizontalPadding,
            ),
            children: [
              const SizedBox(height: AppDimensions.xxl),
              Text(
                'خطط الاشتراك',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'حافظ على تقدّمك باشتراك يضمن لك فيديوهات كافية لاجتياز التوجيهي.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              if (data.current != null) ...[
                _CurrentPlanCard(sub: data.current!),
                const SizedBox(height: AppDimensions.lg),
              ],
              for (final plan in data.plans)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: _PlanCard(
                    plan: plan,
                    featured: plan.type.toString().contains('quarter'),
                  ),
                ),
              const SizedBox(height: AppDimensions.xxl),
            ],
          );
        },
      ),
    );
  }
}

class _PlansData {
  final List<SubscriptionPlan> plans;
  final StudentSubscription? current;
  _PlansData({required this.plans, this.current});
}

class _CurrentPlanCard extends StatelessWidget {
  final StudentSubscription sub;
  const _CurrentPlanCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cosmicGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.accent, size: 32),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اشتراكك الحالي',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub.plan.nameAr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'متبقي ${sub.remainingDays} يوم  ·  ينتهي ${Formatters.date(sub.endDate.toIso8601String())}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool featured;
  const _PlanCard({required this.plan, required this.featured});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isTrial = plan.type.toString().endsWith('trial');
    return Container(
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: featured
              ? AppColors.accent
              : t.colorScheme.outline.withOpacity(0.5),
          width: featured ? 2 : 1,
        ),
        boxShadow: featured ? AppColors.elevatedShadow : AppColors.softShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.nameAr,
                        style: t.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (featured)
                      PillTag(
                        label: 'الأكثر تفضيلاً',
                        color: AppColors.accent,
                        icon: Icons.star,
                      )
                    else if (isTrial)
                      PillTag(
                        label: 'تجريبي',
                        color: AppColors.info,
                        icon: Icons.science_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.priceIls == 0 ? 'مجاناً' : Formatters.currency(plan.effectivePrice),
                      style: t.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    if (plan.discountPercent > 0) ...[
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        Formatters.currency(plan.priceIls),
                        style: t.textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${plan.durationDays} يوم  ·  ${plan.videosPerSubject} فيديو لكل مادة',
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: t.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                const _BulletLine(text: 'وصول كامل لكل مواد صفّك وفرعك'),
                const _BulletLine(text: 'مشاهدة بلا إنترنت لكل فيديو ضمن الحصة'),
                const _BulletLine(text: 'علامة مائية تحمي المحتوى'),
              ],
            ),
          ),
          if (featured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: const Center(
                child: Text(
                  'تواصل مع الإدارة للترقية',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  const _BulletLine({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
