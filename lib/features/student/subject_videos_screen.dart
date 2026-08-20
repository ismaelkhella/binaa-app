import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/student_stats.dart';
import '../../data/models/subject.dart';
import '../../data/repositories/subject_repository.dart';
import '../../providers.dart';
import '../../widgets/info_cards.dart';
import '../../widgets/status_views.dart';
import 'lesson_details_screen.dart';

class SubjectVideosScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String name;
  final bool? isLocked;
  final double? price;

  const SubjectVideosScreen({
    super.key,
    required this.subjectId,
    required this.name,
    this.isLocked,
    this.price,
  });

  @override
  ConsumerState<SubjectVideosScreen> createState() =>
      _SubjectVideosScreenState();
}

class _SubjectVideosScreenState extends ConsumerState<SubjectVideosScreen> {
  late Future<SubjectVideosResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SubjectVideosResponse> _load() {
    return ref.read(subjectRepositoryProvider).getSubjectVideos(widget.subjectId);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: FutureBuilder<SubjectVideosResponse>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingBody();
          }
          if (snap.hasError) {
            return ErrorView(
              title: 'تعذّر تحميل الفيديوهات',
              message: (snap.error as ApiException).message,
              onRetry: _reload,
            );
          }
          final data = snap.data!;
          final grouped = _groupByUnit(data.videos);
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.horizontalPadding,
                    vertical: AppDimensions.md,
                  ),
                  child: _Header(
                    summary: data,
                    isLocked: widget.isLocked ?? data.videos.every((v) => v.locked),
                    price: widget.price,
                  ),
                ),
                if (data.dailyQuiz != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.horizontalPadding,
                      vertical: AppDimensions.sm,
                    ),
                    child: _DailyQuizBanner(data: data.dailyQuiz!),
                  ),
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.horizontalPadding,
                      vertical: AppDimensions.sm,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'الوحدة ${entry.key}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Text(
                          '(${entry.value.where((v) => !v.locked).length}/${entry.value.length})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
          for (final v in entry.value)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.horizontalPadding,
                vertical: AppDimensions.xs,
              ),
              child: _VideoTile(
                video: v,
                locked: v.locked,
                isCompleted: v.isCompleted,
                onTap: () {
                  if (v.locked) {
                    _showLockedDialog(context);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LessonDetailsScreen(
                          videoId: v.id,
                          playlist: data.videos,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Map<int, List<SubjectVideoItem>> _groupByUnit(List<SubjectVideoItem> videos) {
    final m = <int, List<SubjectVideoItem>>{};
    for (final v in videos) {
      m.putIfAbsent(v.unitNumber, () => []).add(v);
    }
    for (final list in m.values) {
      list.sort((a, b) => a.orderInUnit.compareTo(b.orderInUnit));
    }
    return m;
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.lockGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 28),
              ),
              const SizedBox(height: AppDimensions.md),
              const Text(
                'هذا الفيديو ضمن حصتك',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: AppDimensions.sm),
              const Text(
                'قم بترقية خطتك للوصول إلى كل الفيديوهات.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('ترقية الخطة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.horizontalPadding,
        vertical: AppDimensions.xxl,
      ),
      child: Column(
        children: const [
          ShimmerBlock(height: 90, radius: 14),
          SizedBox(height: AppDimensions.md),
          ShimmerBlock(height: 60, radius: 10),
          SizedBox(height: AppDimensions.sm),
          ShimmerBlock(height: 60, radius: 10),
          SizedBox(height: AppDimensions.sm),
          ShimmerBlock(height: 60, radius: 10),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final SubjectVideosResponse summary;
  final bool isLocked;
  final double? price;

  const _Header({
    required this.summary,
    required this.isLocked,
    this.price,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = summary.videos.where((v) => !v.locked).length;
    final total = summary.videos.length;
    final pct = total == 0 ? 0.0 : unlocked / total;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: isLocked ? AppColors.lockGradient : AppColors.cosmicGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isLocked ? Icons.lock_outline : Icons.lock_open,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isLocked ? 'مادة غير مفعلة' : 'الحصة الحالية',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (isLocked && price != null)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final msg = await ref
                          .read(cartRepositoryProvider)
                          .addToCart(summary.subject.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                    } catch (e) {
                      // handle error
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('شراء المادة ($price ₪)'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLocked
                ? 'شاهد الفيديوهات المجانية الآن'
                : '$unlocked من أصل $total فيديو متاح',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: isLocked ? 0 : pct,
              minHeight: 8,
              color: AppColors.accent,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyQuizBanner extends StatelessWidget {
  final DailyQuiz data;
  const _DailyQuizBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7EF),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFFB9F0DB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF065F46),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                ElevatedButton(
                  onPressed: data.isAvailable ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  child: Text(data.buttonText),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_turned_in_outlined,
                color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final SubjectVideoItem video;
  final bool locked;
  final bool isCompleted;
  final VoidCallback onTap;
  const _VideoTile({
    required this.video,
    required this.locked,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(locked ? 0.7 : 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: locked
                    ? AppColors.lockGradient
                    : (isCompleted
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)])
                        : AppColors.brandGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                locked
                    ? Icons.lock_outline
                    : (isCompleted ? Icons.check_circle : Icons.play_arrow_rounded),
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: locked
                                ? theme.colorScheme.onSurface.withOpacity(0.5)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.done_all,
                            size: 16, color: Color(0xFF10B981)),
                    ],
                  ),
                  if (video.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.duration(video.durationSec),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                          fontWeight: FontWeight.w600,
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
}
