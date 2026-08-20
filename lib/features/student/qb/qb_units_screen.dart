import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../providers.dart';
import '../../../widgets/status_views.dart';
import 'qb_solving_screen.dart';

class QbUnitsScreen extends ConsumerWidget {
  final String subjectId;
  final String subjectName;

  const QbUnitsScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(qbUnitsProvider(subjectId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('الوحدات الدراسية'),
            Text(
              subjectName,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: unitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          if (err is ApiForbiddenException) {
            return Center(
              child: EmptyState(
                icon: Icons.lock_outline,
                title: 'المحتوى مقفل',
                message: 'يجب عليك الاشتراك في هذه المادة للوصول إلى بنك الأسئلة الخاص بها.',
                action: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('عرض خطط الاشتراك'),
                ),
              ),
            );
          }
          return Center(
            child: ErrorView(
              title: 'تعذر تحميل الوحدات',
              onRetry: () => ref.refresh(qbUnitsProvider(subjectId)),
            ),
          );
        },
        data: (units) {
          if (units.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.list_alt,
                title: 'لا توجد وحدات',
                message: 'لم يتم إضافة وحدات لهذا بنك الأسئلة بعد',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.lg),
            itemCount: units.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
            itemBuilder: (context, index) {
              final unit = units[index];
              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QbSolvingScreen(
                      unitId: unit.id,
                      unitName: unit.name,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.all(AppDimensions.md),
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  side: BorderSide(color: AppColors.outline.withOpacity(0.1)),
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    '${unit.order}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  unit.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${unit.questionsCount} سؤال'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
              );
            },
          );
        },
      ),
    );
  }
}
