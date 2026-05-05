// lib/screens/MyTicketsScreen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:genz/data/data.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/screens/NewTicketScreen.dart';
import 'package:genz/theme/app_theme.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});
  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  StreamSubscription? _sub;
  Timer? _pollingTimer;
  bool _isLoading = true;
  List<_TicketThread> _threads = [];

  @override
  void initState() {
    super.initState();
    _listenToMessages();
  }

  // ✅ DataStore معطل — API polling على كل الـ platforms
  bool get _isNative => false;

  @override
  void dispose() {
    _sub?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _listenToMessages() async {
    var email = currentUser['email'] ?? '';
    if (email.isEmpty) {
      // ✅ لو currentUser لسه ما اتحملش، حمّله الأول
      try { await AWSStorageService.loadCurrentUser(); } catch (_) {}
      email = currentUser['email'] ?? '';
    }
    if (email.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (_isNative) {
      // ✅ Android/iOS: DataStore observe
      _sub = AWSStorageService.observeMessages(email).listen((items) {
        if (!mounted) return;
        if (items.isEmpty) return;
        final msgs = items.map((m) => <String, String>{
          'id': m.id,
          'senderName': m.senderName ?? '',
          'senderEmail': m.senderEmail ?? '',
          'clientEmail': m.clientEmail,
          'text': m.text ?? '',
          'time': m.time ?? '',
        }).toList()..sort((a, b) => a['time']!.compareTo(b['time']!));
        if (mounted) setState(() {
          _threads = _buildThreads(msgs);
          _isLoading = false;
        });
      });
    } else {
      // ✅ Web/Windows: poll every 3s
      _fetchMessagesFromAPI(email);
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 3),
            (_) => _fetchMessagesFromAPI(email),
      );
    }
  }

  Future<void> _fetchMessagesFromAPI(String email) async {
    try {
      // loadMessages without filter: AppSync owner rule returns only current user's messages
      final results = await AWSStorageService.loadMessages(
        clientEmail: await AWSStorageService.getOwnerEmail() ?? email.trim(),
        limit: 1000,
      );
      final msgs = List<Map<String, String>>.from(results);
      msgs.sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));
      if (mounted) setState(() {
        _threads = _buildThreads(msgs);
        _isLoading = false;
      });
    } catch (e) {
      safePrint('fetchMessagesFromAPI (MyTickets) error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_TicketThread> _buildThreads(List<Map<String, String>> msgs) {
    final clientEmail = currentUser['email'] ?? '';
    final clientMsgs   = msgs.where((m) => (m['senderEmail'] ?? '').toLowerCase() == clientEmail.toLowerCase()).toList();
    final employeeMsgs = msgs.where((m) => (m['senderEmail'] ?? '').toLowerCase() != clientEmail.toLowerCase()).toList();

    final threads = clientMsgs.map((ticket) {
      final text = ticket['text'] ?? '';
      final ticketTime = ticket['time'] ?? '';

      // parse [Category] Subject\n\nBody
      String category = 'General', subject = text, body = '';
      final match = RegExp(r'^\[([^\]]+)\]\s*(.+?)(?:\n\n([\s\S]*))?$').firstMatch(text);
      if (match != null) {
        category = match.group(1) ?? 'General';
        subject  = match.group(2) ?? text;
        body     = match.group(3) ?? '';
      }

      final subjectShort = subject.length > 65 ? '${subject.substring(0, 65)}…' : subject;

      // ردود الموظف اللي بعد وقت التيكت
      final replies = employeeMsgs
          .where((r) => (r['time'] ?? '').compareTo(ticketTime) >= 0)
          .toList();

      return _TicketThread(
        id: ticket['id'] ?? '',
        category: category,
        subject: subjectShort,
        body: body,
        time: ticketTime,
        replies: replies,
        clientMessage: ticket,
      );
    }).toList()
      ..sort((a, b) => b.time.compareTo(a.time));

    return threads;
  }

  // ─── helpers ──────────────────────────────────────────────────────────────
  static Color catColor(String c) {
    switch (c.toLowerCase()) {
      case 'payment':   return AppColors.success;
      case 'booking':   return AppColors.primary;
      case 'technical': return AppColors.warning;
      default:          return const Color(0xFF8B5CF6);
    }
  }

  static IconData catIcon(String c) {
    switch (c.toLowerCase()) {
      case 'payment':   return Icons.payment_rounded;
      case 'booking':   return Icons.calendar_today_rounded;
      case 'technical': return Icons.build_rounded;
      default:          return Icons.more_horiz_rounded;
    }
  }

  static String fmtTimeShort(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24)  return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bg          = isDark ? AppColors.darkBg       : AppColors.lightBg;
    final textColor   = isDark ? AppColors.darkText     : AppColors.lightText;
    final subText     = isDark ? AppColors.darkSubText  : AppColors.lightSubText;
    final cardColor   = isDark ? AppColors.darkCard     : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder   : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('My Tickets',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: textColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NewTicketScreen())),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Ticket',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _threads.isEmpty
          ? _buildEmpty(subText)
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _threads.length,
        itemBuilder: (_, i) => _ticketCard(
            context, _threads[i], isDark, textColor, subText,
            cardColor, borderColor),
      ),
    );
  }

  Widget _buildEmpty(Color subText) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.support_agent_rounded, size: 38, color: AppColors.primary),
      ),
      const SizedBox(height: 20),
      Text('No tickets yet',
          style: TextStyle(color: subText, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Tap + to submit your first support ticket',
          style: TextStyle(color: subText.withOpacity(0.7), fontSize: 13)),
    ]),
  );

  Widget _ticketCard(BuildContext context, _TicketThread t, bool isDark,
      Color textColor, Color subText, Color cardColor, Color borderColor) {
    final cc = catColor(t.category);
    final ci = catIcon(t.category);
    final hasReplies = t.replies.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TicketDetailScreen(thread: t))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cc.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: cc.withOpacity(0.2))),
            ),
            child: Row(children: [
              Icon(ci, color: cc, size: 15),
              const SizedBox(width: 6),
              Text(t.category, style: TextStyle(color: cc, fontWeight: FontWeight.w700, fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (hasReplies ? AppColors.success : AppColors.warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(hasReplies ? Icons.reply_rounded : Icons.hourglass_top_rounded,
                      size: 11,
                      color: hasReplies ? AppColors.success : AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    hasReplies
                        ? '${t.replies.length} repl${t.replies.length == 1 ? 'y' : 'ies'}'
                        : 'Pending',
                    style: TextStyle(
                        color: hasReplies ? AppColors.success : AppColors.warning,
                        fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ]),
          ),
          // content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.subject,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              if (t.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(t.body,
                    style: TextStyle(color: subText, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 13, color: subText.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(fmtTimeShort(t.time),
                    style: TextStyle(color: subText.withOpacity(0.7), fontSize: 12)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: subText.withOpacity(0.5)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Thread Model ──────────────────────────────────────────────────────────
class _TicketThread {
  final String id, category, subject, body, time;
  final List<Map<String, String>> replies;
  final Map<String, String> clientMessage;

  const _TicketThread({
    required this.id, required this.category, required this.subject,
    required this.body, required this.time, required this.replies,
    required this.clientMessage,
  });
}

// ─── Ticket Detail Screen ──────────────────────────────────────────────────
class TicketDetailScreen extends StatelessWidget {
  final _TicketThread thread;
  const TicketDetailScreen({super.key, required this.thread});

  static Color catColor(String c) {
    switch (c.toLowerCase()) {
      case 'payment':   return AppColors.success;
      case 'booking':   return AppColors.primary;
      case 'technical': return AppColors.warning;
      default:          return const Color(0xFF8B5CF6);
    }
  }

  static IconData catIcon(String c) {
    switch (c.toLowerCase()) {
      case 'payment':   return Icons.payment_rounded;
      case 'booking':   return Icons.calendar_today_rounded;
      case 'technical': return Icons.build_rounded;
      default:          return Icons.more_horiz_rounded;
    }
  }

  static int categoryIndex(String c) {
    switch (c.toLowerCase()) {
      case 'payment':   return 0;
      case 'booking':   return 1;
      case 'technical': return 2;
      default:          return 3;
    }
  }

  static String fmtTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bg          = isDark ? AppColors.darkBg      : AppColors.lightBg;
    final textColor   = isDark ? AppColors.darkText    : AppColors.lightText;
    final subText     = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor   = isDark ? AppColors.darkCard    : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final cc = catColor(thread.category);
    final ci = catIcon(thread.category);
    final clientEmail = currentUser['email'] ?? '';
    final hasReplies = thread.replies.isNotEmpty;

    // كل الرسائل مرتبة بالوقت
    final allMsgs = [thread.clientMessage, ...thread.replies]
      ..sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Ticket Detail',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cc.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cc.withOpacity(0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: cc.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(ci, color: cc, size: 20),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: cc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(thread.category,
                    style: TextStyle(color: cc, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (hasReplies ? AppColors.success : AppColors.warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasReplies ? 'Replied' : 'Pending',
                  style: TextStyle(
                      color: hasReplies ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(thread.subject,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(fmtTime(thread.time),
                style: TextStyle(color: subText.withOpacity(0.7), fontSize: 12)),
          ]),
        ),

        // ── Message thread ───────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allMsgs.length,
            itemBuilder: (ctx, i) {
              final msg = allMsgs[i];
              final isClient = msg['senderEmail'] == clientEmail;
              final rawText = msg['text'] ?? '';
              // اعرض الـ body فقط (بعد \n\n) في الـ bubble
              final displayText = rawText.contains('\n\n')
                  ? rawText.split('\n\n').skip(1).join('\n\n').trim()
                  : rawText;

              final bubbleBg = isClient
                  ? AppColors.primary.withOpacity(0.1)
                  : (isDark ? AppColors.darkSurface : Colors.white);
              final bubbleBorder = isClient
                  ? AppColors.primary.withOpacity(0.25)
                  : borderColor;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: isClient
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: isClient
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isClient) ...[
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.support_agent_rounded,
                                size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(ctx).size.width * 0.72),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: bubbleBg,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isClient ? 16 : 4),
                                bottomRight: Radius.circular(isClient ? 4 : 16),
                              ),
                              border: Border.all(color: bubbleBorder),
                            ),
                            child: Text(
                              displayText.isNotEmpty ? displayText : rawText,
                              style: TextStyle(color: textColor, fontSize: 14),
                            ),
                          ),
                        ),
                        if (isClient) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.person_rounded,
                                size: 16, color: AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: 4,
                          left: isClient ? 0 : 40,
                          right: isClient ? 40 : 0),
                      child: Text(fmtTime(msg['time'] ?? ''),
                          style: TextStyle(
                              color: subText.withOpacity(0.6), fontSize: 10)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Follow-up button ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewTicketScreen(
                      initialSubject: 'Follow-up: ${thread.subject}',
                      initialCategoryIndex: categoryIndex(thread.category),
                    ),
                  ),
                ),
                icon: const Icon(Icons.reply_rounded, size: 18),
                label: const Text('Send Follow-up',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}