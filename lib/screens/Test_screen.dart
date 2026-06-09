// lib/screens/Test_screen.dart  (Login Screen)
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:genz/screens/frist_screen.dart';
import 'package:genz/screens/Register_screen.dart';
import 'package:genz/screens/client_screen.dart';
import 'package:genz/screens/Employees_screen.dart';
import 'package:genz/screens/forgot_password_screen.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/data/data.dart';
import 'package:flutter/services.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _passVisible = false;
  String? loginError;

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
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigateByType() async {
    if (!mounted) return;
    if (currentUser['type'] == 'employee') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeesScreen()),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final email = currentUser['email'] ?? '';
    final onboardingDone = prefs.getBool('onboarding_done_${email.toLowerCase()}') ?? false;
    if (!mounted) return;
    if (!onboardingDone) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      if (!mounted) return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ClientScreen()),
    );
  }

  Future<void> performLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      loginError = null;
    });

    try {
      final result = await Amplify.Auth.signIn(
        username: emailController.text.trim(),
        password: passController.text.trim(),
      );

      if (!mounted) return;

      if (result.isSignedIn) {
        await AWSStorageService.loadCurrentUser();
        await AWSStorageService.ensureUserProfileExists(currentUser['email'] ?? '');
        _navigateByType();
      } else if (result.nextStep.signInStep == AuthSignInStep.confirmSignUp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ConfirmSignUpScreen(email: emailController.text.trim()),
          ),
        );
      }
    } on AuthException catch (e) {
      // ✅ لو المستخدم logged in بالفعل (Web issue) → نوجهه مباشرة
      if (e.message.contains('already signed in') ||
          e.message.contains('There is already a user')) {
        try {
          await AWSStorageService.loadCurrentUser();
          if (mounted) _navigateByType();
        } catch (_) {
          if (mounted) setState(() => loginError = _friendlyError(e.message));
        }
      } else {
        setState(() => loginError = _friendlyError(e.message));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String msg) {
    if (msg.contains('Incorrect username or password'))
      return 'Invalid email or password';
    if (msg.contains('User is not confirmed'))
      return 'Please confirm your email first';
    if (msg.contains('User does not exist'))
      return 'No account found with this email';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    // ✅ PopScope يمنع الرجوع للـ Register Screen
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
                        const SizedBox(height: 16),

                        // ─── Header ──────────────────────────────────────────
                        const GenzLogo(size: 44),
                        const SizedBox(height: 28),
                        Text('Welcome back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.8,
                            )),
                        const SizedBox(height: 6),
                        Text('Sign in to your GENZ account',
                            style: TextStyle(
                                fontSize: 14, color: subText, height: 1.5)),

                        const SizedBox(height: 36),

                        // ─── Email ───────────────────────────────────────────
                        _label('Email', textColor),
                        const SizedBox(height: 8),
                        GenzTextField(
                          hint: 'your@email.com',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline_rounded,
                              size: 18, color: AppColors.darkSubText),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // ─── Password ────────────────────────────────────────
                        _label('Password', textColor),
                        const SizedBox(height: 8),
                        GenzTextField(
                          hint: '••••••••',
                          controller: passController,
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
                          validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                        ),

                        // ─── Error ───────────────────────────────────────────
                        if (loginError != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(loginError!,
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 13)),
                              ),
                            ]),
                          ),
                        ],

                        // ─── Forgot Password ─────────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                    const ForgotPasswordScreen())),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ─── Login Button ────────────────────────────────────
                        GenzButton(
                          text: 'Sign In',
                          isLoading: _isLoading,
                          onPressed: performLogin,
                          icon: Icons.login_rounded,
                        ),

                        const SizedBox(height: 32),

                        // ─── Register ────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: TextStyle(
                                    color: subText, fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                              child: const Text('Register',
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

// ─── Confirm SignUp Screen ─────────────────────────────────────────────────────

class ConfirmSignUpScreen extends StatefulWidget {
  final String email;
  const ConfirmSignUpScreen({super.key, required this.email});

  @override
  State<ConfirmSignUpScreen> createState() => _ConfirmSignUpScreenState();
}

class _ConfirmSignUpScreenState extends State<ConfirmSignUpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_code.length < 6) return;
    setState(() => _isLoading = true);
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: widget.email,
        confirmationCode: _code,
      );
      if (result.isSignUpComplete && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account confirmed! Please login ✅'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const TestScreen()));
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      await Amplify.Auth.resendSignUpCode(username: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Verification code resent ✅'),
          backgroundColor: AppColors.primary,
        ));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
      }
    }
  }

  /// ✅ handles paste: fills all 6 boxes if user pastes a 6-digit code
  void _onChanged(String value, int index) {
    // Paste detection: if more than 1 char entered at once
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final nextFocus = (digits.length < 6) ? digits.length : 5;
      _focusNodes[nextFocus].requestFocus();
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final boxColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // ✅ Responsive sizing
    final isTablet = size.width >= 600;
    final hPad = isTablet ? size.width * 0.12 : 28.0;

    // Box size: fit 6 boxes + gaps inside available width
    final availableWidth = size.width - (hPad * 2);
    final boxSize = (availableWidth - (5 * 12)) / 6; // 12px gap between boxes
    final clampedBox = boxSize.clamp(44.0, 68.0);
    final fontSize = clampedBox * 0.42;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, elevation: 0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzLogo(size: 44),
                const SizedBox(height: 28),

                // ── Title ────────────────────────────────────────────
                Text(
                  'Verify Email',
                  style: TextStyle(
                    fontSize: isTablet ? 34 : 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: isTablet ? 15 : 14,
                        color: subText,
                        height: 1.6),
                    children: [
                      const TextSpan(text: 'Code sent to '),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                // ── OTP Boxes ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: clampedBox,
                      height: clampedBox * 1.15,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: false, decimal: false),
                        textInputAction: i < 5
                            ? TextInputAction.next
                            : TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: _controllers[i].text.isNotEmpty
                              ? AppColors.primary.withOpacity(0.08)
                              : boxColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _controllers[i].text.isNotEmpty
                                  ? AppColors.primary.withOpacity(0.5)
                                  : borderColor,
                              width: _controllers[i].text.isNotEmpty ? 1.5 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2.5),
                          ),
                        ),
                        onChanged: (v) => _onChanged(v, i),
                      ),
                    );
                  }),
                ),

                SizedBox(height: size.height * 0.02),

                // ── Progress dots ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = _controllers[i].text.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: filled ? 10 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: filled
                            ? AppColors.primary
                            : borderColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),

                SizedBox(height: size.height * 0.03),

                // ── Resend ────────────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _resendCode,
                    icon: const Icon(Icons.refresh_rounded,
                        size: 16, color: AppColors.primary),
                    label: const Text(
                      'Resend Code',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.04),

                // ── Confirm Button ────────────────────────────────────
                GenzButton(
                  text: 'Confirm Account',
                  isLoading: _isLoading,
                  onPressed:
                  (_isLoading || _code.length < 6) ? null : _confirm,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}