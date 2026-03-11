import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // ✅ مضاف لـ kIsWeb
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:genz/data/data.dart';
import 'package:genz/models/ModelProvider.dart';
import 'package:genz/amplifyconfiguration.dart';
import 'package:genz/services/settings_service.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/screens/frist_screen.dart';
import 'package:genz/screens/client_screen.dart';
import 'package:genz/screens/Employees_screen.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ StatusBar styling فقط على الموبايل (مش Web/Windows)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  // ✅ Portrait lock فقط على الموبايل (Android/iOS)
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

  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    // ✅ DataStore تم إيقافه بسبب مشكلة Unauthorized على syncChatMessages
    // الـ schema بتستخدم owner-based auth على ChatMessage/BookingRequest/AppNotification
    // وده بيخلي DataStore يفشل كله ويرجع LOCAL_ONLY — فبنستخدم API polling على كل الـ platforms
    final List<AmplifyPluginInterface> plugins = [];

    plugins.add(
      AmplifyAPI(
          options: APIPluginOptions(modelProvider: ModelProvider.instance)),
    );

    plugins.add(AmplifyAuthCognito());
    plugins.add(AmplifyStorageS3());

    await Amplify.addPlugins(plugins);
    await Amplify.configure(amplifyconfig);

    safePrint('✅ Amplify configured successfully (API-only mode)');
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
            );
          },
        );
      },
    );
  }
}

// ─── Splash Screen ─────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _checkUserStatus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkUserStatus() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!mounted) return;

      if (!session.isSignedIn) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()));
        return;
      }

      // ✅ جيب بيانات المستخدم — لو فشل نكمل مش نوقف
      try {
        await AWSStorageService.loadCurrentUser();
      } catch (_) {}

      if (!mounted) return;

      // ✅ حدد هل employee أو client
      // الأولوية: Cognito groups → currentUser['type'] من AWS
      bool isEmployee = false;
      try {
        final cognitoSession = session as CognitoAuthSession;
        final groups =
            cognitoSession.userPoolTokensResult.value.idToken.groups;
        isEmployee = groups.contains('Employee');
      } catch (_) {
        // ✅ Fallback على النوع اللي جبناه من AWS
        isEmployee = currentUser['type'] == 'employee';
        safePrint('⚠️ Using type fallback: ${currentUser['type']}');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          isEmployee ? const EmployeesScreen() : const ClientScreen(),
        ),
      );
    } catch (e) {
      safePrint('Session check error: $e');
      // ✅ لو في error عام → اتحقق من الـ session تاني قبل ما تروح WelcomeScreen
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session.isSignedIn && mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const ClientScreen()));
          return;
        }
      } catch (_) {}

      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GenzLogo(size: 80),
                const SizedBox(height: 20),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ).createShader(bounds),
                  child: const Text(
                    'GENZ Studios',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Professional Studio Booking',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkSubText
                        : AppColors.lightSubText,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}