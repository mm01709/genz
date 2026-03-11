// lib/screens/frist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genz/screens/Test_screen.dart';
import 'package:genz/screens/Register_screen.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ─── Responsive breakpoints ──────────────────────────────────────────
    final isTablet  = size.width >= 600;
    final isDesktop = size.width >= 900;

    final hPad = isDesktop ? size.width * 0.25
        : isTablet  ? size.width * 0.15
        : 28.0;

    final logoSize     = isDesktop ? 100.0 : isTablet ? 88.0 : 68.0;
    final titleSize    = isDesktop ?  40.0 : isTablet ? 36.0 : 30.0;
    final subtitleSize = isDesktop ?  17.0 : isTablet ? 15.0 : 13.5;

    final bg        = isDark ? AppColors.darkBg       : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText     : AppColors.lightText;
    final subText   = isDark ? AppColors.darkSubText  : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard     : AppColors.lightSurface;
    final border    = isDark ? AppColors.darkBorder   : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ─── مبني على الـ height المتاحة ─────────────────────────
                final availH = constraints.maxHeight;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availH),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: availH * 0.09),

                            // ─── Logo + Brand ─────────────────────────────
                            GenzLogo(size: logoSize),
                            SizedBox(height: availH * 0.025),
                            Text(
                              AppLocalizations.of(context).translate('app_name'),
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -1.2,
                              ),
                            ),
                            SizedBox(height: availH * 0.012),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('professional_booking'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: subtitleSize,
                                color: subText,
                                height: 1.6,
                              ),
                            ),

                            SizedBox(height: availH * 0.055),

                            // ─── Feature pills ────────────────────────────
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _pill(Icons.camera_indoor_rounded,
                                    AppLocalizations.of(context).translate('studios_count'),
                                    cardColor, border, textColor),
                                _pill(Icons.bolt_rounded,
                                    AppLocalizations.of(context).translate('instant_book'),
                                    cardColor, border, textColor),
                                _pill(Icons.support_agent_rounded,
                                    AppLocalizations.of(context).translate('support_247'),
                                    cardColor, border, textColor),
                              ],
                            ),

                            const Spacer(),

                            // ─── Buttons ──────────────────────────────────
                            GenzButton(
                              text: AppLocalizations.of(context).translate('login'),
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const TestScreen())),
                            ),
                            SizedBox(height: availH * 0.015),
                            GenzButton(
                              text: AppLocalizations.of(context).translate('register'),
                              isOutlined: true,
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                            ),

                            SizedBox(height: availH * 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label,
      Color cardColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor)),
      ]),
    );
  }
}