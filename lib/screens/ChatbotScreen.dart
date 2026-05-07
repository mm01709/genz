// lib/screens/ChatbotScreen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/services/settings_service.dart';

// ⚠️ غيّر هذا العنوان لعنوان سيرفرك الفعلي
const String _kChatbotServerUrl = 'http://3.239.202.67';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // ── كل message بيتخزن بـ role + content زي ما كان ──
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // ── session_id ثابت لكل جهاز ──────────────────────────────────────────────
  // السيرفر بيستخدمه عشان يفصل محادثات المستخدمين المختلفين في الـ memory
  String _sessionId = 'default';

  @override
  void initState() {
    super.initState();
    _initSession();
    _loadMessages();
    SettingsService.locale.addListener(_onLocaleChanged);
  }

  /// جيب الـ session_id المحفوظ أو أنشئ واحد جديد وخزّنه
  Future<void> _initSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('chatbot_session_id');
    if (id == null || id.isEmpty) {
      // UUID بسيط من timestamp + random بدون dependency إضافية
      id = 'sess_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('chatbot_session_id', id);
    }
    setState(() => _sessionId = id!);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SettingsService.locale.removeListener(_onLocaleChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── تحميل الـ local history من SharedPreferences ──────────────────────────
  // ده للعرض فقط — السيرفر عنده الـ history الحقيقية في الـ memory
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('chatbot_history');
    if (saved != null) {
      setState(() {
        _messages = List<Map<String, String>>.from(
            jsonDecode(saved).map((e) => Map<String, String>.from(e)));
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatbot_history', jsonEncode(_messages));
  }

  // ── Clear chat: يمسح الـ local history ويبعت reset للسيرفر ──────────────
  Future<void> _clearChat() async {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.translate('clear_chat_title'),
          style: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.w700),
        ),
        content: Text(
          loc.translate('clear_chat_body'),
          style: TextStyle(
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.translate('cancel'),
                style: const TextStyle(color: AppColors.darkSubText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.translate('clear_btn')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 1) امسح الـ local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chatbot_history');
    setState(() => _messages.clear());

    // 2) أخبر السيرفر يمسح الـ session memory بتاعتك
    try {
      await http
          .post(
            Uri.parse('$_kChatbotServerUrl/reset'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'session_id': _sessionId}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // لو السيرفر مش شغّال، تجاهل — الـ local history اتمسح على أي حال
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  // ── إرسال رسالة للسيرفر ────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // أضف رسالة المستخدم للـ UI فوراً (optimistic update)
    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _isLoading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();
    await _saveMessages();

    try {
      // ── الـ request بيتطابق مع ما يستنى السيرفر بالظبط ──
      // السيرفر endpoint: POST /chat
      // السيرفر يستنى: { "message": "...", "session_id": "..." }
      // السيرفر بيرجع: { "reply": "..." }
      final response = await http
          .post(
            Uri.parse('$_kChatbotServerUrl/chat'), // ← /chat مش /
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': text.trim(), // ← message مش messages
              'session_id': _sessionId, // ← session_id للـ server memory
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['reply'] as String? ?? ''; // ← reply زي ما كان

        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
        });
        _scrollToBottom();
        await _saveMessages();
      } else {
        // أزل رسالة المستخدم من الـ UI لو السيرفر رجع error
        setState(() => _messages.removeLast());
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _messages.removeLast());
      _showError('Connection failed. Check your network.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? 40.0 : 16.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.translate('chatbot_title'),
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text(loc.translate('chatbot_subtitle'),
                style: TextStyle(color: subText, fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded,
                color: _messages.isEmpty ? subText : AppColors.error),
            onPressed: _messages.isEmpty ? null : _clearChat,
            tooltip: 'Clear chat',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                AppColors.gradientStart,
                                AppColors.gradientEnd
                              ]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8))
                              ],
                            ),
                            child: const Icon(Icons.smart_toy_rounded,
                                color: Colors.white, size: 38),
                          ),
                          const SizedBox(height: 20),
                          Text(loc.translate('chatbot_welcome'),
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(loc.translate('chatbot_welcome_sub'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: subText, fontSize: 13, height: 1.6)),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              'Studio prices?',
                              'Available equipment?',
                              'How to book?',
                              'Working hours?',
                            ]
                                .map((q) => GestureDetector(
                                      onTap: () => _sendMessage(q),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: AppColors.primary
                                                  .withOpacity(0.2)),
                                        ),
                                        child: Text(q,
                                            style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ]),
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    return _bubble(msg['content']!, msg['role'] == 'user',
                        isDark, textColor, subText);
                  },
                ),
        ),
        if (_isLoading)
          LinearProgressIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.1),
          ),
        _buildInput(isDark, textColor, subText, hPad),
      ]),
    );
  }

  Widget _bubble(String content, bool isUser, bool isDark, Color textColor,
      Color subText) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd])
              : null,
          color: isUser
              ? null
              : (isDark ? AppColors.darkCard : AppColors.lightSurface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(content,
            style: TextStyle(
                color: isUser ? Colors.white : textColor,
                fontSize: 14,
                height: 1.5)),
      ),
    );
  }

  Widget _buildInput(bool isDark, Color textColor, Color subText, double hPad) {
    final loc = AppLocalizations.of(context);
    final inputBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightBg;

    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 16),
      decoration: BoxDecoration(
        color: surfaceBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _msgCtrl,
              style: TextStyle(color: textColor, fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: loc.translate('chatbot_input_hint'),
                hintStyle: TextStyle(color: subText, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _sendMessage(_msgCtrl.text),
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
                    offset: const Offset(0, 4))
              ],
            ),
            child:
                const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}
