// lib/config/app_config.dart
// ═══════════════════════════════════════════════════════════════════════════════
// AppConfig — Environment-aware configuration
// ─────────────────────────────────────────────────────────────────────────────
// بدل الـ hardcoded values، استخدم --dart-define عند التشغيل:
//
//   flutter run --dart-define=CHATBOT_URL=https://api.example.com
//   flutter build apk --dart-define=CHATBOT_URL=https://api.example.com
//
// ولو ما اتمشيش parameter، بيستخدم الـ default
// ═══════════════════════════════════════════════════════════════════════════════

class AppConfig {
  // ─── Chatbot Server ──────────────────────────────────────────────────────
  /// URL الـ Chatbot. لازم يبقى public URL مش local IP.
  /// عند الـ run/build:
  ///   --dart-define=CHATBOT_URL=https://your-chatbot.example.com
  static const String chatbotServerUrl = String.fromEnvironment(
    'CHATBOT_URL',
    defaultValue: 'https://chatbot.genzstudios.example.com',
  );

  /// Endpoint للشات
  static String get chatbotChatEndpoint => '$chatbotServerUrl/chat';

  /// Endpoint لمسح الـ session memory
  static String get chatbotResetEndpoint => '$chatbotServerUrl/reset';

  /// Timeout لـ requests الشات
  static const Duration chatbotTimeout = Duration(seconds: 30);
  static const Duration chatbotResetTimeout = Duration(seconds: 10);

  // ─── Pagination ──────────────────────────────────────────────────────────
  static const int defaultPageSize = 50;
  static const int largePageSize = 100;
  static const int studiosLimit = 100;

  // ─── Image limits ────────────────────────────────────────────────────────
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // ─── Cache durations ─────────────────────────────────────────────────────
  static const Duration s3UrlExpiry = Duration(hours: 1);

  // ─── Feature flags ───────────────────────────────────────────────────────
  static const bool enableChatbot = bool.fromEnvironment(
    'ENABLE_CHATBOT',
    defaultValue: true,
  );

  static const bool enableNotificationSound = bool.fromEnvironment(
    'ENABLE_NOTIFICATION_SOUND',
    defaultValue: true,
  );

  // ─── Debugging ───────────────────────────────────────────────────────────
  static const bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;

  // ─── Validation ──────────────────────────────────────────────────────────
  /// Validates the config at startup. Call from main().
  static List<String> validate() {
    final issues = <String>[];

    if (chatbotServerUrl.contains('192.168.') ||
        chatbotServerUrl.contains('127.0.0.1') ||
        chatbotServerUrl.contains('localhost')) {
      issues.add(
        '⚠️ CHATBOT_URL is using a local IP. Use --dart-define=CHATBOT_URL=https://your-server.com for production.',
      );
    }

    if (!chatbotServerUrl.startsWith('http')) {
      issues.add('❌ CHATBOT_URL must start with http:// or https://');
    }

    return issues;
  }
}