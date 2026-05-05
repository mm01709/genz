// lib/screens/chat_screen.dart
// ═══════════════════════════════════════════════════════════════════════════════
// ChatScreen — v2 (DataStore-free + Real-time chat status)
// ─────────────────────────────────────────────────────────────────────────────
// ✅ تم إصلاح:
//   - الشات بيتقفل فوراً عند العميل لما الموظف يقفله (subscribeToChatStatus)
//   - بدل ما observeChatStatus (DataStore) كانت بترمي errors صامتة
//   - polling أسرع بدون subscription dead loop
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:amplify_api/amplify_api.dart';
import 'package:genz/models/ModelProvider.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/data/data.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, String>? targetUser;
  const ChatScreen({super.key, this.targetUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  StreamSubscription<bool>? _chatSubscription;
  Timer? _pollingTimer;
  Timer? _msgPollingTimer;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = true;
  bool _chatEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkChatAccess();
  }

  Future<void> _checkChatAccess() async {
    // ✅ تأكيد أن currentUser (خصوصاً email) تم تحميله
    if ((currentUser['email'] ?? '').isEmpty) {
      await AWSStorageService.loadCurrentUser();
    }

    final isEmployee = currentUser['type'] == 'employee';

    // 🧑‍💼 الموظف عنده وصول كامل دايماً
    if (isEmployee) {
      if (mounted) {
        setState(() {
          _chatEnabled = true;
          _isLoading = false;
        });
      }
      _setupRealtime();
      return;
    }

    // 👤 العميل — لازم نتحقق من حالة الشات
    final email = (currentUser['email'] ?? '').trim();
    if (email.isEmpty) {
      if (mounted) {
        setState(() {
          _chatEnabled = false;
          _isLoading = false;
        });
      }
      return;
    }

    // ✅ 1) Initial check — قراءة مباشرة من AppSync
    try {
      final initialStatus =
      await AWSStorageService.isChatEnabledOrNull(email);
      if (!mounted) return;
      setState(() {
        // null → نعتبره enabled (default)، false → مغلق، true → مفتوح
        _chatEnabled = initialStatus ?? true;
        _isLoading = false;
      });
      if (_chatEnabled) _setupRealtime();
    } catch (e) {
      safePrint('Chat initial check error: $e');
      if (mounted) {
        setState(() {
          _chatEnabled = true; // Optimistic — نسيب الشات يفتح
          _isLoading = false;
        });
        _setupRealtime();
      }
    }

    // ✅ 2) Real-time AppSync subscription — بدل observeChatStatus القديم
    // الـ subscription بيستقبل أي تغيير على UserProfile لحظياً
    _chatSubscription?.cancel();
    _chatSubscription =
        AWSStorageService.subscribeToChatStatus(email).listen(
              (newStatus) {
            if (!mounted) return;
            if (newStatus == _chatEnabled) return;

            final wasEnabled = _chatEnabled;
            setState(() => _chatEnabled = newStatus);

            if (newStatus && !wasEnabled) {
              // ✅ الموظف فتح الشات → نشغل الـ realtime
              _setupRealtime();
            } else if (!newStatus && wasEnabled) {
              // 🔒 الموظف قفل الشات → نوقف الـ polling فوراً
              _msgPollingTimer?.cancel();
              _msgPollingTimer = null;
            }
          },
          onError: (e) => safePrint('Chat status sub error: $e'),
        );

    // ✅ 3) Polling كـ safety net (كل 8 ثواني — أقل من قبل)
    // الـ subscription فوق هو الـ primary، الـ polling backup للـ network issues
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted) return;
      try {
        final status = await AWSStorageService.isChatEnabledOrNull(email);
        if (status == null) return; // error → نتجاهل
        if (!mounted || status == _chatEnabled) return;

        final wasEnabled = _chatEnabled;
        setState(() => _chatEnabled = status);

        if (status && !wasEnabled) {
          _setupRealtime();
        } else if (!status && wasEnabled) {
          _msgPollingTimer?.cancel();
          _msgPollingTimer = null;
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _msgPollingTimer?.cancel();
    _msgPollingTimer = null;
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _clientEmail {
    final bool isEmployee = currentUser['type'] == 'employee';
    final raw = isEmployee
        ? (widget.targetUser?['email'] ?? '')
        : (currentUser['email'] ?? '');
    return raw.trim();
  }

  void _setupRealtime() {
    // ✅ Initial fetch
    _fetchMessagesFromAPI();

    // ✅ Polling — مش هيعمل تكرار لو تايمر شغال بالفعل
    _msgPollingTimer?.cancel();
    _msgPollingTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted) return;
        // 🛡️ لو الشات اتقفل خلال الـ polling cycle، أوقف
        if (!_chatEnabled && currentUser['type'] != 'employee') {
          _msgPollingTimer?.cancel();
          return;
        }
        _fetchMessagesFromAPI();
      },
    );
  }

  Future<void> _fetchMessagesFromAPI() async {
    try {
      final isEmployee = currentUser['type'] == 'employee';
      final clientEmail = _clientEmail;

      final request = isEmployee && clientEmail.isEmpty
          ? ModelQueries.list(ChatMessage.classType, limit: 1000)
          : ModelQueries.list(
        ChatMessage.classType,
        where: ChatMessage.CLIENTEMAIL.eq(clientEmail),
        limit: 1000,
      );
      final response = await Amplify.API.query(request: request).response;
      final results =
          response.data?.items.whereType<ChatMessage>().toList() ?? [];

      // 🛡️ Extra client-side filter (defensive)
      final filtered = clientEmail.isEmpty
          ? results
          : results
          .where((m) => m.clientEmail == clientEmail)
          .toList();

      final msgs = filtered
          .map((m) => <String, String>{
        'id': m.id,
        'senderName': m.senderName ?? '',
        'senderEmail': m.senderEmail ?? '',
        'clientEmail': m.clientEmail,
        'text': m.text ?? '',
        'time': m.time ?? '',
      })
          .toList();
      msgs.sort((a, b) => a['time']!.compareTo(b['time']!));

      if (!mounted) return;
      final prevLen = _messages.length;
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      if (msgs.length != prevLen) _scrollToBottom();
    } catch (e) {
      safePrint('fetchMessagesFromAPI error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    // 🛡️ منع العميل من إرسال رسائل لو الشات مقفول
    if (!_chatEnabled && currentUser['type'] != 'employee') {
      return;
    }

    final senderEmail =
    (currentUser['email'] ?? '').trim();

    final msg = <String, String>{
      'senderName': currentUser['name'] ?? '',
      'senderEmail': senderEmail,
      'clientEmail': _clientEmail,
      'text': text,
      'time': DateTime.now().toIso8601String(),
      'messageType': 'chat',
    };
    _msgController.clear();
    final ok = await AWSStorageService.sendMessage(msg);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmployee = currentUser['type'] == 'employee';
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmployee
                      ? (widget.targetUser?['name'] ?? 'Client')
                      : AppLocalizations.of(context).translate('support_team'),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor),
                ),
                Text(
                  isEmployee
                      ? (widget.targetUser?['email'] ?? '')
                      : AppLocalizations.of(context).translate('online'),
                  style: TextStyle(
                      fontSize: 11,
                      color: subText,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : !_chatEnabled && currentUser['type'] != 'employee'
          ? _buildChatDisabled(isDark, textColor, subText)
          : Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 28,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                      AppLocalizations.of(context)
                          .translate('no_messages'),
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      AppLocalizations.of(context)
                          .translate('start_conversation'),
                      style: TextStyle(
                          color: subText, fontSize: 13)),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isMe = msg['senderEmail']
                    ?.toLowerCase() ==
                    (currentUser['email'] ?? '').toLowerCase();
                return _bubble(msg, isMe, isDark);
              },
            ),
          ),
          _buildInput(isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildChatDisabled(bool isDark, Color textColor, Color subText) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: AppColors.warning, size: 36),
          ),
          const SizedBox(height: 20),
          Text(loc.translate('chat_disabled'),
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 17),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(loc.translate('live_chat_unavailable'),
              style: TextStyle(color: subText, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 18),
            label: const Text('Go Back',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(Map<String, String> msg, bool isMe, bool isDark) {
    String timeStr = '';
    try {
      final dt = DateTime.parse(msg['time'] ?? '').toLocal();
      timeStr =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd])
              : null,
          color: isMe
              ? null
              : (isDark ? AppColors.darkCard : AppColors.lightSurface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(
              color:
              isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['text']!,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (isDark ? AppColors.darkText : AppColors.lightText),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isMe
                    ? Colors.white.withOpacity(0.55)
                    : AppColors.darkSubText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
              ),
              child: TextField(
                controller: _msgController,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                  AppLocalizations.of(context).translate('type_message'),
                  hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkSubText
                          : AppColors.lightSubText,
                      fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}