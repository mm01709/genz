// lib/screens/Employees_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb, Uint8List
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:amplify_api/amplify_api.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/data/data.dart';
import 'package:genz/models/ModelProvider.dart';
import 'package:genz/screens/BookingDetailScreen.dart';
import 'package:genz/screens/profile_screen.dart';
import 'package:genz/screens/ReportsScreen.dart';
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
  int _dashboardTab = 0; // 0=Today 1=Week 2=Month
  // selected dates per tab — default to now
  DateTime _selectedDay   = DateTime.now();
  DateTime _selectedWeek  = DateTime.now(); // any day in the week
  DateTime _selectedMonth = DateTime.now();
  // archive
  String _archiveFilter = 'All';
  bool _showArchiveSection = false;

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
    // No immediate fetch — _loadAndFilter already loaded studios on startup
    // Poll every 90s since studios change rarely
    _studiosPollingTimer = Timer.periodic(
      const Duration(seconds: 90),
          (_) => _fetchStudiosFromAPI(),
    );
  }

  Future<void> _fetchStudiosFromAPI() async {
    try {
      final loaded = await AWSStorageService.loadStudios();
      if (!mounted) return;
      // Only rebuild if data actually changed
      final ids = studios.map((s) => s['id']).toSet();
      final newIds = loaded.map((s) => s['id']).toSet();
      final changed = ids.length != newIds.length ||
          ids.any((id) => !newIds.contains(id)) ||
          loaded.any((s) {
            final old = studios.firstWhere((o) => o['id'] == s['id'],
                orElse: () => {});
            return old.isEmpty ||
                old['name'] != s['name'] ||
                old['available'] != s['available'] ||
                old['image'] != s['image'] ||
                old['pricePerHour'] != s['pricePerHour'];
          });
      if (changed) setState(() => studios = loaded);
    } catch (e) {
      safePrint('fetchStudiosFromAPI error: $e');
    }
  }

  void _listenToBookings() {
    _fetchBookingsFromAPI();
    _bookingsPollingTimer = Timer.periodic(
      const Duration(seconds: 8),
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
    for (final b in mapped) {
      final email = b['clientEmail'] ?? '';
      final name = b['clientName'] ?? '';
      if (email.isNotEmpty && name.isNotEmpty) {
        _clientNameCache[email] = name;
      }
    }

    // Only rebuild if something actually changed
    if (!_bookingsChanged(bookingRequests, mapped)) return;

    bookingRequests
      ..clear()
      ..addAll(mapped);
    if (mounted) _applyFilter(currentFilter);
  }

  bool _bookingsChanged(
      List<Map<String, String>> old, List<Map<String, String>> next) {
    if (old.length != next.length) return true;
    for (int i = 0; i < old.length; i++) {
      final o = old[i]; final n = next[i];
      if (o['id']     != n['id']     ||
          o['status'] != n['status'] ||
          o['studio'] != n['studio'] ||
          o['fullStartDateTime'] != n['fullStartDateTime']) return true;
    }
    return false;
  }

  // ✅ الموظف يشوف كل الرسائل realtime — بدون ما يحتاج refresh
  void _listenToMessages() {
    _fetchMessagesFromAPI();
    _messagesPollingTimer = Timer.periodic(
      const Duration(seconds: 10),
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

    // Only rebuild if messages changed
    final changed = appMessages.length != mapped.length ||
        mapped.any((m) {
          final old = appMessages.firstWhere(
              (o) => o['id'] == m['id'], orElse: () => {});
          return old.isEmpty || old['text'] != m['text'];
        });

    appMessages
      ..clear()
      ..addAll(mapped);

    if (mounted && changed) setState(() {});

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
    _fetchEmployeeNotifsFromAPI();
    _notifsPollingTimer = Timer.periodic(
      const Duration(seconds: 15),
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
        'read': (n.read ?? false).toString(),
      })
          .toList();
      _processEmployeeNotifs(mapped);
    } catch (e) {
      safePrint('fetchEmployeeNotifsFromAPI error: $e');
    }
  }

  void _processEmployeeNotifs(List<Map<String, String>> mapped) {
    mapped.sort((a, b) => b['time']!.compareTo(a['time']!));

    // الإشعارات اللي الموظف شافها محلياً — نحافظ على حالة read=true
    for (final incoming in mapped) {
      final existing = _employeeNotifs.firstWhere(
        (e) => e['id'] == incoming['id'],
        orElse: () => {},
      );
      if (existing.isNotEmpty && existing['read'] == 'true') {
        incoming['read'] = 'true';
      }
    }

    final previousIds = _employeeNotifs.map((n) => n['id']).toSet();
    final newOnes = mapped
        .where((n) => !previousIds.contains(n['id']) && n['read'] != 'true')
        .toList();

    _employeeNotifs = mapped;

    if (newOnes.isNotEmpty && previousIds.isNotEmpty) {
      for (final notif in newOnes) {
        _showNewBookingBanner(notif);
      }
    }

    final unread = mapped.where((n) => n['read'] != 'true').length;
    // Only rebuild if unread count actually changed
    if (mounted && unread != _unreadNotifsCount) {
      setState(() => _unreadNotifsCount = unread);
    }
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
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
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
                color: AppColors.primary.withValues(alpha: 0.12),
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
    if (next) {
      await AWSStorageService.sendNotification(
        clientEmail: email,
        title: 'Chat Opened',
        body: 'The support team has opened chat for you. You can now send messages.',
        type: 'chat_opened',
      );
    }
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

  // A booking is "archived" when its end time has passed OR its status is Done.
  bool _isArchived(Map<String, String> b) {
    final status = b['status'] ?? '';
    if (status == 'Done') return true;
    final end = DateTime.tryParse(b['fullEndDateTime'] ?? b['fullStartDateTime'] ?? '');
    if (end == null) return false;
    return end.isBefore(DateTime.now());
  }

  List<Map<String, String>> get _activeBookings =>
      bookingRequests.where((b) => !_isArchived(b)).toList();

  List<Map<String, String>> get _archivedBookings =>
      bookingRequests.where(_isArchived).toList()
        ..sort((a, b) {
          final da = DateTime.tryParse(a['fullStartDateTime'] ?? '') ?? DateTime(0);
          final db = DateTime.tryParse(b['fullStartDateTime'] ?? '') ?? DateTime(0);
          return db.compareTo(da); // newest first
        });

  void _applyFilter(String filter) {
    setState(() {
      currentFilter = filter;
      final source = _activeBookings;
      filteredBookings = filter == 'All'
          ? List.from(source)
          : source.where((b) => b['status'] == filter).toList();
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
      // re-apply filter so the card moves to archive if needed
      _applyFilter(currentFilter);
    });
  }

  Future<void> _markAsDone(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Mark as Done',
              style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontWeight: FontWeight.w700)),
          content: Text(
              'Confirm that this booking session is fully completed.',
              style: TextStyle(
                  color: isDark ? AppColors.darkSubText : AppColors.lightSubText)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.darkSubText))),
            ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success)),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final ok = await AWSStorageService.updateBookingStatus(bookingId, 'Done');
    if (!mounted) return;
    if (!ok) {
      _snack('Failed to update status', AppColors.error);
      return;
    }
    setState(() {
      final i = bookingRequests.indexWhere((b) => b['id'] == bookingId);
      if (i != -1) bookingRequests[i]['status'] = 'Done';
      _applyFilter(currentFilter);
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
        body: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          if (isWide) {
            // ── Wide layout: persistent side nav + content ──────────────
            return Row(children: [
              // Side nav panel
              Container(
                width: 220,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border(right: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: SafeArea(
                  child: Column(children: [
                    const SizedBox(height: 16),
                    _sideNavItem(Icons.dashboard_rounded,    loc.translate('dashboard'),       0, isDark),
                    _sideNavItem(Icons.support_agent_rounded, loc.translate('support_tickets'), 1, isDark),
                    _sideNavItem(Icons.camera_indoor_rounded, 'Studios',                        2, isDark),
                    const Spacer(),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _sideNavItem(Icons.bar_chart_rounded, 'Reports', -1, isDark,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),

              // Main content
              Expanded(
                child: _currentIndex == 0
                    ? (_isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _buildDashboard(isDark, pending, approved))
                    : _currentIndex == 1
                    ? _buildTicketsView(isDark)
                    : (_isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _buildStudiosView(isDark)),
              ),
            ]);
          }

          // ── Narrow layout: standard body ────────────────────────────
          return _currentIndex == 0
              ? (_isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildDashboard(isDark, pending, approved))
              : _currentIndex == 1
              ? _buildTicketsView(isDark)
              : (_isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildStudiosView(isDark));
        }),
      ),
    );
  }

  /// Bottom sheet يعرض سجل إشعارات الحجوزات الجديدة
  void _showEmployeeNotifsSheet(bool isDark) {
    // mark all as read locally + في AWS
    final unread = _employeeNotifs.where((n) => n['read'] != 'true').toList();
    for (final n in unread) {
      n['read'] = 'true';
      final id = n['id'] ?? '';
      if (id.isNotEmpty) AWSStorageService.markNotificationRead(id);
    }
    setState(() => _unreadNotifsCount = 0);
    final bg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final bgSheet = isDark ? AppColors.darkBg : const Color(0xFFF8F9FB);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgSheet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      Text('${_employeeNotifs.length} total',
                          style: TextStyle(color: subText, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            // List
            Expanded(
              child: _employeeNotifs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.07),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.notifications_none_rounded,
                                size: 34,
                                color: AppColors.primary.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 14),
                          Text('No notifications yet',
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('New bookings will appear here',
                              style: TextStyle(color: subText, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _employeeNotifs.length,
                      itemBuilder: (_, i) {
                        final n = _employeeNotifs[i];
                        final type = n['type'] ?? '';
                        final isUnread = n['read'] != 'true';

                        Color typeColor;
                        IconData typeIcon;
                        switch (type) {
                          case 'Approved':
                            typeColor = AppColors.success;
                            typeIcon = Icons.check_circle_rounded;
                            break;
                          case 'Rejected':
                            typeColor = AppColors.error;
                            typeIcon = Icons.cancel_rounded;
                            break;
                          case 'chat_opened':
                            typeColor = const Color(0xFF7C3AED);
                            typeIcon = Icons.chat_bubble_rounded;
                            break;
                          default:
                            typeColor = AppColors.primary;
                            typeIcon = Icons.calendar_today_rounded;
                        }

                        String timeStr = '';
                        try {
                          final dt = DateTime.parse(n['time'] ?? '').toLocal();
                          final now = DateTime.now();
                          final diff = now.difference(dt);
                          if (diff.inMinutes < 1) {
                            timeStr = 'Just now';
                          } else if (diff.inHours < 1) {
                            timeStr = '${diff.inMinutes}m ago';
                          } else if (diff.inHours < 24) {
                            timeStr = '${diff.inHours}h ago';
                          } else {
                            timeStr =
                                '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          }
                        } catch (_) {
                          timeStr = n['time'] ?? '';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? (isDark
                                    ? typeColor.withValues(alpha: 0.10)
                                    : typeColor.withValues(alpha: 0.05))
                                : bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnread
                                  ? typeColor.withValues(alpha: 0.45)
                                  : borderColor,
                              width: isUnread ? 1.5 : 1,
                            ),
                            boxShadow: isUnread
                                ? [
                                    BoxShadow(
                                      color: typeColor.withValues(alpha: 0.18),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.12 : 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: isUnread ? 48 : 42,
                                      height: isUnread ? 48 : 42,
                                      decoration: BoxDecoration(
                                        color: isUnread
                                            ? typeColor.withValues(alpha: 0.18)
                                            : typeColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(
                                            isUnread ? 14 : 12),
                                      ),
                                      child: Icon(typeIcon,
                                          color: isUnread
                                              ? typeColor
                                              : typeColor.withValues(alpha: 0.5),
                                          size: isUnread ? 24 : 20),
                                    ),
                                    if (isUnread)
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: typeColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.darkBg
                                                  : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(n['title'] ?? '',
                                                style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: isUnread
                                                        ? FontWeight.w800
                                                        : FontWeight.w700,
                                                    fontSize: isUnread ? 14.5 : 14)),
                                          ),
                                          if (isUnread)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: typeColor,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text('NEW',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 0.5)),
                                            )
                                          else if (type.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: typeColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                type.replaceAll('_', ' '),
                                                style: TextStyle(
                                                    color: typeColor.withValues(alpha: 0.6),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(timeStr,
                                          style: TextStyle(
                                              color: isUnread
                                                  ? typeColor.withValues(alpha: 0.8)
                                                  : subText.withValues(alpha: 0.6),
                                              fontSize: 10,
                                              fontWeight: isUnread
                                                  ? FontWeight.w600
                                                  : FontWeight.w400)),
                                      const SizedBox(height: 4),
                                      Text(n['body'] ?? '',
                                          style: TextStyle(
                                              color: isUnread
                                                  ? textColor.withValues(alpha: 0.8)
                                                  : subText,
                                              fontSize: 12,
                                              height: 1.4),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      if (!isUnread) ...[
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          Icon(Icons.done_all_rounded,
                                              size: 13,
                                              color: subText.withValues(alpha: 0.4)),
                                          const SizedBox(width: 4),
                                          Text('Read',
                                              style: TextStyle(
                                                  color: subText.withValues(alpha: 0.4),
                                                  fontSize: 10)),
                                        ]),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── helpers للـ dashboard ──────────────────────────────────────────────────

  // ── helpers: week boundaries ──────────────────────────────────────────────
  DateTime _weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));
  DateTime _weekEnd(DateTime d)   => _weekStart(d).add(const Duration(days: 6));

  List<Map<String, String>> _bookingsForTab(int tab) {
    return bookingRequests.where((b) {
      DateTime? dt;
      try { dt = DateTime.parse(b['fullStartDateTime'] ?? b['date'] ?? ''); } catch (_) {}
      if (dt == null) return false;
      if (tab == 0) {
        return dt.year == _selectedDay.year && dt.month == _selectedDay.month && dt.day == _selectedDay.day;
      } else if (tab == 1) {
        final ws = _weekStart(_selectedWeek);
        final we = _weekEnd(_selectedWeek);
        return !dt.isBefore(ws) && !dt.isAfter(we.add(const Duration(hours: 23, minutes: 59)));
      } else {
        return dt.year == _selectedMonth.year && dt.month == _selectedMonth.month;
      }
    }).toList();
  }

  double _totalRevenue(List<Map<String, String>> list) {
    return list.fold(0, (sum, b) {
      final p = double.tryParse(
              b['price']?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ??
          0;
      return sum + p;
    });
  }

  double _totalHours(List<Map<String, String>> list) {
    return list.fold(0.0, (sum, b) {
      // حساب الساعات من fullStartDateTime و fullEndDateTime
      final start = DateTime.tryParse(b['fullStartDateTime'] ?? '');
      final end   = DateTime.tryParse(b['fullEndDateTime']   ?? '');
      if (start != null && end != null && end.isAfter(start)) {
        return sum + end.difference(start).inMinutes / 60.0;
      }
      // fallback: لو في قيمة رقمية مباشرة
      final raw = b['hours'] ?? '';
      final num = double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), ''));
      return sum + (num != null && num < 24 ? num : 0);
    });
  }

  Map<String, int> _studioBookingCount(List<Map<String, String>> list) {
    final map = <String, int>{};
    for (final b in list) {
      final s = b['studio'] ?? 'Unknown';
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  Map<String, double> _studioRevenue(List<Map<String, String>> list) {
    final map = <String, double>{};
    for (final b in list) {
      final s = b['studio'] ?? 'Unknown';
      final p = double.tryParse(
              b['price']?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ??
          0;
      map[s] = (map[s] ?? 0) + p;
    }
    return map;
  }

  Widget _buildDashboard(bool isDark, int pending, int approved) {
    final loc = AppLocalizations.of(context);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final screenW = MediaQuery.of(context).size.width;
    final hPad = screenW > 600 ? 24.0 : 16.0;

    final tabLabels = ['Today', 'This Week', 'This Month'];
    final tabBookings = _bookingsForTab(_dashboardTab);
    final tabApproved = tabBookings.where((b) => b['status'] == 'Approved').toList();
    final tabPending  = tabBookings.where((b) => b['status'] == 'Pending').toList();
    final tabRejected = tabBookings.where((b) => b['status'] == 'Rejected').toList();
    final revenue = _totalRevenue(tabApproved);
    final hours   = _totalHours(tabApproved);
    final studioCount = _studioBookingCount(tabBookings);
    final studioRev   = _studioRevenue(tabBookings);
    final topStudios  = studioCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // bar chart data — آخر 7 أيام / 4 أسابيع / 6 أشهر
    final barData = _buildBarData(_dashboardTab);
    final maxBar  = barData.isEmpty ? 1 : barData.map((e) => e['v'] as int).reduce((a, b) => a > b ? a : b);

    final filters = [
      {'key': 'All',      'label': loc.translate('all')},
      {'key': 'Pending',  'label': loc.translate('pending')},
      {'key': 'Approved', 'label': loc.translate('approved')},
      {'key': 'Rejected', 'label': loc.translate('rejected')},
    ];

    // KPI list
    final kpis = [
      {'label': 'Total',    'value': '${tabBookings.length}', 'icon': Icons.receipt_long_rounded,   'color': AppColors.primary},
      {'label': 'Approved', 'value': '${tabApproved.length}', 'icon': Icons.check_circle_rounded,   'color': AppColors.success},
      {'label': 'Pending',  'value': '${tabPending.length}',  'icon': Icons.hourglass_top_rounded,  'color': AppColors.warning},
      {'label': 'Rejected', 'value': '${tabRejected.length}', 'icon': Icons.cancel_rounded,         'color': AppColors.error},
      {'label': 'Revenue',  'value': '\$${revenue.toStringAsFixed(0)}', 'icon': Icons.attach_money_rounded, 'color': const Color(0xFF10B981)},
      {'label': 'Hours',    'value': '${hours.toStringAsFixed(1)}h',    'icon': Icons.access_time_rounded,  'color': const Color(0xFF6366F1)},
    ];

    return Column(children: [
      Expanded(
        child: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
          children: [

            // ── Header ────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dashboard',
                      style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('Bookings & revenue overview',
                      style: TextStyle(color: subText, fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),

            // ── Time tabs ──────────────────────────────────────────────
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: List.generate(3, (i) {
                  final sel = _dashboardTab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _dashboardTab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: sel ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(tabLabels[i],
                            style: TextStyle(
                              color: sel ? Colors.white : subText,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            )),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),

            // ── Date navigator ─────────────────────────────────────────
            _buildDateNavigator(isDark, textColor, subText, cardColor, borderColor),
            const SizedBox(height: 16),

            // ── KPI grid (responsive columns) ─────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenW > 900 ? 6 : screenW > 600 ? 3 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: screenW > 900 ? 1.1 : screenW > 600 ? 1.3 : 1.15,
              ),
              itemCount: kpis.length,
              itemBuilder: (_, i) {
                final k = kpis[i];
                final color = k['color'] as Color;
                final icon  = k['icon']  as IconData;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const Spacer(),
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ]),
                    const Spacer(),
                    Text(k['value'] as String,
                        style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(k['label'] as String,
                        style: TextStyle(color: subText, fontSize: 11)),
                  ]),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── Bar chart ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Bookings Overview',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(tabLabels[_dashboardTab],
                        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 16),
                if (barData.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No data', style: TextStyle(color: subText, fontSize: 12)),
                  ))
                else
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: barData.map((e) {
                        final v = e['v'] as int;
                        final lbl = e['l'] as String;
                        final ratio = maxBar > 0 ? v / maxBar : 0.0;
                        final isMax = v == maxBar && v > 0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (v > 0)
                                  Text('$v', style: TextStyle(
                                    color: isMax ? AppColors.primary : subText,
                                    fontSize: 9, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  height: ratio * 80,
                                  decoration: BoxDecoration(
                                    color: isMax
                                        ? AppColors.primary
                                        : AppColors.primary.withValues(alpha: 0.25),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(lbl, style: TextStyle(color: subText, fontSize: 8),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Top Studios table ──────────────────────────────────────
            if (topStudios.isNotEmpty) ...[
              _sectionHeader('Top Studios', textColor),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(children: [
                  // table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text('Studio', style: TextStyle(color: subText, fontSize: 11, fontWeight: FontWeight.w700))),
                      Expanded(flex: 2, child: Text('Bookings', style: TextStyle(color: subText, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('Revenue', style: TextStyle(color: subText, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                      Expanded(flex: 3, child: Text('Share', style: TextStyle(color: subText, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                    ]),
                  ),
                  ...topStudios.asMap().entries.map((entry) {
                    final i = entry.key;
                    final studio = entry.value.key;
                    final count  = entry.value.value;
                    final rev    = studioRev[studio] ?? 0;
                    final total  = tabBookings.length;
                    final share  = total > 0 ? count / total : 0.0;
                    final isLast = i == topStudios.length - 1;
                    final rankColors = [const Color(0xFFF59E0B), const Color(0xFF94A3B8), const Color(0xFFCD7F32)];
                    final rankColor = i < 3 ? rankColors[i] : subText;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: isLast ? null : Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                      ),
                      child: Row(children: [
                        Expanded(flex: 3, child: Row(children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('${i + 1}', style: TextStyle(color: rankColor, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(studio,
                              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis)),
                        ])),
                        Expanded(flex: 2, child: Text('$count',
                            style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('\$${rev.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Row(children: [
                          const SizedBox(width: 4),
                          Expanded(child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: share,
                              minHeight: 6,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                            ),
                          )),
                          const SizedBox(width: 6),
                          Text('${(share * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: subText, fontSize: 10)),
                        ])),
                      ]),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // ── Active Bookings ────────────────────────────────────────
            _sectionHeader('Active Bookings', textColor),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((item) {
                  final f   = item['key']!;
                  final lbl = item['label']!;
                  final sel = currentFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _applyFilter(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.primary : borderColor),
                        ),
                        child: Text(lbl, style: TextStyle(
                          color: sel ? Colors.white : subText,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (filteredBookings.isEmpty)
              _emptyState('No active bookings', subText)
            else if (screenW >= 800)
              _bookingGrid(filteredBookings, isDark)
            else
              ...filteredBookings.asMap().entries.map((e) => _bookingCard(e.key, e.value, isDark)),

            const SizedBox(height: 24),

            // ── Archive section ────────────────────────────────────────
            _buildArchiveSection(isDark, textColor, subText, cardColor, borderColor, screenW),
          ],
        ),
      ),
    ]);
  }

  // ── Booking 2-column grid for wide screens ────────────────────────────────
  Widget _bookingGrid(List<Map<String, String>> bookings, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 0,
        childAspectRatio: 1.55,
      ),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _bookingCard(i, bookings[i], isDark),
    );
  }

  // ── Archive section ────────────────────────────────────────────────────────
  Widget _buildArchiveSection(bool isDark, Color textColor, Color subText,
      Color cardColor, Color borderColor, [double screenW = 0]) {
    final archived = _archivedBookings;
    final archiveFilters = [
      {'key': 'All',      'label': 'All'},
      {'key': 'Approved', 'label': 'Approved'},
      {'key': 'Rejected', 'label': 'Rejected'},
      {'key': 'Done',     'label': 'Done'},
      {'key': 'Pending',  'label': 'Expired'},
    ];
    final shown = _archiveFilter == 'All'
        ? archived
        : archived.where((b) => b['status'] == _archiveFilter).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // header row
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _showArchiveSection = !_showArchiveSection),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(children: [
            Icon(Icons.archive_rounded, color: subText, size: 18),
            const SizedBox(width: 8),
            Text('Archive',
                style: TextStyle(color: textColor,
                    fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${archived.length}',
                  style: const TextStyle(color: AppColors.primary,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Icon(_showArchiveSection
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
                color: subText, size: 20),
          ]),
        ),
      ),

      if (_showArchiveSection) ...[
        const SizedBox(height: 12),
        // filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: archiveFilters.map((item) {
              final f   = item['key']!;
              final lbl = item['label']!;
              final sel = _archiveFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _archiveFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel
                          ? (f == 'Done' ? AppColors.success : AppColors.primary)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? (f == 'Done' ? AppColors.success : AppColors.primary)
                              : borderColor),
                    ),
                    child: Text(lbl, style: TextStyle(
                      color: sel ? Colors.white : subText,
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No archived bookings',
                style: TextStyle(color: subText, fontSize: 13))),
          )
        else if (screenW >= 800)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 0,
              childAspectRatio: 2.8,
            ),
            itemCount: shown.length,
            itemBuilder: (_, i) => _archivedBookingCard(shown[i], isDark),
          )
        else
          ...shown.map((b) => _archivedBookingCard(b, isDark)),
      ],
      const SizedBox(height: 32),
    ]);
  }

  Widget _archivedBookingCard(Map<String, String> booking, bool isDark) {
    final textColor   = isDark ? AppColors.darkText    : AppColors.lightText;
    final subText     = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor   = isDark ? AppColors.darkCard    : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final status      = booking['status'] ?? '';

    Color statusColor;
    switch (status) {
      case 'Approved': statusColor = AppColors.success; break;
      case 'Rejected': statusColor = AppColors.error;   break;
      case 'Done':     statusColor = const Color(0xFF6366F1); break;
      default:         statusColor = AppColors.warning; // expired pending
    }
    final displayStatus = status == 'Pending' ? 'Expired' : status;

    String timeStr = '';
    final s = DateTime.tryParse(booking['fullStartDateTime'] ?? '');
    final e = DateTime.tryParse(booking['fullEndDateTime'] ?? '');
    if (s != null && e != null) {
      final fmt = DateFormat('dd MMM · HH:mm');
      final hrs = e.difference(s).inMinutes / 60.0;
      timeStr = '${fmt.format(s)} – ${DateFormat('HH:mm').format(e)} (${hrs.toStringAsFixed(1)}h)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10, right: 0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.archive_rounded, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking['clientName'] ?? booking['clientEmail'] ?? '',
                style: TextStyle(color: textColor,
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(booking['studio'] ?? '',
                style: TextStyle(color: subText, fontSize: 11)),
            if (timeStr.isNotEmpty)
              Text(timeStr, style: TextStyle(color: subText, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(displayStatus,
                  style: TextStyle(color: statusColor,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Text('\$${booking['price'] ?? '0'}',
                style: const TextStyle(color: AppColors.success,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  // ── bar chart data builder ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _buildBarData(int tab) {
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (tab == 0) {
      // كل ساعات اليوم المختار (24 بار أو 8 نقط كل 3 ساعات)
      return List.generate(8, (i) {
        final hourFrom = i * 3;
        final hourTo   = hourFrom + 2;
        final count = bookingRequests.where((b) {
          DateTime? dt;
          try { dt = DateTime.parse(b['fullStartDateTime'] ?? b['date'] ?? ''); } catch (_) {}
          return dt != null &&
              dt.year == _selectedDay.year &&
              dt.month == _selectedDay.month &&
              dt.day == _selectedDay.day &&
              dt.hour >= hourFrom && dt.hour <= hourTo;
        }).length;
        return {'l': '${hourFrom}h', 'v': count};
      });
    } else if (tab == 1) {
      // كل أيام الأسبوع المختار (7 بارات)
      final ws = _weekStart(_selectedWeek);
      return List.generate(7, (i) {
        final day = ws.add(Duration(days: i));
        final count = bookingRequests.where((b) {
          DateTime? dt;
          try { dt = DateTime.parse(b['fullStartDateTime'] ?? b['date'] ?? ''); } catch (_) {}
          return dt != null && dt.year == day.year && dt.month == day.month && dt.day == day.day;
        }).length;
        return {'l': dayLabels[day.weekday - 1], 'v': count, 'day': day};
      });
    } else {
      // كل أيام الشهر المختار — نجمع per week داخل الشهر
      final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
      final weeksCount  = ((daysInMonth + DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday - 1) / 7).ceil();
      return List.generate(weeksCount, (i) {
        final weekNum = i + 1;
        final count = bookingRequests.where((b) {
          DateTime? dt;
          try { dt = DateTime.parse(b['fullStartDateTime'] ?? b['date'] ?? ''); } catch (_) {}
          if (dt == null || dt.year != _selectedMonth.year || dt.month != _selectedMonth.month) return false;
          final dayOfMonth = dt.day;
          final startDay = (i * 7) + 1;
          final endDay   = ((i + 1) * 7).clamp(1, daysInMonth);
          return dayOfMonth >= startDay && dayOfMonth <= endDay;
        }).length;
        return {'l': 'W$weekNum', 'v': count};
      });
    }
  }

  // ── date label helpers ────────────────────────────────────────────────────
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  static const _fullMonths = ['January','February','March','April','May','June','July','August','September','October','November','December'];

  String _dayLabel()   => '${_selectedDay.day} ${_months[_selectedDay.month - 1]} ${_selectedDay.year}';
  String _weekLabel()  {
    final ws = _weekStart(_selectedWeek);
    final we = _weekEnd(_selectedWeek);
    if (ws.month == we.month) return '${ws.day}–${we.day} ${_months[ws.month - 1]} ${ws.year}';
    return '${ws.day} ${_months[ws.month - 1]} – ${we.day} ${_months[we.month - 1]}';
  }
  String _monthLabel() => '${_fullMonths[_selectedMonth.month - 1]} ${_selectedMonth.year}';

  // ── date navigator bar ────────────────────────────────────────────────────
  Widget _buildDateNavigator(bool isDark, Color textColor, Color subText, Color cardColor, Color borderColor) {
    final now = DateTime.now();
    String label;
    bool canGoForward;

    if (_dashboardTab == 0) {
      label = _dayLabel();
      canGoForward = !(_selectedDay.year == now.year && _selectedDay.month == now.month && _selectedDay.day == now.day);
    } else if (_dashboardTab == 1) {
      label = _weekLabel();
      final thisWeekStart = _weekStart(now);
      canGoForward = _weekStart(_selectedWeek).isBefore(thisWeekStart);
    } else {
      label = _monthLabel();
      canGoForward = !(_selectedMonth.year == now.year && _selectedMonth.month == now.month);
    }

    void goBack() => setState(() {
      if (_dashboardTab == 0) {
        _selectedDay = _selectedDay.subtract(const Duration(days: 1));
      } else if (_dashboardTab == 1) {
        _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      }
    });

    void goForward() {
      if (!canGoForward) return;
      setState(() {
        if (_dashboardTab == 0) {
          _selectedDay = _selectedDay.add(const Duration(days: 1));
        } else if (_dashboardTab == 1) {
          _selectedWeek = _selectedWeek.add(const Duration(days: 7));
        } else {
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
        }
      });
    }

    Future<void> pickDate() async {
      if (_dashboardTab == 0) {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDay,
          firstDate: DateTime(2020),
          lastDate: now,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary,
                  brightness: isDark ? Brightness.dark : Brightness.light),
            ),
            child: child!,
          ),
        );
        if (picked != null && mounted) setState(() => _selectedDay = picked);
      } else if (_dashboardTab == 1) {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedWeek,
          firstDate: DateTime(2020),
          lastDate: now,
          helpText: 'Pick any day in the week',
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary,
                  brightness: isDark ? Brightness.dark : Brightness.light),
            ),
            child: child!,
          ),
        );
        if (picked != null && mounted) setState(() => _selectedWeek = picked);
      } else {
        // month picker — use year/month wheel
        await _pickMonthYear(isDark);
      }
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        // back arrow
        InkWell(
          onTap: goBack,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          child: Container(
            width: 44, height: 44,
            alignment: Alignment.center,
            child: Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 22),
          ),
        ),
        // divider
        Container(width: 1, height: 24, color: borderColor),
        // label — tap to open picker
        Expanded(
          child: InkWell(
            onTap: pickDate,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                _dashboardTab == 0 ? Icons.today_rounded
                    : _dashboardTab == 1 ? Icons.date_range_rounded
                    : Icons.calendar_month_rounded,
                size: 14, color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 14, color: subText),
            ]),
          ),
        ),
        // divider
        Container(width: 1, height: 24, color: borderColor),
        // forward arrow
        InkWell(
          onTap: canGoForward ? goForward : null,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
          child: Container(
            width: 44, height: 44,
            alignment: Alignment.center,
            child: Icon(Icons.chevron_right_rounded,
                color: canGoForward ? AppColors.primary : borderColor, size: 22),
          ),
        ),
      ]),
    );
  }

  // ── month/year picker ─────────────────────────────────────────────────────
  Future<void> _pickMonthYear(bool isDark) async {
    int tempYear  = _selectedMonth.year;
    int tempMonth = _selectedMonth.month;
    final now     = DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // handle
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Select Month', style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              // year row
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                  onPressed: () => setLocal(() => tempYear--),
                ),
                Text('$tempYear', style: const TextStyle(
                    color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                IconButton(
                  icon: Icon(Icons.chevron_right_rounded,
                      color: tempYear < now.year ? AppColors.primary : Colors.grey),
                  onPressed: tempYear < now.year ? () => setLocal(() => tempYear++) : null,
                ),
              ]),
              const SizedBox(height: 8),
              // month grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                childAspectRatio: 2.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isFuture = DateTime(tempYear, m).isAfter(DateTime(now.year, now.month));
                  final isSelected = m == tempMonth && tempYear == _selectedMonth.year;
                  return GestureDetector(
                    onTap: isFuture ? null : () => setLocal(() => tempMonth = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary
                              : isFuture ? Colors.grey.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(_months[i],
                          style: TextStyle(
                            color: isSelected ? Colors.white
                                : isFuture ? Colors.grey.withValues(alpha: 0.4)
                                : isDark ? AppColors.darkText : AppColors.lightText,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          )),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedMonth = DateTime(tempYear, tempMonth));
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, Color textColor) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 4, height: 16,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 14)),
    ],
  );

  Widget _emptyState(String msg, Color subText) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    alignment: Alignment.center,
    child: Column(children: [
      Container(width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07), shape: BoxShape.circle),
          child: const Icon(Icons.inbox_rounded, color: AppColors.primary, size: 24)),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(color: subText, fontSize: 13)),
    ]),
  );

  Widget _studioGradient(Color accent, IconData icon) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(icon, size: 36, color: Colors.white.withValues(alpha: 0.4)),
        ),
      );

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
                  color: statusColor.withValues(alpha: 0.1),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
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
              Expanded(
                child: Text('Tap to view details',
                    style: TextStyle(color: subText, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ),
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
              if (booking['status'] == 'Approved')
                _iconBtn(Icons.done_all_rounded, const Color(0xFF6366F1),
                        () => _markAsDone(booking['id'] ?? '')),
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
              color: AppColors.primary.withValues(alpha: 0.08),
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
                    .withValues(alpha: 0.1),
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

    // Remove locally first for instant UI feedback
    setState(() => studios.removeWhere((s) => s['id'] == studioId));

    final success = await AWSStorageService.deleteStudio(studioId);
    if (!mounted) return;

    if (success) {
      _snack('Studio deleted', AppColors.success);
      // Wait for AppSync to propagate before refreshing
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      final updated = await AWSStorageService.loadStudios();
      if (!mounted) return;
      setState(() => studios = updated);
    } else {
      _snack('Failed to delete studio', AppColors.error);
      // Restore by reloading
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
                color: AppColors.primary.withValues(alpha: 0.08),
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
                TextStyle(color: subText.withValues(alpha: 0.6), fontSize: 13)),
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
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                      child: SizedBox(
                        height: 90,
                        width: double.infinity,
                        child: Stack(fit: StackFit.expand, children: [
                          // Image or gradient fallback
                          () {
                            final img = s['image'] as String? ?? '';
                            if (img.startsWith('data:image')) {
                              try {
                                return Image.memory(
                                  base64Decode(img.split(',')[1]),
                                  fit: BoxFit.cover,
                                );
                              } catch (_) {}
                            }
                            if (img.startsWith('http')) {
                              return Image.network(img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _studioGradient(accent, icon));
                            }
                            return _studioGradient(accent, icon);
                          }(),
                          // Subtle overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                          // Price badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
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
                          // Multi-image indicator
                          if ((s['images'] as List?)?.length != null &&
                              ((s['images'] as List).length) > 1)
                            Positioned(
                              bottom: 6,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.photo_library_rounded,
                                          color: Colors.white, size: 10),
                                      const SizedBox(width: 3),
                                      Text(
                                          '${(s['images'] as List).length}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700)),
                                    ]),
                              ),
                            ),
                        ]),
                      ),
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
                                      color: accent.withValues(alpha: 0.1),
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
                                      color: AppColors.error.withValues(alpha: 0.1),
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
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
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
          _dTile(context, Icons.bar_chart_rounded, 'Reports', text, sub,
              false, () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()));
              }, iconColor: const Color(0xFF6366F1)),
          _dTile(context, Icons.settings_rounded, loc.translate('settings'),
              text, sub, false, () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen(isEmployee: true)));
              }),
          const Spacer(),
          Divider(height: 1, color: border),
          _dTile(context, Icons.logout_rounded, loc.translate('logout'),
              AppColors.error, AppColors.error, false, () async {
                final nav = Navigator.of(context);
                await AWSStorageService.signOut();
                if (!mounted) return;
                nav.pushReplacement(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              }, iconColor: AppColors.error),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _sideNavItem(IconData icon, String label, int index, bool isDark,
      {VoidCallback? onTap}) {
    final selected = index == _currentIndex;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor  = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: (selected ? AppColors.primary : subColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18,
              color: selected ? AppColors.primary : subColor),
        ),
        title: Text(label, style: TextStyle(
          color: selected ? AppColors.primary : textColor,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        )),
        onTap: onTap ?? () => setState(() => _currentIndex = index),
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
        color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: (iconColor ?? subColor).withValues(alpha: 0.1),
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

  // Multi-image: each entry is either {bytes: Uint8List} (new) or {url: String, key: String} (existing)
  static const int _maxImages = 5;
  final List<Map<String, dynamic>> _images = [];

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

      // Load existing images
      final rawUrls = e['images'];
      final rawKeys = e['imageKeys'];
      final urls = rawUrls is List
          ? rawUrls.map((x) => x.toString()).where((x) => x.isNotEmpty).toList()
          : <String>[];
      final keys = rawKeys is List
          ? rawKeys.map((x) => x.toString()).where((x) => x.isNotEmpty).toList()
          : <String>[];
      for (int i = 0; i < urls.length; i++) {
        _images.add({'url': urls[i], 'key': i < keys.length ? keys[i] : ''});
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_images.length >= _maxImages) return;
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final remaining = _maxImages - _images.length;
        final picked = await picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1200,
        );
        if (picked.isEmpty || !mounted) return;
        final toAdd = picked.take(remaining).toList();
        for (final f in toAdd) {
          final bytes = await f.readAsBytes();
          if (mounted) setState(() => _images.add({'file': f, 'bytes': bytes}));
        }
      } else {
        final picked = await picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1200,
        );
        if (picked != null && mounted) {
          final bytes = await picked.readAsBytes();
          setState(() => _images.add({'file': picked, 'bytes': bytes}));
        }
      }
    } catch (_) {}
  }

  void _showAddImageSheet() {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      _pickImages(ImageSource.gallery);
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
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary, size: 20),
            ),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImages(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary, size: 20),
            ),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImages(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final List<String> finalKeys = [];

      for (final img in _images) {
        if (img.containsKey('bytes')) {
          // New image — upload to S3
          final bytes = img['bytes'] as Uint8List;
          final file = img['file'] as XFile?;

          if (bytes.length > 5 * 1024 * 1024) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An image exceeds 5MB limit'), backgroundColor: Colors.red),
            );
            setState(() => _isSaving = false);
            return;
          }

          final ext = (file?.path.split('.').lastOrNull ?? 'jpg').toLowerCase();
          const validExts = ['jpg', 'jpeg', 'png', 'webp'];
          if (!validExts.contains(ext)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid format. Use JPG, PNG, or WebP'), backgroundColor: Colors.red),
            );
            setState(() => _isSaving = false);
            return;
          }

          final key = await AWSStorageService.uploadImageBytes(
            bytes: bytes,
            extension: ext,
            prefix: 'studios',
          );
          if (key == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image. Try again.'), backgroundColor: Colors.red),
            );
            setState(() => _isSaving = false);
            return;
          }
          finalKeys.add(key);
        } else {
          // Existing image — keep its S3 key
          final key = img['key']?.toString() ?? '';
          if (key.isNotEmpty) {
            finalKeys.add(key);
          } else {
            // fallback: if key is missing but we have a raw S3 path in url
            final url = img['url']?.toString() ?? '';
            // extract key from pre-signed URL (path before '?')
            if (url.contains('amazonaws.com')) {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                final rawPath = uri.path.replaceFirst('/', '');
                if (rawPath.isNotEmpty) finalKeys.add(rawPath);
              }
            }
          }
        }
      }

      // Delete S3 keys that were removed
      final rawOld = widget.existing?['imageKeys'];
      final oldKeys = rawOld is List
          ? rawOld.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      for (final oldKey in oldKeys) {
        if (oldKey.isEmpty) continue;
        if (oldKey.startsWith('http') || oldKey.startsWith('data:')) continue;
        if (!finalKeys.contains(oldKey)) {
          await AWSStorageService.deleteS3Image(oldKey);
        }
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'type': _selectedType,
        'pricePerHour': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'available': _available,
        'imageKeys': finalKeys,
      };

      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving studio: $e'), backgroundColor: Colors.red),
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
    final canAddMore = _images.length < _maxImages;

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
            // ── Photos section ──────────────────────────────────────────
            Row(children: [
              Text('Studio Photos',
                  style: TextStyle(
                      color: subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_images.length}/$_maxImages',
                    style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Image thumbnails
                  ..._images.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final img = entry.value;
                    return _imageThumbnail(img, idx, accent, borderColor);
                  }),
                  // Add more button
                  if (canAddMore)
                    GestureDetector(
                      onTap: _showAddImageSheet,
                      child: Container(
                        width: 90,
                        height: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                              width: 1.5,
                              style: BorderStyle.solid),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  color: accent, size: 28),
                              const SizedBox(height: 6),
                              Text('Add Photo',
                                  style: TextStyle(
                                      color: accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ]),
                      ),
                    ),
                ],
              ),
            ),
            if (_images.isEmpty) ...[
              const SizedBox(height: 6),
              Text('Add up to $_maxImages photos for your studio',
                  style: TextStyle(color: subText, fontSize: 12)),
            ],
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
                            color: tAccent.withValues(alpha: 0.3),
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
                        .withValues(alpha: 0.12),
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
                  activeThumbColor: AppColors.success,
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
                      color: accent.withValues(alpha: 0.12),
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

  Widget _imageThumbnail(Map<String, dynamic> img, int idx, Color accent, Color borderColor) {
    Widget imageWidget;
    if (img.containsKey('bytes')) {
      imageWidget = Image.memory(img['bytes'] as Uint8List,
          fit: BoxFit.cover, width: 90, height: 110);
    } else {
      final url = img['url'] as String? ?? '';
      imageWidget = url.startsWith('data:')
          ? Image.memory(base64Decode(url.split(',')[1]),
              fit: BoxFit.cover, width: 90, height: 110)
          : Image.network(url,
              fit: BoxFit.cover, width: 90, height: 110,
              errorBuilder: (_, __, ___) => Container(
                width: 90, height: 110,
                color: accent.withValues(alpha: 0.1),
                child: Icon(Icons.broken_image_rounded, color: accent),
              ));
    }

    return Container(
      width: 90,
      height: 110,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: imageWidget,
          ),
          // Cover badge for first image
          if (idx == 0)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(13)),
                ),
                child: const Text('Cover',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          // Remove button
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(idx),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

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