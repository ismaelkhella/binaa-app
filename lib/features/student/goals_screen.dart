import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../data/models/student_stats.dart';
import '../../data/repositories/user_repository.dart';
import '../../providers.dart';
import '../../widgets/status_views.dart';

final goalsProvider = StateNotifierProvider<GoalsController,
    AsyncValue<Map<String, List<DailyGoal>>>>((ref) {
  return GoalsController(ref.read(userRepositoryProvider));
});

class GoalsController
    extends StateNotifier<AsyncValue<Map<String, List<DailyGoal>>>> {
  final UserRepository _repo;
  GoalsController(this._repo) : super(const AsyncLoading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.listGoals());
  }

  Future<void> addGoal(String title) async {
    try {
      await _repo.createGoal(title);
      refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleGoal(String id, bool completed) async {
    try {
      await _repo.updateGoal(id, completed: completed);
      // Optimistic update or just refresh
      refresh();
    } catch (e) {}
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _repo.deleteGoal(id);
      refresh();
    } catch (e) {}
  }
}

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

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
      body: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: ErrorView(
            title: 'تعذر تحميل الأهداف',
            onRetry: () => ref.read(goalsProvider.notifier).refresh(),
          ),
        ),
        data: (data) => _GoalsList(data: data),
      ),
    );
  }
}

class _GoalsList extends ConsumerStatefulWidget {
  final Map<String, List<DailyGoal>> data;
  const _GoalsList({required this.data});

  @override
  ConsumerState<_GoalsList> createState() => _GoalsListState();
}

class _GoalsListState extends ConsumerState<_GoalsList> {
  final _goalCtrl = TextEditingController();

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.data['today'] ?? [];
    final archived = widget.data['archived'] ?? [];
    final completed = today.where((g) => g.completed).length;
    final total = today.length;
    final percent = total == 0 ? 0 : (completed / total * 100).toInt();

    return RefreshIndicator(
      onRefresh: () => ref.read(goalsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: [
          _Header(completed: completed, total: total, percent: percent),
          const SizedBox(height: AppDimensions.xl),
          _AddGoalField(
            controller: _goalCtrl,
            onAdd: () {
              final title = _goalCtrl.text.trim();
              if (title.isNotEmpty) {
                ref.read(goalsProvider.notifier).addGoal(title);
                _goalCtrl.clear();
                FocusScope.of(context).unfocus();
              }
            },
          ),
          const SizedBox(height: AppDimensions.xl),
          const Text(
            'مهام اليوم',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: AppDimensions.md),
          if (today.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'لا توجد أهداف لليوم بعد. أضف هدفك الأول!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...today.map((g) => _GoalItem(
                  goal: g,
                  onToggle: (v) =>
                      ref.read(goalsProvider.notifier).toggleGoal(g.id, v!),
                  onDelete: () =>
                      ref.read(goalsProvider.notifier).deleteGoal(g.id),
                )),
          const SizedBox(height: AppDimensions.xl),
          _ArchivedAccordion(archived: archived),
          const SizedBox(height: AppDimensions.xl),
          _QuoteBanner(),
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int completed;
  final int total;
  final int percent;

  const _Header(
      {required this.completed, required this.total, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أهدافي اليومية',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const Text(
            'يوم جديد، إنجازات جديدة.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: AppDimensions.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نسبة الإنجاز اليوم',
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completed من $total أهداف',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              percent >= 100
                  ? 'رائع! لقد أنجزت جميع أهدافك!'
                  : 'استمر يا بطل! أنت على وشك الوصول.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGoalField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddGoalField({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              boxShadow: AppColors.softShadow,
            ),
            child: TextField(
              controller: controller,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'أضف هدفاً جديداً...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                border: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 4),
              Text('إضافة', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalItem extends StatelessWidget {
  final DailyGoal goal;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  const _GoalItem(
      {required this.goal, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textTertiary, size: 20),
            onPressed: onDelete,
          ),
          Expanded(
            child: Text(
              goal.title,
              style: TextStyle(
                decoration: goal.completed ? TextDecoration.lineThrough : null,
                color: goal.completed
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          Checkbox(
            value: goal.completed,
            onChanged: onToggle,
            activeColor: AppColors.success,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }
}

class _ArchivedAccordion extends StatelessWidget {
  final List<DailyGoal> archived;
  const _ArchivedAccordion({required this.archived});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        backgroundColor: Theme.of(context).colorScheme.surface,
        collapsedBackgroundColor: Theme.of(context).colorScheme.surface,
        leading: const Icon(Icons.history, color: AppColors.primary),
        title: const Text(
          'أرشيف الأهداف السابقة',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        children: archived.isEmpty
            ? [
                const ListTile(
                    title: Center(
                        child: Text('الأرشيف فارغ',
                            style: TextStyle(fontSize: 12))))
              ]
            : archived
                .map((g) => ListTile(
                      title: Text(g.title,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                    ))
                .toList(),
      ),
    );
  }
}

class _QuoteBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        gradient: AppColors.cosmicGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: const Column(
        children: [
          Icon(Icons.format_quote, color: Colors.white54, size: 40),
          Text(
            '"النجاح لا يأتي من ما تفعله أحياناً، بل مما تفعله بانتظام."',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
