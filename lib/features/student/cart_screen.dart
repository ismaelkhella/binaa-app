import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/cart.dart';
import '../../providers.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/status_views.dart';

final cartProvider = FutureProvider.autoDispose<CartResponse>((ref) {
  return ref.read(cartRepositoryProvider).getCart();
});

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('سلة التسوق', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: ErrorView(
            title: 'تعذر تحميل السلة',
            message: err is ApiException ? err.message : 'خطأ غير متوقع',
            onRetry: () => ref.refresh(cartProvider),
          ),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'سلة التسوق فارغة',
              message: 'لم تضف أي مواد تعليمية بعد. استكشف المواد وابدأ رحلتك التعليمية الآن!',
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.lg,
                  AppDimensions.lg,
                  AppDimensions.lg,
                  180, // Space for footer
                ),
                itemCount: data.items.length,
                itemBuilder: (context, i) => _CartItemTile(item: data.items[i]),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _CheckoutFooter(response: data),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      item.teacherName ?? 'بدون معلم',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.priceIls} ₪',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  try {
                    await ref.read(cartRepositoryProvider).removeFromCart(item.subjectId);
                    ref.invalidate(cartProvider);
                    ref.invalidate(dashboardDataProvider); // Update dashboard UI
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تعذر حذف المادة')),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutFooter extends ConsumerStatefulWidget {
  final CartResponse response;
  const _CheckoutFooter({required this.response});

  @override
  ConsumerState<_CheckoutFooter> createState() => _CheckoutFooterState();
}

class _CheckoutFooterState extends ConsumerState<_CheckoutFooter> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المجموع الكلي',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${widget.response.totalPriceIls} ₪',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    '${widget.response.items.length} مواد',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            AppPrimaryButton(
              label: 'تأكيد الشراء والاشتراك',
              loading: _loading,
              onPressed: () async {
                setState(() => _loading = true);
                try {
                  final res = await ref.read(cartRepositoryProvider).checkout();
                  if (!mounted) return;
                  _showSuccessDialog(context, res);
                  ref.invalidate(cartProvider);
                  ref.invalidate(dashboardDataProvider); // To refresh subscribed status
                } on ApiException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, CheckoutResponse res) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.successSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Text(
                'تهانينا! اكتمل الشراء',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                res.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              AppPrimaryButton(
                label: 'ابدأ التعلم الآن',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
