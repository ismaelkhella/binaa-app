import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

export 'api_exception.dart';

/// Builds a configured [Dio] instance.
///
/// Two interceptors are wired in:
///   1. [TokenInterceptor] attaches the bearer JWT when present.
///   2. [AuthInterceptor] handles JWT refreshing.
///   3. [ErrorTranslator] converts raw Dio errors into typed [ApiException]s.
Dio buildApiClient(TokenStorage tokens) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: const {'Content-Type': 'application/json'},
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(TokenInterceptor(tokens));
  dio.interceptors.add(AuthInterceptor(tokens, AppConfig.apiBaseUrl));
  dio.interceptors.add(ErrorTranslator());
  return dio;
}

/// Attaches the access token to outbound requests when available.
class TokenInterceptor extends Interceptor {
  final TokenStorage _tokens;
  TokenInterceptor(this._tokens);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.read();
    if (token != null && token.isNotEmpty) {
      final uri = Uri.tryParse(options.path);
      final isExternal = uri != null && uri.hasScheme && !options.path.contains(AppConfig.apiBaseUrl);
      
      if (!isExternal) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}

/// Converts Dio errors / non-OK responses into the typed [ApiException] family.
class ErrorTranslator extends Interceptor {
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final err = _translate(error);
    handler.reject(
      DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: err,
        message: err.message,
      ),
    );
  }

  ApiException _translate(DioException error) {
    final status = error.response?.statusCode ?? 0;
    final raw = _extractMessage(error.response?.data) ?? error.message ?? 'خطأ غير متوقع';

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiNetworkException('تعذّر الاتصال بالخادم. تأكّد من شبكة الإنترنت.', statusCode: status);
    }

    return switch (status) {
      400 => ApiValidationException(raw, statusCode: status),
      401 => ApiUnauthorizedException(raw, statusCode: status),
      403 => ApiForbiddenException(raw, statusCode: status),
      404 => ApiNotFoundException(raw, statusCode: status),
      429 => ApiThrottledException(raw, statusCode: status),
      _ => ApiServerException(raw, statusCode: status),
    };
  }

  /// API responds with `{ message: string | string[] }`. We pick the first string if array.
  String? _extractMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    return null;
  }
}

/// Convenience extension for repository code: convert any thrown DioException
/// into our typed [ApiException]. Use with [runApiCall].
extension ToApiException on Object {
  ApiException asApiException() {
    if (this is ApiException) return this as ApiException;
    if (this is DioException) {
      final dioErr = this as DioException;
      final wrapped = dioErr.error;
      if (wrapped is ApiException) return wrapped;

      // Fallback: extract info from raw DioException
      final status = dioErr.response?.statusCode;
      final message = _extractFallbackMessage(dioErr);
      return ApiUnknownException(message, statusCode: status);
    }
    return ApiUnknownException(toString());
  }

  String _extractFallbackMessage(DioException error) {
    if (error.response?.data is Map) {
      final data = error.response!.data as Map;
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    return error.message ?? 'خطأ غير متوقع';
  }
}

/// Convenience: run an async block and translate any DioException → ApiException.
Future<T> runApiCall<T>(Future<T> Function() body) async {
  try {
    return await body();
  } catch (e) {
    throw e.asApiException();
  }
}
