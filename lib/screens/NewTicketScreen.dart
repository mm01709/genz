// lib/screens/NewTicketScreen.dart
import 'package:flutter/material.dart';
import 'package:genz/data/data.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';

class NewTicketScreen extends StatefulWidget {
  // ✅ Optional pre-filled params (used when opened from BookingDetailScreen or MyTicketsScreen)
  final String? initialSubject;
  final String? initialMessage;
  final int initialCategoryIndex;

  const NewTicketScreen({
    super.key,
    this.initialSubject,
    this.initialMessage,
    this.initialCategoryIndex = 0,
  });

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _messageCtrl;
  bool _isSending = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Payment', 'icon': Icons.payment_rounded},
    {'label': 'Booking', 'icon': Icons.calendar_today_rounded},
    {'label': 'Technical', 'icon': Icons.build_rounded},
    {'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];
  late int _selectedCategory;

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(text: widget.initialSubject ?? '');
    _messageCtrl = TextEditingController(text: widget.initialMessage ?? '');
    _selectedCategory = widget.initialCategoryIndex;
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    final loc = AppLocalizations.of(context);

    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.translate('fill_all_fields')),
          backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isSending = true);

    final ownerEmail = await AWSStorageService.getOwnerEmail();
    if (ownerEmail == null || ownerEmail.isEmpty) {
      setState(() => _isSending = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.translate('error')),
          backgroundColor: AppColors.error));
      return;
    }

    final msg = {
      'senderEmail': ownerEmail,
      'senderName': currentUser['name'] ?? '',
      'clientEmail': ownerEmail,
      'text':
      '[${_categories[_selectedCategory]['label']}] ${_subjectCtrl.text.trim()}\n\n${_messageCtrl.text.trim()}',
      'time': DateTime.now().toIso8601String(),
      'messageType': 'ticket',
    };

    final success = await AWSStorageService.sendMessage(msg);

    // ✅ Fix 5: أبعت إشعار للموظف بعد إرسال التيكت
    if (success) {
      await AWSStorageService.sendNotification(
        clientEmail: AWSStorageService.employeeInboxKey,
        title: 'New Ticket from ${currentUser['name'] ?? 'Client'}',
        body:
        '[${_categories[_selectedCategory]['label']}] ${_subjectCtrl.text.trim()}',
        type: 'new_ticket',
      );
    }

    setState(() => _isSending = false);

    if (!mounted) return;

    final loc2 = AppLocalizations.of(context);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc2.translate('ticket_success')),
          backgroundColor: AppColors.success));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc2.translate('ticket_failed')),
          backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(loc.translate('new_ticket'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Category ──────────────────────────────────────────────────
            _label(loc.translate('category'), subText),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_categories.length, (i) {
                final selected = i == _selectedCategory;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = i),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.12)
                            : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primary : borderColor,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Icon(
                          _categories[i]['icon'] as IconData,
                          size: 20,
                          color: selected ? AppColors.primary : subText,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _categories[i]['label'] as String,
                          style: TextStyle(
                              fontSize: 10,
                              color: selected ? AppColors.primary : subText,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500),
                        ),
                      ]),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ─── Subject ───────────────────────────────────────────────────
            _label(loc.translate('subject'), subText),
            const SizedBox(height: 10),
            TextField(
              controller: _subjectCtrl,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: loc.translate('subject'),
                filled: true,
                fillColor: inputColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Message ───────────────────────────────────────────────────
            _label(loc.translate('message'), subText),
            const SizedBox(height: 10),
            TextField(
              controller: _messageCtrl,
              maxLines: 6,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: loc.translate('message'),
                filled: true,
                fillColor: inputColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),

            const SizedBox(height: 32),

            GenzButton(
              text: loc.translate('submit_ticket'),
              isLoading: _isSending,
              onPressed: _submitTicket,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5));
}