import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../data/models/community.dart';
import 'community_controller.dart';
import 'chat_screen.dart';

class CommunityListScreen extends ConsumerWidget {
  const CommunityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(communitySubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجتمعات'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(communitySubjectsProvider.future),
        child: subjectsAsync.when(
          data: (subjects) => subjects.isEmpty
              ? _buildEmpty()
              : _buildList(context, subjects),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('خطأ: $err')),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('لا توجد مجتمعات منضمة إليها حالياً'),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<CommunitySubject> subjects) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sub = subjects[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.groups, color: AppColors.primary),
            ),
            title: Text(
              'مجتمع ${sub.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${sub.grade.name} - ${sub.branch.name}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(subjectId: sub.id, subjectName: sub.name),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
