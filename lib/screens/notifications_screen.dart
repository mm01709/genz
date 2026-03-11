import 'package:flutter/material.dart';
import 'package:genz/data/data.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ✅ لو appNotifications فيها بيانات من ClientScreen subscription → استخدمها فوراً
    // مفيش subscription تاني هنا — ClientScreen هو المسؤول
    if (appNotifications.isNotEmpty) {
      _isLoading = false;
    } else {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    await AWSStorageService.loadNotifications();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    // ✅ بيقرأ مباشرة من appNotifications اللي ClientScreen بيحدثها realtime
    final myNotifications = appNotifications
        .where((n) => n['clientEmail'] == currentUser['email'])
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(AppLocalizations.of(context).translate('notifications'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : myNotifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).translate('no_notifications'),
                style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context).translate('no_notifications_sub'),
                style: TextStyle(color: subText, fontSize: 13)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myNotifications.length,
        itemBuilder: (_, i) =>
            _notifCard(myNotifications[i], isDark, textColor, subText),
      ),
    );
  }

  Widget _notifCard(Map<String, String> notif, bool isDark, Color textColor, Color subText) {
    Color statusColor = AppColors.primary;
    IconData statusIcon = Icons.info_outline_rounded;

    if (notif['type'] == 'Approved') {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (notif['type'] == 'Rejected') {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel_outlined;
    }

    String timeDisplay = '';
    try {
      final dt = DateTime.parse(notif['time'] ?? '').toLocal();
      timeDisplay =
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      timeDisplay = notif['time'] ?? '';
    }

    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notif['title'] ?? 'Notification',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(notif['type'] ?? '',
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(notif['body'] ?? '',
                    style: TextStyle(color: subText, fontSize: 13, height: 1.5)),
                const SizedBox(height: 8),
                Text(timeDisplay, style: TextStyle(color: subText, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}