import 'dart:async';
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
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    final email = (currentUser['email'] ?? '').trim();
    if (email.isEmpty) return;
    _notifSub = AWSStorageService.subscribeToNotifications(email).listen(
      (notif) {
        if (!mounted) return;
        final exists = appNotifications.any((n) => n['id'] == notif.id);
        if (!exists) {
          appNotifications.add({
            'id': notif.id,
            'clientEmail': notif.clientEmail,
            'title': notif.title ?? '',
            'body': notif.body ?? '',
            'type': notif.type ?? '',
            'time': notif.time ?? '',
            'read': (notif.read ?? false).toString(),
          });
          setState(() {});
        }
      },
      onError: (e) => debugPrint('notifSub error: $e'),
    );
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final loaded = await AWSStorageService.loadNotifications();
    if (loaded.isNotEmpty) {
      for (final n in loaded) {
        if (!appNotifications.any((e) => e['id'] == n['id'])) {
          appNotifications.add(n);
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
    _markAllRead();
  }

  Future<void> _markAllRead() async {
    final myEmail = (currentUser['email'] ?? '').trim();
    final unread = appNotifications
        .where((n) =>
            (n['clientEmail'] ?? '').toLowerCase() == myEmail.toLowerCase() &&
            n['read'] != 'true')
        .toList();
    for (final n in unread) {
      final id = n['id'] ?? '';
      if (id.isEmpty) continue;
      n['read'] = 'true';
      AWSStorageService.markNotificationRead(id);
    }
    if (unread.isNotEmpty && mounted) setState(() {});
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  List<Map<String, String>> get _myNotifications {
    final myEmail = (currentUser['email'] ?? '').trim();
    return appNotifications
        .where((n) =>
            (n['clientEmail'] ?? '').toLowerCase() == myEmail.toLowerCase())
        .toList()
      ..sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
  }

  Map<String, List<Map<String, String>>> _groupByDate(
      List<Map<String, String>> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Map<String, String>>> groups = {};
    for (final n in list) {
      String label;
      try {
        final dt = DateTime.parse(n['time'] ?? '').toLocal();
        final day = DateTime(dt.year, dt.month, dt.day);
        if (day == today) {
          label = 'Today';
        } else if (day == yesterday) {
          label = 'Yesterday';
        } else {
          label = '${dt.day}/${dt.month}/${dt.year}';
        }
      } catch (_) {
        label = 'Earlier';
      }
      groups.putIfAbsent(label, () => []).add(n);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final loc = AppLocalizations.of(context);

    final myNotifs = _myNotifications;
    final unreadCount = myNotifs.where((n) => n['read'] != 'true').length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: [
            Text(
              loc.translate('notifications'),
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 20),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
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
          : myNotifs.isEmpty
              ? _buildEmpty(textColor, subText, loc)
              : _buildList(myNotifs, isDark, textColor, subText),
    );
  }

  Widget _buildEmpty(Color textColor, Color subText, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            loc.translate('no_notifications'),
            style: TextStyle(
                color: textColor, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            loc.translate('no_notifications_sub'),
            style: TextStyle(color: subText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, String>> notifs, bool isDark,
      Color textColor, Color subText) {
    final grouped = _groupByDate(notifs);
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final label = keys[i];
        final items = grouped[label]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                label,
                style: TextStyle(
                    color: subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ),
            ...items.map((n) => _notifCard(n, isDark, textColor, subText)),
          ],
        );
      },
    );
  }

  Widget _notifCard(Map<String, String> notif, bool isDark, Color textColor,
      Color subText) {
    final type = notif['type'] ?? '';
    Color statusColor;
    IconData statusIcon;

    switch (type) {
      case 'Approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'chat_opened':
        statusColor = const Color(0xFF7C3AED);
        statusIcon = Icons.chat_bubble_rounded;
        break;
      case 'Pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.notifications_rounded;
    }

    String timeDisplay = '';
    try {
      final dt = DateTime.parse(notif['time'] ?? '').toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) {
        timeDisplay = 'Just now';
      } else if (diff.inHours < 1) {
        timeDisplay = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeDisplay = '${diff.inHours}h ago';
      } else {
        timeDisplay =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      timeDisplay = notif['time'] ?? '';
    }

    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isUnread = notif['read'] != 'true';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDark
                ? statusColor.withValues(alpha: 0.08)
                : statusColor.withValues(alpha: 0.04))
            : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? statusColor.withValues(alpha: 0.35) : borderColor,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] ?? 'Notification',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          if (isUnread)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 5, top: 3),
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            timeDisplay,
                            style: TextStyle(color: subText, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notif['body'] ?? '',
                    style:
                        TextStyle(color: subText, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.isEmpty ? 'Info' : type.replaceAll('_', ' '),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
