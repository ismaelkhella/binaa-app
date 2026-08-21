/// Centralized app-level configuration.
///
/// Override the [apiBaseUrl] via `--dart-define=API_BASE_URL=...` at build/run time
/// to point the app at a different backend (e.g. staging, production).
class AppConfig {
  AppConfig._();

  /// Default base URL targets the Android emulator's loopback to localhost.
  /// Override with `flutter run --dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://benaa-academy.org/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String appName = 'Bina Academy';
  static const String appNameAr = 'أكاديمية بناء';
  static const String tagline = 'Tawjihi, Elevated.';
}
