// lib/main.dart
// ═══════════════════════════════════════════════════════════════════════════════
// Main — مع Provider integration
// ─────────────────────────────────────────────────────────────────────────────
// ✅ MultiProvider في الـ root
// ✅ ChangeNotifierProvider للـ AppState
// ✅ كل الـ children بيقدروا يـ context.watch<AppState>()
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'package:genz/models/ModelProvider.dart';
import 'package:genz/amplifyconfiguration.dart';
import 'package:genz/services/settings_service.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/screens/frist_screen.dart';
import 'package:genz/screens/client_screen.dart';
import 'package:genz/screens/Employees_screen.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/providers/app_state.dart';
import 'package:genz/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Status bar styling — موبايل بس
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  // ✅ Portrait lock — موبايل بس
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await SettingsService.loadSettings();
  await _configureAmplify();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _configureAmplify() async {
  try {
    // ⚠️ DataStore disabled — owner-auth schema بيرفض syncBookingRequests/syncChatMessages/etc
    // الكود بيستخدم Amplify.API.query/mutate مباشرة + polling timers بدلاً منها
    final List<AmplifyPluginInterface> plugins = [
      AmplifyAPI(
        options: APIPluginOptions(modelProvider: ModelProvider.instance),
      ),
      AmplifyAuthCognito(),
      AmplifyStorageS3(),
    ];

    await Amplify.addPlugins(plugins);
    await Amplify.configure(amplifyconfig);

    safePrint('✅ Amplify configured successfully');
  } catch (e) {
    safePrint('❌ Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: SettingsService.locale,
          builder: (context, locale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'GENZ Studios',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const SplashScreen(),
              builder: (context, child) {
                // ✅ Responsive: كل الـ screens محدود الـ textScale
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: TextScaler.linear(
                      mq.textScaler.scale(1).clamp(0.85, 1.2),
                    ),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SplashScreen — مع AppState population
// ═══════════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // wait one frame عشان الـ context يكون جاهز
    await Future.delayed(const Duration(milliseconds: 300));

    final state = context.read<AppState>();

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
        return;
      }

      // ✅ Load user data
      await AWSStorageService.loadCurrentUser();

      // ✅ Populate AppState
      state.setUser(
        email: AWSStorageService.currentUser['email'] ?? '',
        name: AWSStorageService.currentUser['name'] ?? '',
        type: AWSStorageService.currentUser['type'] ?? 'client',
        image: AWSStorageService.currentUser['image'],
        chatEnabled:
        AWSStorageService.currentUser['chatEnabled'] != 'false',
      );

      if (!mounted) return;

      // ✅ Route based on user type
      if (state.isEmployee) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeesScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientScreen()),
        );
      }
    } catch (e) {
      safePrint('Bootstrap error: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'GENZ Studios',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}