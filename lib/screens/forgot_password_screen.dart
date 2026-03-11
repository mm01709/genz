// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:genz/screens/Test_screen.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/services/settings_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();

  int step = 1;
  bool _isLoading = false;
  bool _passVisible = false;

  @override
  void initState() {
    super.initState();
    SettingsService.locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    SettingsService.locale.removeListener(_onLocaleChanged);
    emailCtrl.dispose();
    codeCtrl.dispose();
    newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (emailCtrl.text.trim().isEmpty) {
      _snack(AppLocalizations.of(context).translate('please_enter_email'), AppColors.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Amplify.Auth.resetPassword(username: emailCtrl.text.trim());
      setState(() => step = 2);
      _snack(AppLocalizations.of(context).translate('code_sent'), AppColors.primary);
    } on AuthException catch (e) {
      _snack(e.message, AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (codeCtrl.text.isEmpty || newPassCtrl.text.isEmpty) {
      _snack(AppLocalizations.of(context).translate('fill_all_fields'), AppColors.error);
      return;
    }
    if (newPassCtrl.text.length < 8) {
      _snack(AppLocalizations.of(context).translate('password_min_8_err') ?? 'Password must be at least 8 characters', AppColors.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Amplify.Auth.confirmResetPassword(
        username: emailCtrl.text.trim(),
        newPassword: newPassCtrl.text.trim(),
        confirmationCode: codeCtrl.text.trim(),
      );
      if (!mounted) return;
      _snack(AppLocalizations.of(context).translate('reset_success'), AppColors.success);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const TestScreen()));
    } on AuthException catch (e) {
      _snack(e.message, AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Step indicator
              Row(children: [
                _stepDot(1, step >= 1),
                _stepLine(step >= 2),
                _stepDot(2, step >= 2),
              ]),

              const SizedBox(height: 32),
              const GenzLogo(size: 44),
              const SizedBox(height: 24),

              Text(
                step == 1 ? loc.translate('reset_password_title') : loc.translate('new_password_title'),
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                step == 1
                    ? loc.translate('reset_password_sub')
                    : loc.translate('new_password_sub'),
                style: TextStyle(
                    fontSize: 14, color: subText, height: 1.6),
              ),
              const SizedBox(height: 36),

              if (step == 1) ...[
                GenzTextField(
                  hint: 'your@email.com',
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline_rounded,
                      size: 18, color: AppColors.darkSubText),
                ),
                const SizedBox(height: 28),
                GenzButton(
                  text: loc.translate('send_code_btn'),
                  isLoading: _isLoading,
                  onPressed: _sendCode,
                  icon: Icons.send_rounded,
                ),
              ] else ...[
                GenzTextField(
                  hint: 'Verification Code',
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.tag_rounded,
                      size: 18, color: AppColors.darkSubText),
                ),
                const SizedBox(height: 16),
                GenzTextField(
                  hint: 'New Password',
                  controller: newPassCtrl,
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
                ),
                const SizedBox(height: 28),
                GenzButton(
                  text: loc.translate('reset_password_btn'),
                  isLoading: _isLoading,
                  onPressed: _confirmReset,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendCode,
                    child: Text(loc.translate('resend_code_btn'),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int num, bool active) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
              color: active ? AppColors.primary : AppColors.darkSubText,
              width: 1.5),
        ),
        child: Center(
          child: Text('$num',
              style: TextStyle(
                color: active ? Colors.white : AppColors.darkSubText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              )),
        ),
      );

  Widget _stepLine(bool active) => Expanded(
        child: Container(
          height: 1.5,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: active ? AppColors.primary : AppColors.darkBorder,
        ),
      );
}
