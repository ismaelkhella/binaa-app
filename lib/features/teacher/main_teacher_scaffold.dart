import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_controller.dart';
import '../community/community_list_screen.dart';
import 'teacher_home_screen.dart';

final teacherTabProvider = StateProvider<int>((ref) => 0);

class MainTeacherScaffold extends ConsumerWidget {
  const MainTeacherScaffold({super.key});

  static const _screens = [
    TeacherHomeScreen(),
    CommunityListScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(teacherTabProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(index == 0 ? 'لوحة المعلم' : 'المجتمعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(teacherTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded, color: AppColors.primary),
            label: 'المجتمعات',
          ),
        ],
      ),
    );
  }
}
