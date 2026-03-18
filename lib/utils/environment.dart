class Environment {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool isDebug = !isProduction;

  static const String apiTimeout = String.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: '30',
  );

  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  static const int maxRouterProfiles = int.fromEnvironment(
    'MAX_ROUTER_PROFILES',
    defaultValue: 10,
  );

  static const int cacheSize = int.fromEnvironment(
    'CACHE_SIZE',
    defaultValue: 100,
  );

  static Duration get apiTimeoutDuration =>
      Duration(seconds: int.parse(apiTimeout));
}
