// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:genz/services/settings_service.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: SettingsService.locale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: SettingsService.themeMode,
          builder: (context, themeMode, _) {
            final loc         = AppLocalizations.of(context);
            final isDark      = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
            final bg          = isDark ? AppColors.darkBg       : AppColors.lightBg;
            final textColor   = isDark ? AppColors.darkText      : AppColors.lightText;
            final subText     = isDark ? AppColors.darkSubText   : AppColors.lightSubText;
            final cardColor   = isDark ? AppColors.darkCard      : AppColors.lightSurface;
            final borderColor = isDark ? AppColors.darkBorder    : AppColors.lightBorder;

            return Scaffold(
              backgroundColor: bg,
              appBar: AppBar(
                backgroundColor: bg,
                title: Text(loc.translate('settings'),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                iconTheme: IconThemeData(color: textColor),
              ),
              body: Directionality(
                textDirection: locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ─── Language ────────────────────────────────────────
                    _sectionTitle(loc.translate('language_section'), subText),
                    const SizedBox(height: 10),
                    _settingsCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Column(children: [
                        _radioTile(
                          label: 'English',
                          value: 'en',
                          groupValue: locale.languageCode,
                          textColor: textColor,
                          onChanged: (_) =>
                              SettingsService.updateLocale(const Locale('en')),
                        ),
                        Divider(height: 1, color: borderColor),
                        _radioTile(
                          label: 'العربية',
                          value: 'ar',
                          groupValue: locale.languageCode,
                          textColor: textColor,
                          onChanged: (_) =>
                              SettingsService.updateLocale(const Locale('ar')),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 28),

                    // ─── Appearance ──────────────────────────────────────
                    _sectionTitle(loc.translate('appearance_section'), subText),
                    const SizedBox(height: 10),
                    _settingsCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Column(children: [
                        _radioTile(
                          label: loc.translate('system_default'),
                          icon: Icons.brightness_auto_rounded,
                          value: ThemeMode.system,
                          groupValue: themeMode,
                          textColor: textColor,
                          onChanged: (_) =>
                              SettingsService.updateThemeMode(ThemeMode.system),
                        ),
                        Divider(height: 1, color: borderColor),
                        _radioTile(
                          label: loc.translate('light_mode'),
                          icon: Icons.light_mode_rounded,
                          value: ThemeMode.light,
                          groupValue: themeMode,
                          textColor: textColor,
                          onChanged: (_) =>
                              SettingsService.updateThemeMode(ThemeMode.light),
                        ),
                        Divider(height: 1, color: borderColor),
                        _radioTile(
                          label: loc.translate('dark_mode'),
                          icon: Icons.dark_mode_rounded,
                          value: ThemeMode.dark,
                          groupValue: themeMode,
                          textColor: textColor,
                          onChanged: (_) =>
                              SettingsService.updateThemeMode(ThemeMode.dark),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 28),

                    // ─── About ───────────────────────────────────────────
                    _sectionTitle(loc.translate('about_section'), subText),
                    const SizedBox(height: 10),
                    _settingsCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Column(children: [
                        _infoTile(loc.translate('app_name'), 'GENZ Studios',
                            textColor, subText, Icons.camera_alt_rounded),
                        Divider(height: 1, color: borderColor),
                        _infoTile(loc.translate('app_version'), '1.0.0',
                            textColor, subText, Icons.info_outline_rounded),
                      ]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String text, Color color) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 2),
    child: Text(text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.8)),
  );

  Widget _settingsCard({
    required Widget child,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }

  Widget _radioTile<T>({
    required String label,
    IconData? icon,
    required T value,
    required T groupValue,
    required Color textColor,
    required void Function(T?) onChanged,
  }) {
    return RadioListTile<T>(
      title: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Text(label, style: TextStyle(color: textColor, fontSize: 14)),
      ]),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _infoTile(String label, String value, Color textColor,
      Color subColor, IconData icon) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, size: 18, color: AppColors.primary),
      title: Text(label, style: TextStyle(color: subColor, fontSize: 12)),
      trailing: Text(value,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}