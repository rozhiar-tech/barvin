import 'package:flutter/foundation.dart';

/// Provides build-time environment configuration via `--dart-define`.
class Environment {
  static const String _apiOrigin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: 'http://62.84.176.8:3000',
  );

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// Base origin for all API calls (e.g. `http://host:port`).
  static String get apiOrigin => _apiOrigin;

  /// Base API path (origin + `/api`).
  static String get apiBase => '$_apiOrigin/api';

  /// Current environment name (dev/staging/prod).
  static String get name => _envName;

  static bool get isProduction => _envName.toLowerCase() == 'prod';
  static bool get isStaging => _envName.toLowerCase() == 'staging';
  static bool get isDevelopment => !isProduction && !isStaging;

  static bool get isDebugBuild => kDebugMode;
}
