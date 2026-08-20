import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/api_enums.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../providers.dart';

class AuthState {
  final AuthStep step;
  final bool isSubmitting;
  final String? error;

  const AuthState({
    required this.step,
    this.isSubmitting = false,
    this.error,
  });

  AuthState copyWith({
    AuthStep? step,
    bool? isSubmitting,
    Object? error = _undef,
  }) {
    return AuthState(
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error == _undef ? this.error : error as String?,
    );
  }

  static const _undef = Object();
}

enum AuthStep { initial, authenticated }

class AuthController extends AsyncNotifier<User?> {
  late AuthState _form;
  AuthState get form => _form;

  @override
  Future<User?> build() async {
    _form = const AuthState(step: AuthStep.initial);
    final tokens = ref.read(tokenStorageProvider);
    final token = await tokens.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final me = await ref.read(userRepositoryProvider).getMe();
      _form = _form.copyWith(step: AuthStep.authenticated);
      return me.user;
    } on ApiException catch (e) {
      // Token invalid/expired -> clear it
      if (e.statusCode == 401) await tokens.clear();
      return null;
    }
  }

  Future<void> login(String phone, String password) async {
    _form = _form.copyWith(isSubmitting: true, error: null);
    state = AsyncData(state.valueOrNull);
    try {
      final r = await ref.read(authRepositoryProvider).login(phone, password);
      _form = _form.copyWith(
        step: AuthStep.authenticated,
        isSubmitting: false,
      );
      state = AsyncData(r.user);
    } on ApiException catch (e) {
      _form = _form.copyWith(
        isSubmitting: false,
        error: e.message,
      );
      state = AsyncData(state.valueOrNull);
      rethrow;
    }
  }

  Future<void> register({
    required String phone,
    required String password,
    required String name,
    required Grade grade,
    required Branch branch,
  }) async {
    _form = _form.copyWith(isSubmitting: true, error: null);
    state = AsyncData(state.valueOrNull);
    try {
      final r = await ref.read(authRepositoryProvider).register(
            phone: phone,
            password: password,
            name: name,
            grade: grade,
            branch: branch,
          );
      _form = _form.copyWith(
        step: AuthStep.authenticated,
        isSubmitting: false,
      );
      state = AsyncData(r.user);
    } on ApiException catch (e) {
      _form = _form.copyWith(
        isSubmitting: false,
        error: e.message,
      );
      state = AsyncData(state.valueOrNull);
      rethrow;
    }
  }

  Future<void> completeProfile({required Grade grade, required Branch branch}) async {
    _form = _form.copyWith(isSubmitting: true, error: null);
    state = AsyncData(state.valueOrNull);
    try {
      final u = await ref.read(authRepositoryProvider).setupProfile(
            grade: grade,
            branch: branch,
          );
      _form = _form.copyWith(step: AuthStep.authenticated, isSubmitting: false);
      state = AsyncData(u);
    } on ApiException catch (e) {
      _form = _form.copyWith(isSubmitting: false, error: e.message);
      state = AsyncData(state.valueOrNull);
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncLoading();
    try {
      final me = await ref.read(userRepositoryProvider).getMe();
      state = AsyncData(me.user);
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateParentPhone(String phone) async {
    state = const AsyncLoading();
    try {
      await ref.read(userRepositoryProvider).updateParentPhone(phone);
      await refreshUser();
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final refreshToken = await ref.read(tokenStorageProvider).readRefreshToken();
    if (refreshToken != null) {
      try {
        await ref.read(authRepositoryProvider).logout(refreshToken);
      } catch (e) {
        // Silently fail if server logout fails
      }
    }
    await ref.read(tokenStorageProvider).clear();
    _form = const AuthState(step: AuthStep.initial);
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);
