import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/admin/admin_controller.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/admin/admin_shell.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/student/lesson_details_screen.dart';
import 'features/student/downloads_screen.dart';
import 'features/student/main_student_scaffold.dart';
import 'features/teacher/main_teacher_scaffold.dart';
import 'data/models/subject.dart';
import 'data/models/api_enums.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final admin = ref.read(adminControllerProvider);
      final loc = state.matchedLocation;

      if (auth.isLoading || auth.hasError || admin.isLoading) {
        // Hold on the splash screen while the persisted session resolves.
        return loc == '/splash' ? null : '/splash';
      }

      final user = auth.valueOrNull;
      final session = admin.valueOrNull;
      final isAdminPath = loc.startsWith('/admin');
      final isAuthPath = loc == '/welcome' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/profile-setup';

      // Admin routes are mutually exclusive with student/teacher app.
      if (isAdminPath) {
        if (session == null) return '/admin/login';
        return null;
      }

      // User / auth routing
      if (user == null) {
        if (isAuthPath) return null;
        return '/welcome';
      }

      // Only students need to complete their profile (grade/branch selection)
      if (user.role == UserRole.student && user.needsProfile) {
        if (loc == '/profile-setup') return null;
        return '/profile-setup';
      }

      // Authenticated users can access home.
      if (loc == '/profile-setup' ||
          loc == '/welcome' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/splash') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
          path: '/profile-setup', builder: (_, _) => const ProfileSetupScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final user = ref.read(authControllerProvider).valueOrNull;
          if (user?.role == UserRole.teacher) {
            return const MainTeacherScaffold();
          }
          return const MainStudentScaffold();
        },
      ),
      GoRoute(
        path: '/lesson/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          final playlist = extra?['playlist'] as List<SubjectVideoItem>?;
          return LessonDetailsScreen(videoId: id, playlist: playlist);
        },
      ),
      GoRoute(
        path: '/downloads',
        builder: (_, _) => const DownloadsScreen(),
      ),
      GoRoute(
          path: '/admin/login', builder: (_, _) => const AdminLoginScreen()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminShell()),
    ],
  );
});

/// Triggers router refresh whenever auth or admin sessions change.
/// Disposes cleanly when the [WidgetRef] host is torn down.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(adminControllerProvider, (_, _) => notifyListeners());
  }
}
