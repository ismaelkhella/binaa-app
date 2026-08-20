import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_client.dart';

/// Interceptor to handle JWT Refresh Token flow.
/// If a request returns 401, it tries to refresh the token and retry.
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokens;
  final Dio _refreshDio; // Use a separate Dio to avoid loops

  AuthInterceptor(this._tokens, String baseUrl)
      : _refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    // Don't attempt refresh for auth endpoints to avoid infinite loops or
    // attempting refresh when login itself fails.
    if (err.response?.statusCode != 401 ||
        path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.register) ||
        path.contains(ApiEndpoints.refreshToken)) {
      return handler.next(err);
    }

    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) {
      return handler.next(err);
    }

    try {
      final response = await _refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['accessToken']?.toString() ?? '';
      final newRefreshToken = data['refreshToken']?.toString();

      await _tokens.writeStudent(newAccessToken, refreshToken: newRefreshToken);

      // Retry the original request with the new token
      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryDio = Dio(BaseOptions(baseUrl: requestOptions.baseUrl));
      // Add necessary interceptors for retry if needed, or keep it simple
      final retryResponse = await retryDio.fetch(requestOptions);
      return handler.resolve(retryResponse);
    } catch (refreshErr) {
      // If refresh fails, clear tokens and let the UI handle the logout
      await _tokens.clear();
      return handler.next(err);
    }
  }
}
