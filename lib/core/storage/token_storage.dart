import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight token + role persistence. We use [SharedPreferences] rather
/// than `flutter_secure_storage` to keep the dependency surface minimal;
/// the JWTs themselves have short lifetimes (7–30 days) so this is acceptable.
class TokenStorage {
  static const _kStudentToken = 'auth.student_token';
  static const _kRefreshToken = 'auth.refresh_token';
  static const _kAdminToken = 'auth.admin_token';
  static const _kRole = 'auth.role';

  final _controller = StreamController<void>.broadcast();

  /// Emits whenever a token changes, so providers can react globally.
  Stream<void> get changes => _controller.stream;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<String?> readToken() async => (await _prefs()).getString(_kStudentToken);
  Future<String?> readRefreshToken() async => (await _prefs()).getString(_kRefreshToken);
  Future<String?> readAdminToken() async =>
      (await _prefs()).getString(_kAdminToken);

  /// Returns the appropriate token for an Administrator session; otherwise falls
  /// back to the student token. The caller knows which to send based on context.
  Future<String?> read() async {
    final prefs = await _prefs();
    final role = prefs.getString(_kRole);
    if (role == 'ADMIN') return prefs.getString(_kAdminToken);
    return prefs.getString(_kStudentToken);
  }

  Future<void> writeStudent(String token, {String? refreshToken}) async {
    final prefs = await _prefs();
    await prefs.setString(_kStudentToken, token);
    if (refreshToken != null) {
      await prefs.setString(_kRefreshToken, refreshToken);
    }
    await prefs.setString(_kRole, 'STUDENT');
    _controller.add(null);
  }

  Future<void> writeAdmin(String token) async {
    final prefs = await _prefs();
    await prefs.setString(_kAdminToken, token);
    await prefs.setString(_kRole, 'ADMIN');
    _controller.add(null);
  }

  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(_kStudentToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kAdminToken);
    await prefs.remove(_kRole);
    _controller.add(null);
  }

  Future<void> dispose() async => _controller.close();
}
