import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connectivity_service.dart';
import '../../core/theme/app_colors.dart';
import '../community/community_list_screen.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';
import 'student_tab.dart';
import 'subjects_screen.dart';

class MainStudentScaffold extends ConsumerWidget {
  const MainStudentScaffold({super.key});

  static const _screens = <Widget>[
    DashboardScreen(),
    SubjectsScreen(),
    CommunityListScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivityServiceProvider);
    final index = ref.watch(selectedStudentTabProvider);
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: index.clamp(0, _screens.length - 1),
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index.clamp(0, _screens.length - 1),
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          ref.read(selectedStudentTabProvider.notifier).state = i;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: AppColors.primary),
            label: 'المواد',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded, color: AppColors.primary),
            label: 'المجتمع',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl_rounded, color: AppColors.primary),
            label: 'أهدافي',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
