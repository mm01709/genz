// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:genz/data/data.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/screens/EditProfileScreen.dart';
import 'package:genz/screens/my_bookings_screen.dart';
import 'package:genz/screens/MyTicketsScreen.dart';
import 'package:genz/screens/chat_screen.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/services/settings_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool? _isChatOn;
  bool _chatLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatStatus();
    SettingsService.locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    SettingsService.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  Future<void> _loadChatStatus() async {
    final email = currentUser['email'] ?? '';
    if (email.isEmpty || currentUser['type'] == 'employee') return;
    if (mounted) setState(() => _chatLoading = true);
    try {
      final enabled = await AWSStorageService.isChatEnabled(email);
      if (mounted) setState(() { _isChatOn = enabled; _chatLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _isChatOn = false; _chatLoading = false; });
    }
  }

  Future<void> _openChat() async {
    final email = currentUser['email'] ?? '';
    if (!mounted) return;
    if (_isChatOn == true) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatScreen(
              targetUser: {'name': 'Support', 'email': email})));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc         = AppLocalizations.of(context);
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isEmployee  = currentUser['type'] == 'employee';
    final isChatOn    = _isChatOn ?? false;
    final bg          = isDark ? AppColors.darkBg      : AppColors.lightBg;
    final textColor   = isDark ? AppColors.darkText     : AppColors.lightText;
    final subText     = isDark ? AppColors.darkSubText  : AppColors.lightSubText;
    final cardColor   = isDark ? AppColors.darkCard     : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder   : AppColors.lightBorder;
    final size        = MediaQuery.of(context).size;
    final hPad        = size.width > 600 ? 40.0 : 20.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(loc.translate('profile_title'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Header gradient banner ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                Stack(children: [
                  CircleAvatar(
                    radius: size.width > 600 ? 60 : 48,
                    backgroundColor: Colors.white24,
                    backgroundImage: _getProfileImage(),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()));
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gradientStart, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: AppColors.primary, size: 14),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(currentUser['name'] ?? 'User',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(currentUser['email'] ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    isEmployee
                        ? '👔 ${loc.translate("employee")}'
                        : '👤 ${loc.translate("client")}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ]),
            ),

            // ─── Stats row (clients only) ────────────────────────────────
            if (!isEmployee) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(children: [
                  _statItem(
                    bookingRequests
                        .where((b) => b['clientEmail'] == currentUser['email'])
                        .length
                        .toString(),
                    loc.translate('bookings_stat'),
                    AppColors.primary,
                    textColor,
                    subText,
                  ),
                  _divider(borderColor),
                  _statItem(
                    bookingRequests
                        .where((b) =>
                    b['clientEmail'] == currentUser['email'] &&
                        b['status'] == 'Approved')
                        .length
                        .toString(),
                    loc.translate('approved'),
                    AppColors.success,
                    textColor,
                    subText,
                  ),
                  _divider(borderColor),
                  _statItem(
                    isChatOn
                        ? loc.translate('active_status')
                        : loc.translate('off_status'),
                    loc.translate('chat_stat'),
                    isChatOn ? AppColors.success : AppColors.darkSubText,
                    textColor,
                    subText,
                  ),
                ]),
              ),
            ] else
              const SizedBox(height: 20),

            // ─── Menu items ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(children: [
                _menuSection(loc.translate('account_section'), subText),
                _menuItem(
                  Icons.edit_rounded,
                  loc.translate('edit_profile'),
                  loc.translate('edit_profile_subtitle'),
                  textColor, subText, cardColor, borderColor,
                      () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()));
                    if (mounted) setState(() {});
                  },
                ),

                if (!isEmployee) ...[
                  const SizedBox(height: 20),
                  _menuSection(loc.translate('bookings_support_section'), subText),
                  _menuItem(
                    Icons.calendar_month_rounded,
                    loc.translate('my_bookings'),
                    loc.translate('my_bookings_subtitle'),
                    textColor, subText, cardColor, borderColor,
                        () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
                  ),
                  _menuItem(
                    Icons.confirmation_number_rounded,
                    loc.translate('open_ticket'),
                    loc.translate('open_ticket_subtitle'),
                    textColor, subText, cardColor, borderColor,
                        () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyTicketsScreen())),
                  ),
                  if (_chatLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary)),
                    )
                  else if (isChatOn)
                    _menuItem(
                      Icons.chat_rounded,
                      loc.translate('live_chat'),
                      loc.translate('live_chat_subtitle'),
                      textColor, subText, cardColor, borderColor,
                      _openChat,
                      accent: AppColors.success,
                    ),
                ],

                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String val, String label, Color valColor,
      Color textColor, Color subText) {
    return Expanded(
      child: Column(children: [
        Text(val, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: valColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: subText)),
      ]),
    );
  }

  Widget _divider(Color color) =>
      Container(width: 1, height: 36, color: color);

  Widget _menuSection(String title, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.5)),
    ),
  );

  Widget _menuItem(IconData icon, String title, String subtitle,
      Color textColor, Color subText, Color cardColor, Color borderColor,
      VoidCallback onTap, {Color? accent}) {
    final c = accent ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: TextStyle(color: subText, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subText),
        ]),
      ),
    );
  }

  ImageProvider _getProfileImage() {
    final p = currentUser['image'] ?? '';
    if (p.isEmpty) {
      final seed = currentUser['email']?.isNotEmpty == true
          ? currentUser['email']!
          : (currentUser['name'] ?? 'user');
      return NetworkImage(getRandomAvatarUrl(seed));
    }
    if (p.startsWith('http')) return NetworkImage(p);
    // ✅ fallback for Web/Windows
    return const AssetImage('images/Gnz.png');
  }
}