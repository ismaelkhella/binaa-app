import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers.dart';

class AdminSession {
  final String id;
  final String email;
  final String name;
  const AdminSession({required this.id, required this.email, required this.name});
}

class AdminController extends AsyncNotifier<AdminSession?> {
  @override
  Future<AdminSession?> build() async {
    // No admin stored data besides the token. The dashboard hits the admin endpoint
    // lazily so we don't pre-fetch here.
    final tokens = ref.read(tokenStorageProvider);
    final stored = await tokens.readAdminToken();
    if (stored == null || stored.isEmpty) return null;
    return const AdminSession(id: '', email: '', name: 'مدير النظام');
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final r = await ref.read(authRepositoryProvider).adminLogin(email, password);
      state = AsyncData(
        AdminSession(id: r.id, email: r.email, name: r.name),
      );
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final adminControllerProvider = AsyncNotifierProvider<AdminController, AdminSession?>(
  AdminController.new,
);
