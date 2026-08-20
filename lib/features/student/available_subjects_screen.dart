import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/student_stats.dart';
import '../../providers.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/info_cards.dart';
import 'cart_screen.dart';
import 'subject_videos_screen.dart';

class AvailableSubjectsScreen extends ConsumerWidget {
  final List<SubjectShoppingItem> subjects;

  const AvailableSubjectsScreen({super.key, required this.subjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسوق الان'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: subjects.isEmpty
          ? const Center(child: Text('لا توجد مواد متاحة حالياً'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.lg),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
              itemBuilder: (context, i) => _ShoppingSubjectCard(item: subjects[i]),
            ),
    );
  }
}

class _ShoppingSubjectCard extends ConsumerWidget {
  final SubjectShoppingItem item;

  const _ShoppingSubjectCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkWell(
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
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                image: item.teacher?.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(item.teacher!.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.teacher?.avatarUrl == null
                  ? const Icon(Icons.school_outlined, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    item.teacher?.name ?? 'بدون معلم',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${item.priceIls} ₪',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (item.isSubscribed)
                        const InfoChip(
                          label: 'مشترك',
                          color: Color(0xFFD1FAE5),
                          textColor: Color(0xFF059669),
                          small: true,
                          icon: Icons.check_circle_outline,
                        )
                      else if (item.isInCart)
                        const InfoChip(
                          label: 'في السلة',
                          color: AppColors.primarySurface,
                          textColor: AppColors.primary,
                          small: true,
                          icon: Icons.shopping_cart_outlined,
                        )
                      else
                        SizedBox(
                          height: 32,
                          child: TextButton.icon(
                            onPressed: () => _addToCart(context, ref),
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('إضافة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
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
    );
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    try {
      final msg = await ref.read(cartRepositoryProvider).addToCart(item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      // Invalidate dashboard to update isInCart state
      ref.invalidate(dashboardDataProvider);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
