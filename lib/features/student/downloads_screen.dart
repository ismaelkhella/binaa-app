import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../providers.dart';
import '../../data/models/downloaded_video.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  String _searchQuery = '';
  bool _sortByDate = true;

  @override
  Widget build(BuildContext context) {
    final downloadsAsync = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحميلاتي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_sortByDate ? Icons.sort_by_alpha : Icons.date_range),
            onPressed: () => setState(() => _sortByDate = !_sortByDate),
            tooltip: _sortByDate ? 'ترتيب أبجدي' : 'ترتيب حسب التاريخ',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث في التحميلات...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: downloadsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('خطأ: $err')),
              data: (downloads) {
                var filtered = downloads.where((v) =>
                    v.title.contains(_searchQuery) ||
                    v.subHeader.contains(_searchQuery)).toList();
                
                if (_sortByDate) {
                  filtered.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
                } else {
                  filtered.sort((a, b) => a.title.compareTo(b.title));
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_for_offline_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: AppDimensions.md),
                        Text(
                          _searchQuery.isEmpty ? 'لا توجد دروس محملة حالياً' : 'لا توجد نتائج للبحث',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
                  itemBuilder: (context, index) {
                    final video = filtered[index];
                    return _DownloadItem(video: video);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadItem extends ConsumerWidget {
  final DownloadedVideo video;
  const _DownloadItem({required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final manager = ref.watch(downloadManagerProvider);
    final sizeStr = (video.sizeInBytes / (1024 * 1024)).toStringAsFixed(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          context.push('/lesson/${video.videoId}');
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  width: 120,
                  height: 70,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      video.subHeader,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (video.status == 2) ...[
                          Text(
                            '$sizeStr MB',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (video.status == 3)
                          const Text(
                            'فشل التحميل',
                            style: TextStyle(color: AppColors.danger, fontSize: 10),
                          ),
                        if (video.status == 1)
                          StreamBuilder<Map<String, double>>(
                            stream: manager.progressStream,
                            builder: (context, snapshot) {
                              double progress = manager.getProgress(video.videoId) ?? 0.0;
                              if (snapshot.hasData && snapshot.data!.containsKey(video.videoId)) {
                                progress = snapshot.data![video.videoId]!;
                              }
                              
                              final percent = (progress * 100).toInt();
                              return Text(
                                progress <= 0 ? 'جاري البدء...' : 'جاري التحميل... ($percent%)',
                                style: const TextStyle(
                                  color: AppColors.primary, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold
                                ),
                              );
                            },
                          ),
                        if (video.lastPositionSec > 0 && video.status == 2)
                          Text(
                            'متبقي ${Formatters.duration(video.durationSec - video.lastPositionSec)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (video.status == 3)
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: () {
                    context.push('/lesson/${video.videoId}');
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التحميل'),
        content: const Text('هل أنت متأكد من حذف هذا الدرس من جهازك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(videoRepositoryProvider).deleteDownloadedVideo(video.videoId);
      await ref.read(offlineStorageProvider).deleteDownload(video.videoId);
      // Delete file
      if (video.localPath.isNotEmpty) {
        final file = File(video.localPath);
        if (await file.exists()) await file.delete();
      }
      ref.invalidate(downloadsProvider);
    }
  }
}
