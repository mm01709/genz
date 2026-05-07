// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:genz/services/settings_service.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/screens/privacy_policy_screen.dart';
import 'package:genz/screens/frist_screen.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final bool isEmployee;
  const SettingsScreen({super.key, this.isEmployee = false});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  Future<void> _logout() async {
    await AWSStorageService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  void _confirmDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText   = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_forever_rounded,
                color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Delete Account',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
          ),
        ]),
        content: Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
          style: TextStyle(color: subText, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    TextStyle(color: subText, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AWSStorageService.deleteAccount();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (_) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Failed to delete account: $e'),
                  backgroundColor: AppColors.error,
                ));
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: SettingsService.locale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: SettingsService.themeMode,
          builder: (context, themeMode, _) {
            final loc    = AppLocalizations.of(context);
            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark);

            final bg          = isDark ? AppColors.darkBg      : AppColors.lightBg;
            final textColor   = isDark ? AppColors.darkText     : AppColors.lightText;
            final subText     = isDark ? AppColors.darkSubText  : AppColors.lightSubText;
            final cardColor   = isDark ? AppColors.darkCard     : AppColors.lightSurface;
            final borderColor = isDark ? AppColors.darkBorder   : AppColors.lightBorder;

            // Responsive: cap content width on wide screens
            final screenW = MediaQuery.of(context).size.width;
            final hPad = screenW > 700 ? (screenW - 600) / 2 : 20.0;

            return Scaffold(
              backgroundColor: bg,
              appBar: AppBar(
                backgroundColor: bg,
                elevation: 0,
                title: Text(loc.translate('settings'),
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w700)),
                iconTheme: IconThemeData(color: textColor),
              ),
              body: Directionality(
                textDirection: locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                  children: [

                    // ─── Language ─────────────────────────────────────
                    _section(loc.translate('language_section'), subText),
                    _card(cardColor, borderColor, Column(children: [
                      _radio('English', 'en', locale.languageCode, textColor,
                          () => SettingsService.updateLocale(const Locale('en'))),
                      Divider(height: 1, color: borderColor),
                      _radio('العربية', 'ar', locale.languageCode, textColor,
                          () => SettingsService.updateLocale(const Locale('ar'))),
                    ])),

                    const SizedBox(height: 28),

                    // ─── Appearance ───────────────────────────────────
                    _section(loc.translate('appearance_section'), subText),
                    _card(cardColor, borderColor, Column(children: [
                      _radioIcon(loc.translate('system_default'),
                          Icons.brightness_auto_rounded,
                          ThemeMode.system, themeMode, textColor,
                          () => SettingsService.updateThemeMode(ThemeMode.system)),
                      Divider(height: 1, color: borderColor),
                      _radioIcon(loc.translate('light_mode'),
                          Icons.light_mode_rounded,
                          ThemeMode.light, themeMode, textColor,
                          () => SettingsService.updateThemeMode(ThemeMode.light)),
                      Divider(height: 1, color: borderColor),
                      _radioIcon(loc.translate('dark_mode'),
                          Icons.dark_mode_rounded,
                          ThemeMode.dark, themeMode, textColor,
                          () => SettingsService.updateThemeMode(ThemeMode.dark)),
                    ])),

                    const SizedBox(height: 28),

                    // ─── Account ──────────────────────────────────────
                    _section('Account', subText),
                    // Logout — standalone card
                    _card(cardColor, borderColor,
                      _actionTile(Icons.logout_rounded,
                          loc.translate('logout'), AppColors.error, _logout)),

                    // Delete Account — separate card below with spacing
                    if (!widget.isEmployee) ...[
                      const SizedBox(height: 12),
                      _card(cardColor, borderColor,
                        _actionTile(Icons.delete_forever_rounded,
                            'Delete Account', AppColors.error, _confirmDelete)),
                    ],

                    const SizedBox(height: 28),

                    // ─── Legal ────────────────────────────────────────
                    _section('Legal', subText),
                    _card(cardColor, borderColor, Column(children: [
                      _navTile(Icons.privacy_tip_rounded, 'Privacy Policy',
                          textColor, subText,
                          () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(initialTab: 0)))),
                      Divider(height: 1, color: borderColor),
                      _navTile(Icons.gavel_rounded, 'Terms of Service',
                          textColor, subText,
                          () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(initialTab: 1)))),
                    ])),

                    const SizedBox(height: 28),

                    // ─── About ────────────────────────────────────────
                    _section(loc.translate('about_section'), subText),
                    _card(cardColor, borderColor, Column(children: [
                      _infoTile(loc.translate('app_name'), 'GENZ Studios',
                          textColor, subText, Icons.camera_alt_rounded),
                      Divider(height: 1, color: borderColor),
                      _infoTile(loc.translate('app_version'), '1.0.0',
                          textColor, subText, Icons.info_outline_rounded),
                    ])),

                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _section(String text, Color color) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.8)),
      );

  Widget _card(Color cardColor, Color borderColor, Widget child) => Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(14), child: child),
      );

  Widget _radio(String label, String value, String groupValue,
      Color textColor, VoidCallback onChanged) {
    return RadioListTile<String>(
      title: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      onChanged: (_) => onChanged(),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _radioIcon(String label, IconData icon, ThemeMode value,
      ThemeMode groupValue, Color textColor, VoidCallback onChanged) {
    return RadioListTile<ThemeMode>(
      title: Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: textColor, fontSize: 14)),
      ]),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      onChanged: (_) => onChanged(),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _navTile(IconData icon, String label, Color textColor,
      Color subText, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, size: 18, color: AppColors.primary),
      title: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
      trailing:
          Icon(Icons.chevron_right_rounded, color: subText, size: 18),
      onTap: onTap,
    );
  }

  Widget _actionTile(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, size: 18, color: color),
      title: Text(label,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _infoTile(String label, String value, Color textColor,
      Color subColor, IconData icon) {
    return ListTile(
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, size: 18, color: AppColors.primary),
      title: Text(label, style: TextStyle(color: subColor, fontSize: 12)),
      trailing: Text(value,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14)),
    );
  }
}
