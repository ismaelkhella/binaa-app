import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import 'admin_controller.dart';
import 'admin_dashboard_screen.dart';
import 'admin_students_screen.dart';
import 'admin_login_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(adminControllerProvider).valueOrNull;
    if (session == null) {
      // Defensive: routed here without login.
      return const AdminLoginScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'لوحة الإدارة' : 'الطلاب'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          AdminDashboardScreen(),
          AdminStudentsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'الإحصائيات',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
            label: 'الطلاب',
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await ref.read(adminControllerProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }
}
