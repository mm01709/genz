// lib/screens/Register_screen.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:genz/screens/Test_screen.dart';
import 'package:genz/screens/frist_screen.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/services/settings_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _passVisible = false;
  bool _confirmPassVisible = false;
  bool _isLoading = false;

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    SettingsService.locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    SettingsService.locale.removeListener(_onLocaleChanged);
    usernameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await Amplify.Auth.signUp(
        username: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: emailCtrl.text.trim(),
            CognitoUserAttributeKey.name: usernameCtrl.text.trim(),
          },
        ),
      );

      if (!mounted) return;

      if (result.isSignUpComplete) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const TestScreen()));
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ConfirmSignUpScreen(email: emailCtrl.text.trim())),
        );
      }
    } on AuthException catch (e) {
      String errorMsg = e.message;
      if (e.message.contains('UsernameExistsException') ||
          e.message.contains('already exists')) {
        errorMsg = 'An account with this email already exists';
      } else if (e.message.contains('InvalidPasswordException')) {
        errorMsg =
            'Password must have uppercase, lowercase, number & special character';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textColor, size: 20),
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen())),
            ),
          ),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const GenzLogo(size: 44),
                        const SizedBox(height: 28),
                        Text(loc.translate('create_account_title'),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.8,
                            )),
                        const SizedBox(height: 6),
                        Text(loc.translate('join_today'),
                            style: TextStyle(
                                fontSize: 14, color: subText)),
                        const SizedBox(height: 32),

                        _label(loc.translate('full_name'), textColor),
                        const SizedBox(height: 8),
                        GenzTextField(
                          hint: 'John Doe',
                          controller: usernameCtrl,
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              size: 18, color: AppColors.darkSubText),
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? loc.translate('required_field') : null,
                        ),

                        const SizedBox(height: 16),
                        _label(loc.translate('email'), textColor),
                        const SizedBox(height: 8),
                        GenzTextField(
                          hint: 'your@email.com',
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline_rounded,
                              size: 18, color: AppColors.darkSubText),
                          validator: (v) {
                            if (v == null || v.isEmpty) return loc.translate('required_field');
                            if (!v.contains('@')) return loc.translate('invalid_email_msg');
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        _label(loc.translate('password'), textColor),
                        const SizedBox(height: 8),
                        GenzTextField(
                          hint: '••••••••',
                          controller: passCtrl,
                          isPassword: !_passVisible,
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              size: 18, color: AppColors.darkSubText),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.darkSubText,
                            ),
                            onPressed: () =>
                                setState(() => _passVisible = !_passVisible),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return loc.translate('required_field');
                            if (v.length < 8) return loc.translate('min_8_chars');
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        _label(loc.translate('confirm_password'), textColor),
                        const SizedBox(height: 8),
                        GenzTextField(
                          hint: '••••••••',
                          controller: confirmPassCtrl,
                          isPassword: !_confirmPassVisible,
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              size: 18, color: AppColors.darkSubText),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPassVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.darkSubText,
                            ),
                            onPressed: () => setState(
                                () => _confirmPassVisible = !_confirmPassVisible),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return loc.translate('required_field');
                            if (v != passCtrl.text) return loc.translate('passwords_not_match');
                            return null;
                          },
                        ),

                        // Password hint
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 13, color: AppColors.darkSubText),
                          const SizedBox(width: 6),
                          Text(loc.translate('password_hint_info'),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: subText)),
                        ]),

                        const SizedBox(height: 28),
                        GenzButton(
                          text: loc.translate('create_account_title'),
                          isLoading: _isLoading,
                          onPressed: _register,
                          icon: Icons.person_add_alt_1_rounded,
                        ),

                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(loc.translate('already_account'),
                                style: TextStyle(
                                    color: subText, fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const TestScreen())),
                              child: Text(loc.translate('login'),
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2));
}
