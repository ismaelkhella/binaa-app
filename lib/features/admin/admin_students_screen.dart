import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/admin_dashboard.dart';
import '../../data/models/api_enums.dart';
import '../../data/repositories/admin_repository.dart';
import '../../providers.dart';
import '../../widgets/info_cards.dart';
import '../../widgets/status_views.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  final _searchCtl = TextEditingController();
  AdminStudentFilter _filter = const AdminStudentFilter();
  late Future<List<StudentAdminRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<StudentAdminRow>> _load() {
    return ref.read(adminRepositoryProvider).students(filter: _filter);
  }

  void _reload() => setState(() => _future = _load());

  void _applyFilters() => setState(() => _future = _load());

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StudentAdminRow>>(
      future: _future,
      builder: (context, snap) {
        return Column(
          children: [
            _Filters(
              searchCtl: _searchCtl,
              filter: _filter,
              onChanged: (f) {
                _filter = f;
                _applyFilters();
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: _buildList(snap),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(AsyncSnapshot<List<StudentAdminRow>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: const [
          ShimmerBlock(height: 70, radius: 12),
          SizedBox(height: AppDimensions.md),
          ShimmerBlock(height: 70, radius: 12),
          SizedBox(height: AppDimensions.md),
          ShimmerBlock(height: 70, radius: 12),
        ],
      );
    }
    if (snap.hasError) {
      return ErrorView(
        title: 'تعذّر تحميل الطلاب',
        message: (snap.error as ApiException).message,
        onRetry: _reload,
      );
    }
    final list = snap.data ?? const [];
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.person_search_outlined,
            title: 'لا يوجد طلاب بالفلاتر الحالية',
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.horizontalPadding,
        vertical: AppDimensions.md,
      ),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
      itemBuilder: (context, i) => _StudentRow(
        student: list[i],
        onGrant: () => _showGrantDialog(list[i]),
      ),
    );
  }

  void _showGrantDialog(StudentAdminRow student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return _GrantSheet(
          student: student,
          onGrant: (planType, days) async {
            try {
              await ref.read(adminRepositoryProvider).grant(
                    student.id,
                    planType: planType,
                    durationDays: days,
                  );
              if (!mounted) return;
              Navigator.of(sheetCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم منح الاشتراك'),
                  backgroundColor: AppColors.success,
                ),
              );
              _reload();
            } on ApiException catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message)),
              );
            }
          },
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController searchCtl;
  final AdminStudentFilter filter;
  final ValueChanged<AdminStudentFilter> onChanged;

  const _Filters({
    required this.searchCtl,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.horizontalPadding,
        vertical: AppDimensions.md,
      ),
      child: Column(
        children: [
          TextField(
            controller: searchCtl,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث برقم الهاتف أو الاسم',
            ),
            onChanged: (v) =>
                onChanged(AdminStudentFilter(grade: filter.grade, branch: filter.branch, search: v)),
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _PillOption<Grade?>(
                label: 'كل الصفوف',
                value: null,
                selected: filter.grade == null,
                onTap: (v) => onChanged(
                  AdminStudentFilter(search: searchCtl.text, grade: v, branch: filter.branch),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              _PillOption<Grade?>(
                label: '11',
                value: Grade.eleven,
                selected: filter.grade == Grade.eleven,
                onTap: (v) => onChanged(
                  AdminStudentFilter(search: searchCtl.text, grade: v, branch: filter.branch),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              _PillOption<Grade?>(
                label: '12',
                value: Grade.twelve,
                selected: filter.grade == Grade.twelve,
                onTap: (v) => onChanged(
                  AdminStudentFilter(search: searchCtl.text, grade: v, branch: filter.branch),
                ),
              ),
              const SizedBox(width: AppDimensions.lg),
              _PillOption<Branch?>(
                label: 'كل الفروع',
                value: null,
                selected: filter.branch == null,
                onTap: (v) => onChanged(
                  AdminStudentFilter(search: searchCtl.text, grade: filter.grade, branch: v),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              _PillOption<Branch?>(
                label: 'علمي',
                value: Branch.scientific,
                selected: filter.branch == Branch.scientific,
                onTap: (v) => onChanged(
                  AdminStudentFilter(search: searchCtl.text, grade: filter.grade, branch: v),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              _PillOption<Branch?>(
                label: 'أدبي',
                value: Branch.literary,
                selected: filter.branch == Branch.literary,
                onTap: (v) => onChanged(
                  AdminStudentFilter(search: searchCtl.text, grade: filter.grade, branch: v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillOption<T> extends StatelessWidget {
  final String label;
  final T value;
  final bool selected;
  final ValueChanged<T> onTap;
  const _PillOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(color: AppColors.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final StudentAdminRow student;
  final VoidCallback onGrant;
  const _StudentRow({required this.student, required this.onGrant});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: t.colorScheme.outline.withOpacity(0.4)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
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
              IconButton(
                tooltip: 'منح اشتراك',
                onPressed: onGrant,
                icon: const Icon(Icons.local_offer, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              if (student.grade != null)
                InfoChip(
                  label: student.grade!,
                  icon: Icons.layers_outlined,
                  small: true,
                ),
              const SizedBox(width: 6),
              if (student.branch != null)
                InfoChip(
                  label: student.branch!,
                  color: AppColors.accentLight.withOpacity(0.4),
                  textColor: AppColors.accentDark,                        icon: Icons.account_tree_outlined,
                  small: true,
                ),
              const SizedBox(width: 6),
              InfoChip(
                label: '${student.viewsCount} مشاهدة',
                icon: Icons.visibility_outlined,
                color: AppColors.primarySurface,
                textColor: AppColors.primaryDark,
                small: true,
              ),
            ],
          ),
          if (student.subscription != null) ...[
            const SizedBox(height: 6),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.workspace_premium,
                    size: 14, color: AppColors.accentDark),
                const SizedBox(width: 6),
                Text(
                  student.subscription!.planName.isEmpty
                      ? student.subscription!.planType
                      : student.subscription!.planName,
                  style: const TextStyle(
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ينتهي ${Formatters.date(student.subscription!.endDate.toIso8601String())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GrantSheet extends StatefulWidget {
  final StudentAdminRow student;
  final Future<void> Function(PlanType planType, int? durationDays) onGrant;
  const _GrantSheet({required this.student, required this.onGrant});

  @override
  State<_GrantSheet> createState() => _GrantSheetState();
}

class _GrantSheetState extends State<_GrantSheet> {
  PlanType _plan = PlanType.monthly;
  int _days = 30;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'منح اشتراك لـ ${widget.student.name ?? widget.student.phone}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppDimensions.lg),
            Wrap(
              spacing: AppDimensions.sm,
              runSpacing: 8,
              children: PlanType.values.map((p) {
                return ChoiceChip(
                  label: Text(p.name.toUpperCase()),
                  selected: _plan == p,
                  onSelected: (_) => setState(() => _plan = p),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                const Text('المدة (يوم): '),
                Expanded(
                  child: Slider(
                    value: _days.toDouble(),
                    min: 7,
                    max: 365,
                    divisions: 51,
                    label: '$_days',
                    onChanged: (v) => setState(() => _days = v.round()),
                  ),
                ),
                Text('$_days'),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await widget.onGrant(_plan, _days);
                      if (mounted) setState(() => _busy = false);
                    },
              child: Text(_busy ? '...' : 'منح الاشتراك'),
            ),
          ],
        ),
      ),
    );
  }
}
