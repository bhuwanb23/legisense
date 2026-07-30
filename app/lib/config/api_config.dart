/// API base URL. Override with `--dart-define=API_BASE_URL=...`
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001',
  );
}
