import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../models/api_enums.dart';
import '../models/user.dart';
import '../models/teacher.dart';

class AuthResult {
  final String accessToken;
  final String? refreshToken;
  final User user;
  final TeacherProfile? teacher;
  const AuthResult({
    required this.accessToken,
    required this.user,
    this.refreshToken,
    this.teacher,
  });
}

class AdminLoginResult {
  final String token;
  final String id;
  final String email;
  final String name;
  const AdminLoginResult({
    required this.token,
    required this.id,
    required this.email,
    required this.name,
  });
}

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokens;

  AuthRepository(this._dio, this._tokens);

  Future<AuthResult> login(String phone, String password) async {
    return runApiCall(() async {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
      );
      final data = (res.data as Map).cast<String, dynamic>();
      
      // Support both 'accessToken' and 'token' for backward compatibility
      final accessToken = (data['accessToken'] ?? data['token'])?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString();
      
      await _tokens.writeStudent(accessToken, refreshToken: refreshToken);
      
      final userData = data['user'] as Map?;
      if (userData == null) {
        throw ApiServerException('فشل استلام بيانات المستخدم من الخادم');
      }

      return AuthResult(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: User.fromJson(userData.cast<String, dynamic>()),
        teacher: data['teacher'] == null
            ? null
            : TeacherProfile.fromJson(
                (data['teacher'] as Map).cast<String, dynamic>()),
      );
    });
  }

  Future<AuthResult> register({
    required String phone,
    required String password,
    required String name,
    required Grade grade,
    required Branch branch,
  }) async {
    return runApiCall(() async {
      final res = await _dio.post(
        ApiEndpoints.register,
        data: {
          'phone': phone,
          'password': password,
          'name': name,
          'grade': grade.toApi(),
          'branch': branch.toApi(),
        },
      );
      final data = (res.data as Map).cast<String, dynamic>();
      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString();
      await _tokens.writeStudent(accessToken, refreshToken: refreshToken);
      return AuthResult(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: User.fromJson((data['user'] as Map).cast<String, dynamic>()),
      );
    });
  }

  Future<User> setupProfile({required Grade grade, required Branch branch}) async {
    return runApiCall(() async {
      final res = await _dio.post(
        ApiEndpoints.setupProfile,
        data: {'grade': grade.toApi(), 'branch': branch.toApi()},
      );
      final data = (res.data as Map).cast<String, dynamic>();
      return User.fromJson((data['user'] as Map).cast<String, dynamic>());
    });
  }

  Future<void> logout(String refreshToken) async {
    return runApiCall(() async {
      await _dio.post(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
      await _tokens.clear();
    });
  }

  Future<AdminLoginResult> adminLogin(String email, String password) async {
    return runApiCall(() async {
      final res = await _dio.post(
        ApiEndpoints.adminLogin,
        data: {'email': email, 'password': password},
      );
      final data = (res.data as Map).cast<String, dynamic>();
      final token = data['token']?.toString() ?? '';
      await _tokens.writeAdmin(token);
      final admin = (data['admin'] as Map).cast<String, dynamic>();
      return AdminLoginResult(
        token: token,
        id: admin['id']?.toString() ?? '',
        email: admin['email']?.toString() ?? '',
        name: admin['name']?.toString() ?? '',
      );
    });
  }
}
