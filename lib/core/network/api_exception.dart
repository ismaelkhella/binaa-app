/// Strongly typed exception representing failures from the API layer.
///
/// Use `kind` to branch without parsing error messages.
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

class ApiNetworkException extends ApiException {
  const ApiNetworkException(super.message, {super.statusCode = 0});
}

class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException(super.message, {super.statusCode = 401});
}

class ApiForbiddenException extends ApiException {
  const ApiForbiddenException(super.message, {super.statusCode = 403});
}

class ApiNotFoundException extends ApiException {
  const ApiNotFoundException(super.message, {super.statusCode = 404});
}

class ApiThrottledException extends ApiException {
  const ApiThrottledException(super.message, {super.statusCode = 429});
}

class ApiValidationException extends ApiException {
  /// Class-validator returns an array of strings. We expose the first one.
  const ApiValidationException(super.message, {super.statusCode = 400});
}

class ApiServerException extends ApiException {
  const ApiServerException(super.message, {super.statusCode});
}

class ApiUnknownException extends ApiException {
  const ApiUnknownException(super.message, {super.statusCode});
}
