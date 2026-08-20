import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/api_enums.dart';
import '../../data/models/subject.dart';
import '../../providers.dart';
import '../../widgets/info_cards.dart';
import '../../widgets/status_views.dart';
import 'cart_screen.dart';
import 'student_tab.dart';
import 'subject_videos_screen.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  late Future<List<Subject>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Subject>> _load() {
    return ref.read(subjectRepositoryProvider).listMySubjects();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final next = _load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المواد الدراسية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
            tooltip: 'الإشعارات',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Subject>>(
          future: _future,
          builder: (context, snap) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppDimensions.xxl)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'موادي الدراسية',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تابع تقدمك في المواد المشترك بها',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),
                        _SearchField(
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: AppDimensions.lg),
                      ],
                    ),
                  ),
                ),
                if (snap.connectionState == ConnectionState.waiting)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.horizontalPadding),
                      child: Column(
                        children: [
                          ShimmerBlock(height: 180, radius: 20),
                          SizedBox(height: AppDimensions.md),
                          ShimmerBlock(height: 180, radius: 20),
                        ],
                      ),
                    ),
                  )
                else if (snap.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(
                      title: 'تعذّر تحميل المواد',
                      message: snap.error is ApiException
                          ? (snap.error as ApiException).message
                          : 'خطأ غير متوقع',
                      onRetry: _reload,
                    ),
                  )
                else
                  ..._subjectSlivers(snap.data ?? const []),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppDimensions.xxl)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _subjectSlivers(List<Subject> subscribed) {
    if (subscribed.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'لا توجد مواد مشتركة',
            message: 'قم بالاشتراك في المواد من الصفحة الرئيسية للبدء في رحلتك التعليمية.',
            action: ElevatedButton.icon(
              onPressed: () {
                ref.read(selectedStudentTabProvider.notifier).state = 0;
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('اكتشف المواد المتاحة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ];
    }
    
    final query = _query.trim();
    final filtered = query.isEmpty
        ? subscribed
        : subscribed
            .where((s) =>
                s.name.contains(query) ||
                (s.teacherName ?? '').contains(query))
            .toList();
            
    if (filtered.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: 'لم نجد ما يطابق "$query"',
            message: 'جرب البحث بكلمات أخرى أو تأكد من مراجعة القائمة.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.horizontalPadding),
        sliver: SliverList.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, i) => _SubjectCard(
            subject: filtered[i],
            index: i,
            onTap: () => _openSubject(filtered[i]),
          ),
        ),
      ),
    ];
  }

  void _openSubject(Subject s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubjectVideosScreen(
          subjectId: s.id,
          name: s.name,
          isLocked: s.locked,
          price: s.priceIls,
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final ctl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: AppColors.softShadow,
      ),
      child: TextField(
        controller: ctl,
        onChanged: widget.onChanged,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث عن مادة أو معلم...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent, // Inherit from container
        ),
      ),
    );
  }

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final int index;
  final VoidCallback onTap;
  const _SubjectCard({
    required this.subject,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = subject.locked;

    final gradients = [
      const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]), // Blue
      const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF10B981)]), // Green
      const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF8B5CF6)]), // Purple
      const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFF59E0B)]), // Orange
    ];
    final gradient =
        isLocked ? AppColors.lockGradient : gradients[index % gradients.length];

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          color: theme.colorScheme.surface,
          boxShadow: AppColors.softShadow,
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Top Banner
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(gradient: gradient),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(_iconFor(subject.name),
                      color: Colors.white.withOpacity(0.9), size: 40),
                  if (isLocked)
                    Container(
                      decoration:
                          BoxDecoration(color: Colors.black.withOpacity(0.3)),
                      child: const Center(
                        child: Icon(Icons.lock_outline,
                            color: Colors.white, size: 32),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subject.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (isLocked)
                        const PillTag(
                            label: 'يتطلب ترقية', color: Colors.orange)
                      else
                        InfoChip(
                          label: '${subject.videoCount} فيديو',
                          icon: Icons.play_circle_outline,
                          small: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        subject.teacherName ?? 'بدون معلم',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مستوى الإنجاز',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        '${subject.progressPercent}%',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: subject.progressPercent / 100,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation(
                        isLocked
                            ? Colors.grey
                            : (subject.progressPercent > 70
                                ? AppColors.success
                                : AppColors.primary),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('رياض')) return Icons.calculate_outlined;
    if (n.contains('فيزي')) return Icons.science_outlined;
    if (n.contains('كيمياء') || n.contains('كيمي'))
      return Icons.biotech_outlined;
    if (n.contains('أحياء') || n.contains('احي')) return Icons.spa_outlined;
    if (n.contains('لغة') || n.contains('عربي') || n.contains('عرب')) {
      return Icons.menu_book_outlined;
    }
    if (n.contains('إنجل') || n.contains('انجل'))
      return Icons.translate_outlined;
    if (n.contains('تاريخ')) return Icons.history_edu_outlined;
    if (n.contains('جغراف')) return Icons.public_outlined;
    return Icons.school_outlined;
  }
}
