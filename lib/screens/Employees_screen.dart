// lib/screens/Employees_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:amplify_api/amplify_api.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/data/data.dart';
import 'package:genz/models/ModelProvider.dart';
import 'package:genz/screens/BookingDetailScreen.dart';
import 'package:genz/screens/profile_screen.dart';
import 'package:genz/screens/StudioDetailScreen.dart';
import 'package:genz/screens/chat_screen.dart';
import 'package:genz/screens/frist_screen.dart';
import 'package:genz/screens/settings_screen.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/services/settings_service.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Map<String, String>> filteredBookings = [];
  List<Map<String, dynamic>> studios = [];
  final Map<String, bool> _chatEnabledCache = {};
  // ✅ map: clientEmail → clientName (من bookings أو messages)
  final Map<String, String> _clientNameCache = {};
  String currentFilter = 'All';
  int _currentIndex = 0;
  StreamSubscription? _studiosSubscription;
  StreamSubscription? _bookingsSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _employeeNotifsSubscription;
  // ✅ Polling timers للـ Web/Windows
  Timer? _bookingsPollingTimer;
  Timer? _messagesPollingTimer;
  Timer? _notifsPollingTimer;
  Timer? _studiosPollingTimer;
  List<Map<String, String>> _employeeNotifs = [];
  int _unreadNotifsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SettingsService.locale.addListener(_onLocaleChanged);
    _guardAndLoad(); // ✅ لازم Login الأول
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _guardAndLoad() async {
    // ✅ فقط requireSignedIn يرجع للـ WelcomeScreen لو فشل
    try {
      await AWSStorageService.requireSignedIn();
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      return;
    }

    // ✅ باقي الخطوات: أي error لا يوقف التطبيق
    try { await _loadAndFilter(); } catch (_) {}
    try { _listenToStudios(); } catch (_) {}
    try { _listenToBookings(); } catch (_) {}
    try { _listenToMessages(); } catch (_) {}
    try { _listenToEmployeeNotifications(); } catch (_) {}
  }

  // ✅ DataStore شيلناه — كل الـ platforms بتستخدم API polling/subscriptions

  void _listenToStudios() {
    // ✅ Web/Windows/Android: load once then poll every 10s
    _fetchStudiosFromAPI();
    _studiosPollingTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => _fetchStudiosFromAPI(),
    );
  }

  Future<void> _fetchStudiosFromAPI() async {
    try {
      final loaded = await AWSStorageService.loadStudios();
      if (mounted) setState(() => studios = loaded);
    } catch (e) {
      safePrint('fetchStudiosFromAPI error: $e');
    }
  }

  // ✅ الموظف يشوف كل الحجوزات realtime
  void _listenToBookings() {
    // ✅ poll every 5s
    _fetchBookingsFromAPI();
    _bookingsPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _fetchBookingsFromAPI(),
    );
  }

  Future<void> _fetchBookingsFromAPI() async {
    try {
      final response = await Amplify.API.query(
        request: ModelQueries.list(BookingRequest.classType),
      ).response;
      final results =
          response.data?.items.whereType<BookingRequest>().toList() ?? [];
      final mapped = results
          .map((b) => <String, String>{
        'id': b.id,
        'clientEmail': b.clientEmail,
        'clientName': b.clientName ?? '',
        'clientPhone': b.clientPhone ?? '',
        'studio': b.studio,
        'date': b.date,
        'hours': b.hours,
        'price': b.price,
        'equipment': b.equipment ?? '',
        'status': b.status ?? '',
        'fullStartDateTime': b.fullStartDateTime,
        'fullEndDateTime': b.fullEndDateTime,
      })
          .toList();
      _processBookings(mapped);
    } catch (e) {
      safePrint('fetchBookingsFromAPI error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processBookings(List<Map<String, String>> mapped) {
    // ✅ احفظ أسماء العملاء في الـ cache
    for (final b in mapped) {
      final email = b['clientEmail'] ?? '';
      final name = b['clientName'] ?? '';
      if (email.isNotEmpty && name.isNotEmpty) {
        _clientNameCache[email] = name;
      }
    }
    bookingRequests
      ..clear()
      ..addAll(mapped);
    if (mounted) _applyFilter(currentFilter);
  }

  // ✅ الموظف يشوف كل الرسائل realtime — بدون ما يحتاج refresh
  void _listenToMessages() {
    // ✅ poll every 3s
    _fetchMessagesFromAPI();
    _messagesPollingTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _fetchMessagesFromAPI(),
    );
  }

  Future<void> _fetchMessagesFromAPI() async {
    try {
      final response = await Amplify.API.query(
        request: ModelQueries.list(ChatMessage.classType),
      ).response;
      final results =
          response.data?.items.whereType<ChatMessage>().toList() ?? [];
      final mapped = results
          .map((m) => <String, String>{
        'id': m.id,
        'senderName': m.senderName ?? '',
        'senderEmail': m.senderEmail ?? '',
        'clientEmail': m.clientEmail,
        'text': m.text ?? '',
        'time': m.time ?? '',
      })
          .toList();
      _processMessages(mapped);
    } catch (e) {
      safePrint('fetchMessagesFromAPI error: $e');
    }
  }

  void _processMessages(List<Map<String, String>> mapped) {
    mapped.sort((a, b) => a['time']!.compareTo(b['time']!));

    // ✅ استخرج أسماء العملاء من الرسائل اللي بعتوها هم
    for (final m in mapped) {
      final clientEmail = m['clientEmail'] ?? '';
      final senderEmail = m['senderEmail'] ?? '';
      final senderName = m['senderName'] ?? '';
      // لو المرسل هو العميل نفسه (مش الموظف)، احفظ اسمه
      if (clientEmail == senderEmail && senderName.isNotEmpty) {
        _clientNameCache[clientEmail] = senderName;
      }
    }

    appMessages
      ..clear()
      ..addAll(mapped);

    if (mounted) setState(() {});

    // ✅ حمّل حالة الشات لكل العملاء الجدد
    final newEmails = mapped
        .map((m) => m['clientEmail']!)
        .toSet()
        .where((e) => !_chatEnabledCache.containsKey(e))
        .toList();
    if (newEmails.isNotEmpty) _preloadChatStatuses(newEmails);
  }

  // ✅ الموظف يستقبل إشعارات الحجوزات الجديدة realtime
  void _listenToEmployeeNotifications() {
    // ✅ poll every 8s
    _fetchEmployeeNotifsFromAPI();
    _notifsPollingTimer = Timer.periodic(
      const Duration(seconds: 8),
          (_) => _fetchEmployeeNotifsFromAPI(),
    );
  }

  Future<void> _fetchEmployeeNotifsFromAPI() async {
    try {
      final response = await Amplify.API.query(
        request: ModelQueries.list(
          AppNotification.classType,
          where: AppNotification.CLIENTEMAIL
              .eq(AWSStorageService.employeeInboxKey),
        ),
      ).response;
      final results =
          response.data?.items.whereType<AppNotification>().toList() ?? [];
      final mapped = results
          .map((n) => <String, String>{
        'id': n.id,
        'title': n.title ?? '',
        'body': n.body ?? '',
        'type': n.type ?? '',
        'time': n.time ?? '',
      })
          .toList();
      _processEmployeeNotifs(mapped);
    } catch (e) {
      safePrint('fetchEmployeeNotifsFromAPI error: $e');
    }
  }

  void _processEmployeeNotifs(List<Map<String, String>> mapped) {
    mapped.sort((a, b) => b['time']!.compareTo(a['time']!));

    final previousIds = _employeeNotifs.map((n) => n['id']).toSet();
    final newOnes =
    mapped.where((n) => !previousIds.contains(n['id'])).toList();

    _employeeNotifs = mapped;

    if (newOnes.isNotEmpty && previousIds.isNotEmpty) {
      for (final notif in newOnes) {
        _showNewBookingBanner(notif);
      }
    }

    if (mounted) setState(() => _unreadNotifsCount = mapped.length);
  }

  /// بيعرض banner احترافي في أعلى الشاشة لما بييجي حجز جديد
  void _showNewBookingBanner(Map<String, String> notif) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2D45) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(notif['title'] ?? 'New Booking',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(notif['body'] ?? '',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.darkSubText
                              : AppColors.lightSubText,
                          fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                setState(() => _currentIndex = 0);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('View',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }



  // ✅ AWS-only chat enabled
  @override
  void dispose() {
    _studiosSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _employeeNotifsSubscription?.cancel();
    _bookingsPollingTimer?.cancel();
    _messagesPollingTimer?.cancel();
    _notifsPollingTimer?.cancel();
    _studiosPollingTimer?.cancel();
    SettingsService.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  // ✅ يتحمّل حالة الشات لكل العملاء ويحفظها في الـ cache
  Future<void> _preloadChatStatuses(List<String> emails) async {
    for (final email in emails) {
      if (!_chatEnabledCache.containsKey(email)) {
        final enabled = await AWSStorageService.isChatEnabled(email);
        if (mounted) setState(() => _chatEnabledCache[email] = enabled);
      }
    }
  }

  Future<void> _toggleChat(String email, bool current) async {
    final next = !current;
    // ✅ optimistic update — حدّث الـ UI فوراً بدون انتظار AWS
    setState(() => _chatEnabledCache[email] = next);
    await AWSStorageService.enableChatForClient(email, enable: next);
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    _snack(
      next ? loc.translate('chat_enabled') : loc.translate('chat_disabled_msg'),
      next ? AppColors.success : AppColors.warning,
    );
  }

  Future<void> _loadAndFilter() async {
    setState(() => _isLoading = true);
    try {
      await AWSStorageService.requireSignedIn();
      await AWSStorageService.loadCurrentUser();

      final loadedStudios = await AWSStorageService.loadStudios();
      _applyFilter(currentFilter);

      if (!mounted) return;
      setState(() {
        studios = loadedStudios;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      currentFilter = filter;
      filteredBookings = filter == 'All'
          ? List.from(bookingRequests)
          : bookingRequests.where((b) => b['status'] == filter).toList();
    });
  }

  Future<void> _updateStatus(int index, String newStatus) async {
    final booking = filteredBookings[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final loc = AppLocalizations.of(context);

    final msgCtrl = TextEditingController(
      text: newStatus == 'Approved'
          ? loc.translate('booking_approved_msg')
          : loc.translate('booking_rejected_msg'),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${loc.translate('confirm_status')} $newStatus',
          style: TextStyle(color: text, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: msgCtrl,
          maxLines: 3,
          style: TextStyle(color: text),
          decoration: InputDecoration(
            hintText: loc.translate('message_for_client'),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              loc.translate('cancel'),
              style: const TextStyle(color: AppColors.darkSubText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              newStatus == 'Approved' ? AppColors.success : AppColors.error,
            ),
            child: Text(newStatus == 'Approved'
                ? loc.translate('approved')
                : loc.translate('rejected')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = booking['id'] ?? '';
    if (id.isEmpty) return;

    final success = await AWSStorageService.updateBookingStatus(id, newStatus);
    if (!mounted) return;

    if (!success) {
      _snack(loc.translate('failed_update'), AppColors.error);
      return;
    }

    await AWSStorageService.sendNotification(
      clientEmail: booking['clientEmail'] ?? '',
      title: 'Booking $newStatus',
      body: msgCtrl.text,
      type: newStatus,
    );

    setState(() {
      filteredBookings[index]['status'] = newStatus;
      final i = bookingRequests.indexWhere((b) => b['id'] == id);
      if (i != -1) bookingRequests[i]['status'] = newStatus;
    });
  }

  Future<void> _deleteBooking(int index) async {
    final booking = filteredBookings[index];
    final id = booking['id'] ?? '';
    if (id.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.translate('delete_booking'),
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          loc.translate('cannot_undo'),
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
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await AWSStorageService.deleteBooking(id);
    if (!mounted) return;

    if (success) {
      setState(() {
        bookingRequests.remove(booking);
        filteredBookings.removeAt(index);
      });
    }
  }

  Future<void> _deletePermanently(String email) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.translate('delete_all_data'),
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          loc.translate('cannot_undo'),
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
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ✅ حذف الرسايل من AWS DataStore أولاً
    await AWSStorageService.deleteMessagesByClient(email);

    // ✅ اقفل الشات للعميل
    await AWSStorageService.enableChatForClient(email, enable: false);
    _chatEnabledCache[email] = false;

    // ✅ حذف محلي من الـ global state
    appMessages.removeWhere((m) => m['clientEmail'] == email);

    if (!mounted) return;
    setState(() {});
    _snack(loc.translate('delete_all_data'), AppColors.success);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final loc = AppLocalizations.of(context);

    final pending =
        bookingRequests.where((b) => b['status'] == 'Pending').length;
    final approved =
        bookingRequests.where((b) => b['status'] == 'Approved').length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(
            _currentIndex == 0
                ? loc.translate('dashboard')
                : _currentIndex == 1
                ? loc.translate('support_tickets')
                : 'Studios',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
          ),
          actions: [
            // ✅ Bell icon مع badge لإشعارات الحجوزات الجديدة
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_rounded, color: textColor),
                  tooltip: 'Booking Notifications',
                  onPressed: () => _showEmployeeNotifsSheet(isDark),
                ),
                if (_unreadNotifsCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotifsCount > 9 ? '9+' : '$_unreadNotifsCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              onPressed: _loadAndFilter,
            ),
          ],
        ),
        drawer: _buildDrawer(context, isDark),
        body: _currentIndex == 0
            ? (_isLoading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
            : _buildDashboard(isDark, pending, approved))
            : _currentIndex == 1
            ? _buildTicketsView(isDark)
            : (_isLoading
            ? const Center(
            child:
            CircularProgressIndicator(color: AppColors.primary))
            : _buildStudiosView(isDark)),
      ),
    );
  }

  /// Bottom sheet يعرض سجل إشعارات الحجوزات الجديدة
  void _showEmployeeNotifsSheet(bool isDark) {
    setState(() => _unreadNotifsCount = 0); // clear badge
    final bg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ]),
            Text('Booking Notifications',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: _employeeNotifs.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 48,
                        color: subText.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('No booking notifications yet',
                        style: TextStyle(color: subText)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _employeeNotifs.length,
                itemBuilder: (_, i) {
                  final n = _employeeNotifs[i];
                  String timeStr = '';
                  try {
                    final dt = DateTime.parse(n['time'] ?? '').toLocal();
                    timeStr =
                    '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  } catch (_) {
                    timeStr = n['time'] ?? '';
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'] ?? '',
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(n['body'] ?? '',
                                style: TextStyle(
                                    color: subText, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(timeStr,
                                style: TextStyle(
                                    color: subText.withOpacity(0.7),
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isDark, int pending, int approved) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? 24.0 : 16.0;
    final loc = AppLocalizations.of(context);

    final filters = [
      {'key': 'All', 'label': loc.translate('all')},
      {'key': 'Pending', 'label': loc.translate('pending')},
      {'key': 'Approved', 'label': loc.translate('approved')},
      {'key': 'Rejected', 'label': loc.translate('rejected')},
    ];

    return Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
        child: Row(children: [
          _statCard(loc.translate('pending'), pending, AppColors.warning, isDark),
          const SizedBox(width: 10),
          _statCard(
              loc.translate('approved'), approved, AppColors.success, isDark),
          const SizedBox(width: 10),
          _statCard(
              loc.translate('total'), bookingRequests.length, AppColors.primary, isDark),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14),
        child: Row(
          children: filters.map((item) {
            final f = item['key']!;
            final label = item['label']!;
            final sel = currentFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: sel,
                onSelected: (_) => _applyFilter(f),
                selectedColor: AppColors.primary,
                backgroundColor:
                isDark ? AppColors.darkCard : AppColors.lightSurface,
                labelStyle: TextStyle(
                  color: sel
                      ? Colors.white
                      : (isDark ? AppColors.darkText : AppColors.lightText),
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: sel
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
      Expanded(
        child: filteredBookings.isEmpty
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
                child: const Icon(Icons.inbox_rounded,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                loc.translate('no_tickets'),
                style: TextStyle(
                    color: isDark
                        ? AppColors.darkSubText
                        : AppColors.lightSubText),
              ),
            ],
          ),
        )
            : size.width > 700
            ? GridView.builder(
          padding: EdgeInsets.all(hPad),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredBookings.length,
          itemBuilder: (_, i) =>
              _bookingCard(i, filteredBookings[i], isDark),
        )
            : ListView.builder(
          padding: EdgeInsets.all(hPad),
          itemCount: filteredBookings.length,
          itemBuilder: (_, i) =>
              _bookingCard(i, filteredBookings[i], isDark),
        ),
      ),
    ]);
  }

  Widget _statCard(String title, int value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  color:
                  isDark ? AppColors.darkSubText : AppColors.lightSubText)),
        ]),
      ),
    );
  }

  Widget _bookingCard(int index, Map<String, String> booking, bool isDark) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Color statusColor = AppColors.warning;
    if (booking['status'] == 'Approved') statusColor = AppColors.success;
    if (booking['status'] == 'Rejected') statusColor = AppColors.error;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(
            booking: booking,
            index: index,
            onUpdateStatus: _updateStatus,
            onDelete: _deleteBooking,
          ),
        ),
      ).then((_) => _loadAndFilter()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['clientName'] ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: textColor),
                      ),
                      Text(
                        booking['clientEmail'] ?? '',
                        style: TextStyle(fontSize: 11, color: subText),
                      ),
                    ]),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking['status'] ?? '',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 12),
            _infoRow(Icons.camera_indoor_rounded, booking['studio'] ?? '',
                AppColors.primary),
            const SizedBox(height: 6),
            _infoRow(Icons.calendar_today_rounded, booking['date'] ?? '', subText),
            const SizedBox(height: 6),
            _infoRow(Icons.access_time_rounded, booking['hours'] ?? '', subText),
            const SizedBox(height: 6),
            _infoRow(Icons.attach_money_rounded,
                '\$${booking['price'] ?? '0'}', AppColors.success),
            const SizedBox(height: 12),
            Row(children: [
              Text('Tap to view details',
                  style: TextStyle(color: subText, fontSize: 11)),
              const Spacer(),
              _iconBtn(
                Icons.chat_bubble_outline_rounded,
                AppColors.primary,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      targetUser: {
                        'name': booking['clientName'] ?? '',
                        'email': booking['clientEmail'] ?? ''
                      },
                    ),
                  ),
                ),
              ),
              if (booking['status'] == 'Pending') ...[
                _iconBtn(Icons.check_circle_outline_rounded, AppColors.success,
                        () => _updateStatus(index, 'Approved')),
                _iconBtn(Icons.highlight_off_rounded, AppColors.warning,
                        () => _updateStatus(index, 'Rejected')),
              ],
              _iconBtn(Icons.delete_outline_rounded, AppColors.error,
                      () => _deleteBooking(index)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => IconButton(
    icon: Icon(icon, color: color, size: 22),
    onPressed: onTap,
    padding: const EdgeInsets.all(6),
    constraints: const BoxConstraints(),
  );

  Widget _infoRow(IconData icon, String text, Color color) => Row(children: [
    Icon(icon, size: 15, color: color),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ]);

  Widget _buildTicketsView(bool isDark) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final size = MediaQuery.of(context).size;
    final loc = AppLocalizations.of(context);

    final uniqueClients = appMessages.map((m) => m['clientEmail']!).toSet().toList();

    if (uniqueClients.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(loc.translate('no_tickets'), style: TextStyle(color: subText)),
        ]),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(size.width > 600 ? 24 : 16),
      itemCount: uniqueClients.length,
      itemBuilder: (_, i) {
        final email = uniqueClients[i];
        final lastMsg = appMessages.lastWhere(
              (m) => m['clientEmail'] == email,
          orElse: () => {'senderName': 'Unknown', 'text': ''},
        );

        final enabled = _chatEnabledCache[email] ?? false;

        // ✅ جيب اسم العميل: أولاً من cache الحجوزات/الرسائل، وإلا من الـ email
        final clientName = _clientNameCache[email]?.isNotEmpty == true
            ? _clientNameCache[email]!
            : email.split('@').first;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (enabled ? AppColors.success : AppColors.darkSubText)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                enabled ? Icons.chat_rounded : Icons.block_rounded,
                color: enabled ? AppColors.success : AppColors.darkSubText,
                size: 20,
              ),
            ),
            title: Text(
              clientName,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
            subtitle: Text(
              lastMsg['text'] ?? '',
              style: TextStyle(color: subText, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // ✅ الموظف يقدر يفتح المحادثة دايماً حتى لو الشات disabled للعميل
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  targetUser: {
                    'name': clientName,
                    'email': email,
                  },
                ),
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.darkSubText),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              color: cardColor,
              onSelected: (v) async {
                if (v == 'toggle') await _toggleChat(email, enabled);
                if (v == 'delete') await _deletePermanently(email);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                      enabled ? Icons.block_rounded : Icons.check_circle_rounded,
                      color: enabled ? AppColors.warning : AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      enabled
                          ? AppLocalizations.of(context).translate('disable_chat')
                          : AppLocalizations.of(context).translate('enable_chat'),
                      style: TextStyle(color: textColor),
                    ),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_forever_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context).translate('delete_all'),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Studios Management ──────────────────────────────────────────────────

  Future<void> _showAddStudioDialog([Map<String, dynamic>? existing]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddStudioSheet(
          existing: existing,
          onSave: (data) async {
            bool success;
            if (existing != null && existing['id'] != null) {
              success = await AWSStorageService.updateStudio(
                  existing['id'] as String, data);
            } else {
              success = await AWSStorageService.saveStudio(data);
            }

            if (!mounted) return;

            _snack(
              success ? 'Studio saved ✅' : 'Failed. Try again.',
              success ? AppColors.success : AppColors.error,
            );

            if (success) {
              final updated = await AWSStorageService.loadStudios();
              if (!mounted) return;
              setState(() => studios = updated);
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteStudio(String studioId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Studio?',
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.darkSubText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await AWSStorageService.deleteStudio(studioId);
    if (!mounted) return;

    _snack(success ? 'Studio deleted' : 'Failed',
        success ? AppColors.success : AppColors.error);

    if (success) {
      final updated = await AWSStorageService.loadStudios();
      if (!mounted) return;
      setState(() => studios = updated);
    }
  }

  Widget _buildStudiosView(bool isDark) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudioDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Studio',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: studios.isEmpty
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
              child: const Icon(Icons.camera_indoor_rounded,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text('No Studios Yet',
                style: TextStyle(color: subText, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Tap + to add your first studio',
                style:
                TextStyle(color: subText.withOpacity(0.6), fontSize: 13)),
          ],
        ),
      )
          : GridView.builder(
        padding: EdgeInsets.fromLTRB(
          size.width > 600 ? 24 : 16,
          16,
          size.width > 600 ? 24 : 16,
          100,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size.width > 600 ? 3 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemCount: studios.length,
        itemBuilder: (_, i) {
          final s = studios[i];
          final type = s['type'] as String? ?? '';

          final Map<String, Color> typeColors = {
            'Portrait': const Color(0xFF6C63FF),
            'Product': const Color(0xFF22C55E),
            'Wedding': const Color(0xFFEF4444),
            'Video': const Color(0xFF3B82F6),
            'Fashion': const Color(0xFFF59E0B),
          };

          final Map<String, IconData> typeIcons = {
            'Portrait': Icons.portrait_rounded,
            'Product': Icons.inventory_2_rounded,
            'Wedding': Icons.favorite_rounded,
            'Video': Icons.videocam_rounded,
            'Fashion': Icons.style_rounded,
          };

          final accent = typeColors[type] ?? AppColors.primary;
          final icon = typeIcons[type] ?? Icons.camera_alt_rounded;
          final available = s['available'] as bool? ?? true;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StudioDetailScreen(studio: s)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                      ),
                      child: Stack(children: [
                        Center(
                          child: Icon(icon,
                              size: 36,
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '\$${s['pricePerHour']}/hr',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        if (!available)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CLOSED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['name'] as String? ?? '',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(type,
                                style:
                                TextStyle(color: subText, fontSize: 11)),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showAddStudioDialog(s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 7),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.edit_rounded,
                                        color: accent, size: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _deleteStudio(s['id'] as String),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 7),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.delete_rounded,
                                        color: AppColors.error, size: 16),
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                    ),
                  ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final loc = AppLocalizations.of(context);
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final sub = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    ImageProvider getImg() {
      final p = currentUser['image'] ?? '';
      if (p.isEmpty) return const AssetImage('images/Gnz.png');
      if (p.startsWith('http')) return NetworkImage(p);
      // ✅ fallback for Web/Windows
      return const AssetImage('images/Gnz.png');
    }

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(children: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
              if (mounted) setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd]),
              ),
              child: Row(children: [
                CircleAvatar(radius: 28, backgroundImage: getImg()),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentUser['name'] ?? 'Employee',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        Text(currentUser['email'] ?? '',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text('👔 Employee',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                ),
              ]),
            ),
          ),
          Divider(height: 1, color: border),
          const SizedBox(height: 8),
          _dTile(context, Icons.dashboard_rounded, loc.translate('dashboard'),
              text, sub, _currentIndex == 0, () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              }),
          _dTile(
              context,
              Icons.support_agent_rounded,
              loc.translate('support_tickets'),
              text,
              sub,
              _currentIndex == 1, () {
            Navigator.pop(context);
            setState(() => _currentIndex = 1);
          }, iconColor: AppColors.primary),
          _dTile(context, Icons.camera_indoor_rounded, 'Studios', text, sub,
              _currentIndex == 2, () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              }, iconColor: AppColors.success),
          _dTile(context, Icons.settings_rounded, loc.translate('settings'),
              text, sub, false, () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
          const Spacer(),
          Divider(height: 1, color: border),
          _dTile(context, Icons.logout_rounded, loc.translate('logout'),
              AppColors.error, AppColors.error, false, () async {
                await AWSStorageService.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              }, iconColor: AppColors.error),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _dTile(
      BuildContext context,
      IconData icon,
      String label,
      Color textColor,
      Color subColor,
      bool selected,
      VoidCallback onTap, {
        Color? iconColor,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: (iconColor ?? subColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18,
              color: iconColor ?? (selected ? AppColors.primary : subColor)),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : textColor,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─── Add / Edit Studio Full Screen ─────────────────────────────────────────────
class _AddStudioSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _AddStudioSheet({this.existing, required this.onSave});

  @override
  State<_AddStudioSheet> createState() => _AddStudioSheetState();
}

class _AddStudioSheetState extends State<_AddStudioSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'Portrait';
  bool _available = true;
  bool _isSaving = false;
  XFile? _imageFile;
  Uint8List? _imageBytes; // ✅ for display on Web/Windows
  String? _existingImageUrl;

  final _types = ['Portrait', 'Product', 'Wedding', 'Video', 'Fashion'];

  final Map<String, IconData> _typeIcons = {
    'Portrait': Icons.portrait_rounded,
    'Product': Icons.inventory_2_rounded,
    'Wedding': Icons.favorite_rounded,
    'Video': Icons.videocam_rounded,
    'Fashion': Icons.style_rounded,
  };

  final Map<String, Color> _typeColors = {
    'Portrait': const Color(0xFF6C63FF),
    'Product': const Color(0xFF22C55E),
    'Wedding': const Color(0xFFEF4444),
    'Video': const Color(0xFF3B82F6),
    'Fashion': const Color(0xFFF59E0B),
  };

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text = e['name'] ?? '';
      _descCtrl.text = e['description'] ?? '';
      _priceCtrl.text = '${e['pricePerHour'] ?? ''}';
      _selectedType = e['type'] ?? 'Portrait';
      _available = e['available'] ?? true;
      _existingImageUrl = e['image'] as String?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes(); // ✅ يشتغل على كل المنصات
        setState(() {
          _imageFile = picked;
          _imageBytes = bytes;
        });
      }
    } catch (_) {}
  }

  void _showImageSourceSheet() {
    // ✅ على Web/Windows: فتح الـ gallery مباشرة (مفيش camera)
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      _pickImage(ImageSource.gallery);
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary, size: 20),
            ),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary, size: 20),
            ),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          if (_imageBytes != null || (_existingImageUrl?.isNotEmpty == true))
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_rounded,
                    color: AppColors.error, size: 20),
              ),
              title: const Text('Remove Image',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _imageFile = null;
                  _imageBytes = null;
                  _existingImageUrl = null;
                });
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? imageKey; // S3 key (مش URL ولا Base64)

    try {
      if (_imageFile != null) {
        // ✅ في صورة جديدة → ارفع لـ S3
        final bytes = _imageBytes ?? await _imageFile!.readAsBytes();

        // ✅ Validation: الحجم
        if (bytes.length > 5 * 1024 * 1024) {
          // 5 MB max
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large (max 5MB)'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
          return;
        }

        // ✅ Validation: الـ extension
        final ext = (_imageFile!.path.split('.').lastOrNull ?? 'jpg').toLowerCase();
        const validExts = ['jpg', 'jpeg', 'png', 'webp'];
        if (!validExts.contains(ext)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid format. Use JPG, PNG, or WebP'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
          return;
        }

        // ✅ Upload لـ S3
        imageKey = await AWSStorageService.uploadImageBytes(
          bytes: bytes,
          extension: ext,
          prefix: 'studios',
        );

        if (imageKey == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
          return;
        }

        // ✅ لو في صورة قديمة → احذفها من S3 (بس لو مش URL خارجي)
        final oldKey = widget.existing?['imageKey'] as String?;
        if (oldKey != null &&
            oldKey.isNotEmpty &&
            !oldKey.startsWith('http') &&
            !oldKey.startsWith('data:')) {
          await AWSStorageService.deleteS3Image(oldKey);
        }
      } else {
        // ✅ مفيش صورة جديدة → استخدم الـ key القديم (من الـ DB)
        imageKey = widget.existing?['imageKey'] as String?;
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'type': _selectedType,
        'pricePerHour': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'available': _available,
        'image': imageKey ?? '', // ✅ S3 key بس
      };

      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving studio: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final accent = _typeColors[_selectedType] ?? AppColors.primary;
    final icon = _typeIcons[_selectedType] ?? Icons.camera_alt_rounded;
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(isEditing ? 'Edit Studio' : 'New Studio',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w800, fontSize: 18)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _save,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: _imageBytes != null
                      ? Stack(fit: StackFit.expand, children: [
                    Image.memory(_imageBytes!, fit: BoxFit.cover), // ✅ Web/Windows safe
                    _editImageOverlay(),
                  ])
                      : _existingImageUrl?.isNotEmpty == true
                      ? Stack(fit: StackFit.expand, children: [
                    _existingImageUrl!.startsWith('data:')
                        ? Image.memory(
                      base64Decode(
                          _existingImageUrl!.split(',')[1]),
                      fit: BoxFit.cover,
                    )
                        : Image.network(_existingImageUrl!,
                        fit: BoxFit.cover),
                    _editImageOverlay(),
                  ])
                      : _emptyImagePlaceholder(accent, icon, isDark),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Studio Type',
              style: TextStyle(
                color: subText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _types[i];
                  final tAccent = _typeColors[t]!;
                  final tIcon = _typeIcons[t]!;
                  final selected = _selectedType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? tAccent : cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selected ? tAccent : borderColor,
                            width: 1.5),
                        boxShadow: selected
                            ? [
                          BoxShadow(
                            color: tAccent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                            : [],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(tIcon,
                            size: 16,
                            color: selected ? Colors.white : tAccent),
                        const SizedBox(width: 6),
                        Text(
                          t,
                          style: TextStyle(
                            color: selected ? Colors.white : textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _label('Studio Name', subText),
            const SizedBox(height: 8),
            _textField(
              ctrl: _nameCtrl,
              hint: 'e.g. Studio A',
              isDark: isDark,
              inputBg: inputBg,
              borderColor: borderColor,
              textColor: textColor,
              validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            _label('Description', subText),
            const SizedBox(height: 8),
            _textField(
              ctrl: _descCtrl,
              hint: 'Describe the studio, equipment, features...',
              isDark: isDark,
              inputBg: inputBg,
              borderColor: borderColor,
              textColor: textColor,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _label('Price per Hour (\$)', subText),
            const SizedBox(height: 8),
            _textField(
              ctrl: _priceCtrl,
              hint: 'e.g. 150',
              isDark: isDark,
              inputBg: inputBg,
              borderColor: borderColor,
              textColor: textColor,
              keyboard: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_available ? AppColors.success : subText)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _available
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: _available ? AppColors.success : subText,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available for Booking',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        Text(
                          _available
                              ? 'Clients can book this studio'
                              : 'Studio is closed',
                          style: TextStyle(color: subText, fontSize: 12),
                        ),
                      ]),
                ),
                Switch(
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  activeColor: AppColors.success,
                  inactiveThumbColor: subText,
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Preview',
                  style: TextStyle(
                    color: subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameCtrl.text.isEmpty ? 'Studio Name' : _nameCtrl.text,
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                          ),
                          Text(_selectedType,
                              style: TextStyle(color: subText, fontSize: 12)),
                        ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration:
                    BoxDecoration(color: accent, borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      '\$${_priceCtrl.text.isEmpty ? '0' : _priceCtrl.text}/hr',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _emptyImagePlaceholder(Color accent, IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add_photo_alternate_rounded, color: accent, size: 32),
        ),
        const SizedBox(height: 12),
        Text('Add Studio Photo',
            style: TextStyle(
                color: accent, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Tap to upload from camera or gallery',
            style: TextStyle(color: accent.withOpacity(0.6), fontSize: 12)),
      ]),
    );
  }

  Widget _editImageOverlay() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
      ),
    ),
    child: const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.edit_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'Change Photo',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ]),
      ),
    ),
  );

  Widget _label(String text, Color color) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    required bool isDark,
    required Color inputBg,
    required Color borderColor,
    required Color textColor,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
            fontSize: 14,
          ),
          filled: true,
          fillColor: inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}