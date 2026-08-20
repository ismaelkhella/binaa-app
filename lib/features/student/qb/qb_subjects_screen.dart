import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../providers.dart';
import '../../../widgets/status_views.dart';
import 'qb_units_screen.dart';

class QbSubjectsScreen extends ConsumerWidget {
  const QbSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(qbSubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بنك الأسئلة - المواد'),
        centerTitle: true,
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: ErrorView(
            title: 'تعذر تحميل المواد',
            onRetry: () => ref.refresh(qbSubjectsProvider),
          ),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.quiz_outlined,
                title: 'لا توجد مواد متاحة',
                message: 'لا توجد مواد بها بنك أسئلة حالياً',
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppDimensions.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.md,
              mainAxisSpacing: AppDimensions.md,
              childAspectRatio: 0.85,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QbUnitsScreen(
                      subjectId: subject.id,
                      subjectName: subject.name,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    boxShadow: AppColors.softShadow,
                    border: Border.all(color: AppColors.outline.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primarySurface,
                        child: Icon(Icons.menu_book, color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        subject.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.unitsCount} وحدة',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
