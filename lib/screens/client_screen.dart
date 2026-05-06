// lib/screens/client_screen.dart
import 'dart:async';
import 'dart:convert';
// dart:io removed — not supported on Web/Windows
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:genz/models/ModelProvider.dart';
import 'package:genz/data/data.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/screens/frist_screen.dart';
import 'package:genz/screens/settings_screen.dart';
import 'package:genz/screens/my_bookings_screen.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/services/settings_service.dart';
import 'package:genz/screens/chat_screen.dart';
import 'package:genz/screens/notifications_screen.dart';
import 'package:genz/screens/MyTicketsScreen.dart';
import 'package:genz/screens/ChatbotScreen.dart';
import 'package:genz/screens/profile_screen.dart';
import 'package:genz/screens/StudioDetailScreen.dart';
import 'package:genz/theme/app_theme.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});
  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  int _selectedIndex = 0;
  // ✅ GraphQL Subscriptions (real-time) — لا polling
  StreamSubscription<Studio>? _studiosSubscription;
  StreamSubscription<BookingRequest>? _bookingsSubscription;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _fromDateCtrl  = TextEditingController();
  final _toDateCtrl    = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? selectedStudio;
  List<String> selectedEquipment = [];
  List<Map<String, dynamic>> _studios = [];
  int startHour = 10;
  int endHour   = 18;
  bool termsAccepted = false;
  bool _isSubmitting = false;

  List<String> get studioNames => _studios.map((s) => s['name'] as String).toList();
  final List<int> hours = List.generate(24, (i) => i);

  @override
  void initState() {
    super.initState();
    SettingsService.locale.addListener(_onLocaleChanged);
    _guardAndLoad();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _guardAndLoad() async {
    try {
      await AWSStorageService.requireSignedIn();
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()));
      return;
    }

    try { await AWSStorageService.loadCurrentUser(); } catch (_) {}

    try {
      final parts = (currentUser['name'] ?? '').split(' ');
      _firstNameCtrl.text = parts.isNotEmpty ? parts.first : '';
      if (parts.length > 1) _lastNameCtrl.text = parts.sublist(1).join(' ');
    } catch (_) {}

    // ✅ تحميل الاستوديوهات فوراً على كل الـ platforms
    try {
      final loadedStudios = await AWSStorageService.loadStudios();
      if (mounted) {
        setState(() {
          _studios
            ..clear()
            ..addAll(loadedStudios.map((s) => Map<String, dynamic>.from(s)));
        });
      }
    } catch (_) {}

    // ✅ GraphQL Subscriptions على كل الـ platforms (real-time)
    try { _listenToStudios(); } catch (_) {}
    try { _listenToBookings(); } catch (_) {}
    try { _listenToNotifications(); } catch (_) {}

  }

  void _listenToStudios() {
    // Subscription للـ real-time updates
    _studiosSubscription?.cancel();
    _studiosSubscription =
        AWSStorageService.subscribeToStudios().listen((_) {
          _fetchStudiosFromAPI();
        }, onError: (e) {
          safePrint('Studios subscription error: $e');
        });

    // Polling كـ backup لو الـ subscription انقطع أو الشبكة بطيئة
    _studiosPollingTimer?.cancel();
    _studiosPollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchStudiosFromAPI(),
    );
  }

  Future<void> _fetchStudiosFromAPI() async {
    try {
      final loaded = await AWSStorageService.loadStudios();
      if (mounted) {
        setState(() {
          _studios
            ..clear()
            ..addAll(loaded.map((s) => Map<String, dynamic>.from(s)));
        });
      }
    } catch (e) {
      safePrint('fetchStudiosFromAPI error: $e');
    }
  }

  Timer? _bookingsPollingTimer;
  Timer? _notificationsPollingTimer;
  Timer? _studiosPollingTimer;

  void _listenToBookings() {
    final email = currentUser['email'] ?? '';
    if (email.isEmpty) return;

    // ✅ Initial load
    _fetchBookingsFromAPI(email);

    // ✅ Owner-auth subscriptions على BookingRequest بترجع Unauthorized للعميل
    // لأن AppSync محتاج owner argument في الـ subscription، الـ ModelSubscriptions
    // ما بيدعمش ده. للعميل: polling. للموظف: subscription لكل الحجوزات.
    if (currentUser['type'] == 'employee') {
      _bookingsSubscription?.cancel();
      _bookingsSubscription =
          AWSStorageService.subscribeToBookings(clientEmail: null).listen(
                (booking) {
              if (!mounted) return;
              final map = <String, String>{
                'id': booking.id,
                'clientEmail': booking.clientEmail,
                'clientName': booking.clientName ?? '',
                'clientPhone': booking.clientPhone ?? '',
                'studio': booking.studio,
                'date': booking.date,
                'hours': booking.hours,
                'price': booking.price,
                'equipment': booking.equipment ?? '',
                'status': booking.status ?? 'Pending',
                'fullStartDateTime': booking.fullStartDateTime,
                'fullEndDateTime': booking.fullEndDateTime,
              };
              final idx =
              bookingRequests.indexWhere((b) => b['id'] == booking.id);
              setState(() {
                if (idx >= 0) {
                  bookingRequests[idx] = map;
                } else {
                  bookingRequests.add(map);
                }
              });
            },
            onError: (e) => safePrint('Bookings subscription error: $e'),
          );
    } else {
      // ✅ Client: polling كل 5 ثواني
      _bookingsPollingTimer?.cancel();
      _bookingsPollingTimer = Timer.periodic(
        const Duration(seconds: 5),
            (_) => _fetchBookingsFromAPI(email),
      );
    }
  }

  Future<void> _fetchBookingsFromAPI(String email) async {
    try {
      final list = await AWSStorageService.loadBookings(limit: 100);
      _processBookings(list);
    } catch (e) {
      safePrint('fetchBookingsFromAPI error: $e');
    }
  }

  void _processBookings(List<Map<String, String>> mapped) {
    bookingRequests
      ..clear()
      ..addAll(mapped);
    if (mounted) setState(() {});
  }

  void _listenToNotifications() {
    final email = (currentUser['email'] ?? '').trim();
    if (email.isEmpty) return;

    final isEmployee = currentUser['type'] == 'employee';
    final fetchKey = isEmployee ? AWSStorageService.employeeInboxKey : email;

    // Initial load + polling (subscriptions rejected by AppSync for owner-field types)
    _fetchNotificationsFromAPI(fetchKey);
    _notificationsPollingTimer?.cancel();
    _notificationsPollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchNotificationsFromAPI(fetchKey),
    );
  }

  /// 📥 Fetch notifications — للموظف يجيب من employeeInboxKey، للعميل من emailه
  Future<void> _fetchNotificationsFromAPI(String emailOrKey) async {
    try {
      final list = await AWSStorageService.loadNotifications(
        clientEmail: emailOrKey,
        limit: 100,
      );
      _processNotifications(list);
    } catch (e) {
      safePrint('fetchNotificationsFromAPI error: $e');
    }
  }

  void _processNotifications(List<Map<String, String>> mapped) {
    mapped.sort((a, b) => b['time']!.compareTo(a['time']!));
    appNotifications
      ..clear()
      ..addAll(mapped);
    if (mounted) setState(() {});
  }



  @override
  void dispose() {
    SettingsService.locale.removeListener(_onLocaleChanged);
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _fromDateCtrl.dispose();
    _toDateCtrl.dispose();
    _studiosSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _bookingsPollingTimer?.cancel();
    _notificationsPollingTimer?.cancel();
    _studiosPollingTimer?.cancel();
    super.dispose();
  }




  Future<void> _handleSupportClick() async {
    final email = currentUser['email'] ?? '';
    if (email.isEmpty) return;
    if (!mounted) return;

    // افتح ChatScreen مباشرة - هو سيتحقق من chatEnabled داخلياً
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(targetUser: {'name': 'Support', 'email': email})));
  }

  Future<void> _selectDate(BuildContext context, TextEditingController ctrl) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: isDark
            ? ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.primary))
            : ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  int _calculateTotalPrice() {
    if (selectedStudio == null || _fromDateCtrl.text.isEmpty || _toDateCtrl.text.isEmpty) return 0;
    try {
      final start = DateTime.parse('${_fromDateCtrl.text} ${startHour.toString().padLeft(2, '0')}:00:00');
      final end   = DateTime.parse('${_toDateCtrl.text} ${endHour.toString().padLeft(2, '0')}:00:00');
      final hrs   = end.difference(start).inHours;
      if (hrs <= 0) return 0;
      final studioData  = _studios.firstWhere((s) => s['name'] == selectedStudio, orElse: () => {});
      final studioPrice = (studioData['pricePerHour'] as int?) ?? 0;
      final equipTotal  = selectedEquipment.fold<int>(0, (s, i) => s + (equipmentPrices[i] ?? 0));
      return studioPrice * hrs + equipTotal;
    } catch (_) { return 0; }
  }

  Future<void> _submitBooking() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final loc = AppLocalizations.of(context);
    final start = DateTime.tryParse('${_fromDateCtrl.text} ${startHour.toString().padLeft(2, '0')}:00:00');
    final end   = DateTime.tryParse('${_toDateCtrl.text} ${endHour.toString().padLeft(2, '0')}:00:00');
    if (start == null || end == null) { _snack(loc.translate('invalid_dates'), AppColors.error); return; }
    if (!end.isAfter(start)) { _snack(loc.translate('end_after_start'), AppColors.error); return; }
    if (!termsAccepted)      { _snack(loc.translate('accept_terms'), AppColors.error); return; }

    setState(() => _isSubmitting = true);

    // جيب الـ email من Cognito — لو فشل حاول من الـ cache كـ fallback
    String? ownerEmail = await AWSStorageService.getOwnerEmail();
    if (ownerEmail == null || ownerEmail.isEmpty) {
      ownerEmail = (currentUser['email'] ?? '').trim();
    }
    if (ownerEmail.isEmpty) {
      if (!mounted) return;
      _snack(loc.translate('session_expired'), AppColors.error);
      setState(() => _isSubmitting = false);
      return;
    }

    final clientFullName =
    '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();

    final booking = {
      'clientName':  clientFullName,
      'clientEmail': ownerEmail,   // ✅ من Cognito مباشرة
      'clientPhone': _phoneCtrl.text.trim(),
      'studio':      selectedStudio!,
      'fullStartDateTime': start.toIso8601String(),
      'fullEndDateTime':   end.toIso8601String(),
      'date':  'From ${_fromDateCtrl.text} To ${_toDateCtrl.text}',
      'hours': '$startHour:00 - $endHour:00',
      'status': 'Pending',
      'price':     _calculateTotalPrice().toString(),
      'equipment': selectedEquipment.join(', '),
    };

    // ✅ ATOMIC booking — يفحص الـ availability من السيرفر مباشرة
    final result = await AWSStorageService.saveBookingAtomic(booking);
    final success = result['success'] == true;

    if (success) {
      // ✅ بعت إشعار للموظفين بالـ key الموحد (مش 'EMPLOYEE_INBOX' بعد كده)
      await AWSStorageService.sendNotification(
        clientEmail: AWSStorageService.employeeInboxKey,
        title: 'New Booking Request',
        body:
        '$clientFullName booked ${booking['studio']} on ${booking['date']}',
        type: 'new_booking',
      );

      // ✅ إشعار تأكيد للعميل نفسه
      await AWSStorageService.sendNotification(
        clientEmail: ownerEmail,
        title: 'Booking Submitted',
        body: 'Your booking for ${booking['studio']} is pending approval.',
        type: 'info',
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final loc2 = AppLocalizations.of(context);

    if (success) {
      _snack(loc2.translate('booking_sent'), AppColors.success);
      _clearForm();
    } else {
      // ✅ رسالة دقيقة حسب سبب الفشل
      final reason = result['reason'] as String? ?? '';
      String msg;
      if (reason == 'studio_booked') {
        msg = loc2.translate('studio_booked');
      } else if (reason == 'invalid_dates') {
        msg = loc2.translate('invalid_dates');
      } else if (reason.startsWith('auth_error')) {
        msg = 'Session expired. Please login again.';
      } else if (reason == 'invalid_studio') {
        msg = 'Please select a valid studio.';
      } else {
        msg = loc2.translate('booking_failed');
        safePrint('Booking failed — reason: $reason');
      }
      _snack(msg, AppColors.error);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _clearForm() {
    _firstNameCtrl.clear(); _lastNameCtrl.clear();
    _phoneCtrl.clear(); _fromDateCtrl.clear(); _toDateCtrl.clear();
    setState(() {
      selectedStudio = null; selectedEquipment = [];
      termsAccepted = false; _selectedIndex = 0;
      startHour = 10; endHour = 18;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc       = AppLocalizations.of(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bg        = isDark ? AppColors.darkBg  : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final size      = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final isTablet  = size.width >= 600;

    // ── body content ──────────────────────────────────────────────────────
    final bodyContent = _selectedIndex == 0
        ? _buildHomeView(isDark)
        : _buildBookingView(isDark, loc);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectedIndex != 0) setState(() => _selectedIndex = 0);
      },

      // ════════════════════════════════════════════════════════════════════
      // DESKTOP / TABLET — Persistent sidebar + no AppBar hamburger
      // ════════════════════════════════════════════════════════════════════
      child: isDesktop || isTablet
          ? Scaffold(
        backgroundColor: bg,
        body: Row(
          children: [
            // ── Persistent Side Navigation ──────────────────────────
            _SideNav(
              isDark: isDark,
              selectedIndex: _selectedIndex,
              isDesktop: isDesktop,
              onItemTapped: (i) => setState(() => _selectedIndex = i),
              onProfileUpdated: () => setState(() {}),
              onSupportTap: _handleSupportClick,
              onNotificationsTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              notificationsCount: appNotifications.length,
            ),

            // ── Main content ────────────────────────────────────────
            Expanded(
              child: Scaffold(
                backgroundColor: bg,
                // Chatbot FAB
                floatingActionButton: FloatingActionButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatbotScreen())),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
                ),
                // Top bar (no hamburger on desktop)
                appBar: AppBar(
                  backgroundColor: bg,
                  automaticallyImplyLeading: false,
                  title: Text(
                    _selectedIndex == 0
                        ? loc.translate('app_name')
                        : loc.translate('book_studio'),
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_outlined,
                                size: 20, color: AppColors.primary),
                            if (appNotifications.isNotEmpty)
                              Positioned(
                                top: -4, right: -4,
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen())),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                body: bodyContent,
              ),
            ),
          ],
        ),
      )

      // ════════════════════════════════════════════════════════════════
      // MOBILE — original Drawer layout
      // ════════════════════════════════════════════════════════════════
          : Scaffold(
        backgroundColor: bg,
        drawer: _AppDrawer(
          isDark: isDark,
          onItemTapped: (i) => setState(() => _selectedIndex = i),
          onProfileUpdated: () => setState(() {}),
          onSupportTap: _handleSupportClick,
        ),
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0
                ? loc.translate('app_name')
                : loc.translate('book_studio'),
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined,
                    size: 20, color: AppColors.primary),
              ),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen())),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        ),
        body: bodyContent,
      ),
    );
  }

  // ─── Home View ───────────────────────────────────────────────────────────────
  Widget _buildHomeView(bool isDark) {
    final loc        = AppLocalizations.of(context);
    final textColor  = isDark ? AppColors.darkText    : AppColors.lightText;
    final subText    = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor  = isDark ? AppColors.darkCard    : AppColors.lightSurface;
    final borderColor= isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final size       = MediaQuery.of(context).size;

    final isDesktopView = size.width >= 900;
    final hPadHome = isDesktopView ? size.width * 0.04 : size.width > 600 ? 40.0 : 20.0;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPadHome, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.translate('welcome_back'), style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(currentUser['name'] ?? 'User',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(loc.translate('instant_book'), style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                    ),
                  ),
                ]),
              ),
              const Icon(Icons.camera_alt_rounded, color: Colors.white38, size: 60),
            ]),
          ),

          const SizedBox(height: 28),

          Text(loc.translate('our_studios'), style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: textColor, letterSpacing: -0.5)),
          Text(loc.translate('app_tagline'), style: TextStyle(
              fontSize: 13, color: subText)),
          const SizedBox(height: 16),

          // Studio cards - responsive grid
          size.width > 900
              ? GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16, mainAxisSpacing: 16,
            childAspectRatio: 0.82,
            children: _studios.map((s) =>
                _studioCard(s, textColor, cardColor, borderColor)).toList(),
          )
              : size.width > 600
              ? GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16, mainAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: _studios.map((s) =>
                _studioCard(s, textColor, cardColor, borderColor)).toList(),
          )
              : Column(
            children: _studios.map((s) =>
                _studioCard(s, textColor, cardColor, borderColor)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _studioCard(Map<String, dynamic> studio, Color textColor,
      Color cardColor, Color borderColor) {
    final loc   = AppLocalizations.of(context);
    final title = studio['name'] as String? ?? '';
    final price = studio['pricePerHour'] as int? ?? 0;
    final type  = studio['type'] as String? ?? '';
    final available = studio['available'] as bool? ?? true;

    final Map<String, IconData> typeIcons = {
      'Portrait': Icons.portrait_rounded,
      'Product' : Icons.inventory_2_rounded,
      'Wedding' : Icons.favorite_rounded,
      'Video'   : Icons.videocam_rounded,
      'Fashion' : Icons.style_rounded,
    };
    final Map<String, Color> typeColors = {
      'Portrait': const Color(0xFF6C63FF),
      'Product' : const Color(0xFF22C55E),
      'Wedding' : const Color(0xFFEF4444),
      'Video'   : const Color(0xFF3B82F6),
      'Fashion' : const Color(0xFFF59E0B),
    };
    final accent = typeColors[type] ?? AppColors.primary;
    final icon   = typeIcons[type] ?? Icons.camera_alt_rounded;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => StudioDetailScreen(
            studio: studio,
            onBook: available ? () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 1;
                selectedStudio = title;
              });
            } : null,
          ))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  _studioImage(studio, accent, icon),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                      ),
                    ),
                  ),
                  Positioned(top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('\$$price/hr',
                          style: TextStyle(color: accent,
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  if (!available)
                    Positioned(top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('CLOSED',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 15, color: textColor)),
                      Text(type,
                          style: TextStyle(fontSize: 12, color: AppColors.darkSubText)),
                    ]),
                  ),
                  ElevatedButton(
                    onPressed: available ? () => setState(() {
                      _selectedIndex = 1;
                      selectedStudio = title;
                    }) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      disabledBackgroundColor: AppColors.darkSubText.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(loc.translate('book'), style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studioImage(Map<String, dynamic> studio, Color accent, IconData icon) {
    final image = studio['image'] as String?;

    // ✅ Base64 (legacy data من قبل ما تتحول لـ S3)
    if (image != null && image.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(image.split(',')[1]),
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gradientBox(accent, icon),
        );
      } catch (_) {
        return _gradientBox(accent, icon);
      }
    }

    // ✅ يشمل URLs العادية + الـ pre-signed URLs من S3
    if (image != null && (image.startsWith('http://') || image.startsWith('https://'))) {
      return Image.network(
        image,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: 600,
        errorBuilder: (_, __, ___) => _gradientBox(accent, icon),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _gradientBox(accent, icon);
        },
      );
    }
    return _gradientBox(accent, icon);
  }

  Widget _gradientBox(Color accent, IconData icon) => Container(
    height: 140, width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [accent, accent.withOpacity(0.6)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: Icon(icon, size: 50, color: Colors.white.withOpacity(0.25)),
  );

  // ─── Booking View ────────────────────────────────────────────────────────────
  Widget _buildBookingView(bool isDark, AppLocalizations loc) {
    final textColor  = isDark ? AppColors.darkText    : AppColors.lightText;
    final subText    = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final inputBg    = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor= isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final size       = MediaQuery.of(context).size;
    final hPad       = size.width > 600 ? 40.0 : 20.0;

    // لو الاستوديوهات لسه بتتحمل، عرض loading + زر retry
    if (_studios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text(loc.translate('loading_studios'),
                style: TextStyle(color: subText, fontSize: 14)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _fetchStudiosFromAPI,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              label: Text(loc.translate('retry'),
                  style: const TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price summary
            if (selectedStudio != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.12),
                        AppColors.gradientEnd.withOpacity(0.08)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.camera_indoor_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(selectedStudio!,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
                  Text('\$${_calculateTotalPrice()}',
                      style: const TextStyle(color: AppColors.primary,
                          fontWeight: FontWeight.w800, fontSize: 22)),
                ]),
              ),

            _sectionTitle(loc.translate('studio_section'), subText),
            const SizedBox(height: 8),
            _dropdown<String>(
              value: selectedStudio,
              hint: loc.translate('select_studio'),
              items: studioNames.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => selectedStudio = v),
              validator: (v) => v == null ? loc.translate('required') : null,
              fillColor: inputBg, borderColor: borderColor, textColor: textColor,
            ),

            const SizedBox(height: 20),
            _sectionTitle(loc.translate('personal_info'), subText),
            const SizedBox(height: 8),

            // Responsive row
            size.width > 500
                ? Row(children: [
              Expanded(child: _field(_firstNameCtrl, loc.translate('first_name'), inputBg, borderColor, textColor,
                  validator: (v) => (v?.isEmpty ?? true) ? loc.translate('required') : null)),
              const SizedBox(width: 12),
              Expanded(child: _field(_lastNameCtrl, loc.translate('last_name'), inputBg, borderColor, textColor)),
            ])
                : Column(children: [
              _field(_firstNameCtrl, loc.translate('first_name'), inputBg, borderColor, textColor,
                  validator: (v) => (v?.isEmpty ?? true) ? loc.translate('required') : null),
              const SizedBox(height: 12),
              _field(_lastNameCtrl, loc.translate('last_name'), inputBg, borderColor, textColor),
            ]),

            const SizedBox(height: 12),
            _field(_phoneCtrl, loc.translate('phone_number'), inputBg, borderColor, textColor,
                keyboardType: TextInputType.phone),

            const SizedBox(height: 20),
            _sectionTitle(loc.translate('start_date_time'), subText),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(_fromDateCtrl, loc.translate('start_date'), inputBg, borderColor, textColor,
                  readOnly: true, onTap: () => _selectDate(context, _fromDateCtrl),
                  validator: (v) => (v?.isEmpty ?? true) ? loc.translate('required') : null)),
              const SizedBox(width: 12),
              Expanded(child: _dropdown<int>(
                value: startHour,
                hint: loc.translate('hour'),
                items: hours.map((h) => DropdownMenuItem(value: h, child: Text('$h:00'))).toList(),
                onChanged: (v) => setState(() => startHour = v!),
                fillColor: inputBg, borderColor: borderColor, textColor: textColor,
              )),
            ]),

            const SizedBox(height: 16),
            _sectionTitle(loc.translate('end_date_time'), subText),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(_toDateCtrl, loc.translate('end_date'), inputBg, borderColor, textColor,
                  readOnly: true, onTap: () => _selectDate(context, _toDateCtrl),
                  validator: (v) => (v?.isEmpty ?? true) ? loc.translate('required') : null)),
              const SizedBox(width: 12),
              Expanded(child: _dropdown<int>(
                value: endHour,
                hint: loc.translate('hour'),
                items: hours.map((h) => DropdownMenuItem(value: h, child: Text('$h:00'))).toList(),
                onChanged: (v) => setState(() => endHour = v!),
                fillColor: inputBg, borderColor: borderColor, textColor: textColor,
              )),
            ]),

            const SizedBox(height: 20),
            _sectionTitle(loc.translate('extra_equipment'), subText),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: equipmentPrices.entries.map((e) {
                  final isLast = e.key == equipmentPrices.keys.last;
                  return Column(children: [
                    CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      title: Text(e.key, style: TextStyle(color: textColor, fontSize: 14)),
                      subtitle: Text('+\$${e.value}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                      value: selectedEquipment.contains(e.key),
                      onChanged: (v) => setState(() =>
                      v! ? selectedEquipment.add(e.key) : selectedEquipment.remove(e.key)),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    if (!isLast) Divider(height: 1, color: borderColor),
                  ]);
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: Text(loc.translate('agree_terms'),
                    style: TextStyle(color: textColor, fontSize: 13)),
                value: termsAccepted,
                onChanged: (v) => setState(() => termsAccepted = v!),
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),

            const SizedBox(height: 24),
            GenzButton(
              text: loc.translate('send_booking'),
              isLoading: _isSubmitting,
              onPressed: _submitBooking,
              icon: Icons.send_rounded,
              color: const Color(0xFFB71C1C),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.5));

  Widget _field(TextEditingController ctrl, String hint,
      Color fillColor, Color borderColor, Color textColor, {
        TextInputType? keyboardType,
        String? Function(String?)? validator,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value, required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    required Color fillColor, required Color borderColor, required Color textColor,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 14),
      dropdownColor: fillColor,
      decoration: InputDecoration(
        filled: true, fillColor: fillColor,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

// ─── Side Navigation (Tablet / Desktop) ──────────────────────────────────────

class _SideNav extends StatefulWidget {
  final bool isDark;
  final bool isDesktop;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onProfileUpdated;
  final Future<void> Function() onSupportTap;
  final VoidCallback onNotificationsTap;
  final int notificationsCount;

  const _SideNav({
    required this.isDark,
    required this.isDesktop,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onProfileUpdated,
    required this.onSupportTap,
    required this.onNotificationsTap,
    required this.notificationsCount,
  });

  @override
  State<_SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<_SideNav> {
  bool _isLoadingChat = false;

  @override
  void initState() {
    super.initState();
    SettingsService.locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SettingsService.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc         = AppLocalizations.of(context);
    final isDark      = widget.isDark;
    final bg          = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final textColor   = isDark ? AppColors.darkText    : AppColors.lightText;
    final subColor    = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    // Tablet: icon rail only (56px). Desktop: full sidebar (220px)
    final navWidth = widget.isDesktop ? 220.0 : 68.0;

    ImageProvider getImg() {
      final p = currentUser['image'] ?? '';
      if (p.isEmpty) return const AssetImage('images/Gnz.png');
      if (p.startsWith('http')) return NetworkImage(p);
      // ✅ fallback for Web/Windows
      return const AssetImage('images/Gnz.png');
    }

    final navItems = [
      _NavItem(Icons.home_rounded,              loc.translate('home'),          0),
      _NavItem(Icons.calendar_month_rounded,    loc.translate('my_bookings'),   -1),
      _NavItem(Icons.confirmation_number_rounded,'My Tickets',                  -2, iconColor: const Color(0xFF8B5CF6)),
      _NavItem(Icons.support_agent_rounded,     loc.translate('support_chat'),  -3, iconColor: AppColors.primary),
      _NavItem(Icons.notifications_rounded,     loc.translate('notifications'), -4, iconColor: AppColors.warning,
          badge: widget.notificationsCount),
      _NavItem(Icons.event_available_rounded,   loc.translate('book_studio'),   1),
      _NavItem(Icons.settings_rounded,          loc.translate('settings'),      -5),
    ];

    return Container(
      width: navWidth,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Profile header ────────────────────────────────────────────
            GestureDetector(
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
                widget.onProfileUpdated();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(widget.isDesktop ? 16 : 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                ),
                child: widget.isDesktop
                    ? Row(children: [
                  CircleAvatar(
                    key: ValueKey(currentUser['image'] ?? ''),
                    radius: 22,
                    backgroundImage: getImg(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentUser['name'] ?? 'User',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        Text(currentUser['email'] ?? '',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined,
                      color: Colors.white70, size: 14),
                ])
                    : Center(
                  child: CircleAvatar(
                    key: ValueKey(currentUser['image'] ?? ''),
                    radius: 20,
                    backgroundImage: getImg(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Nav Items ─────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: navItems.map((item) {
                  final isSelected = widget.selectedIndex == item.index;
                  return _buildNavTile(
                    context: context,
                    item: item,
                    isSelected: isSelected,
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                  );
                }).toList(),
              ),
            ),

            // ── Logout ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildNavTile(
                context: context,
                item: _NavItem(Icons.logout_rounded, loc.translate('logout'), -99,
                    iconColor: AppColors.error),
                isSelected: false,
                isDark: isDark,
                textColor: AppColors.error,
                subColor: AppColors.error,
                onTap: () async {
                  await AWSStorageService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required _NavItem item,
    required bool isSelected,
    required bool isDark,
    required Color textColor,
    required Color subColor,
    VoidCallback? onTap,
  }) {
    final activeColor  = item.iconColor ?? AppColors.primary;
    final activeBg     = activeColor.withOpacity(0.1);
    final color        = isSelected ? activeColor : (item.iconColor ?? subColor);

    return Tooltip(
      message: widget.isDesktop ? '' : item.label,
      child: InkWell(
        onTap: onTap ?? () => _handleNavTap(context, item.index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
              horizontal: widget.isDesktop ? 12 : 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: activeColor.withOpacity(0.25))
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.isDesktop
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, size: 20, color: color),
                  if ((item.badge ?? 0) > 0)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              if (widget.isDesktop) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.label,
                      style: TextStyle(
                          color: isSelected ? activeColor : textColor,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNavTap(BuildContext context, int index) async {
    if (index == 0 || index == 1) {
      widget.onItemTapped(index);
      return;
    }
    switch (index) {
      case -1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
        break;
      case -2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
        break;
      case -3:
        if (!_isLoadingChat) {
          setState(() => _isLoadingChat = true);
          await widget.onSupportTap();
          if (mounted) setState(() => _isLoadingChat = false);
        }
        break;
      case -4:
        widget.onNotificationsTap();
        break;
      case -5:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
      case -99:
        await AWSStorageService.signOut();
        if (context.mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()));
        }
        break;
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  final Color? iconColor;
  final int? badge;
  const _NavItem(this.icon, this.label, this.index,
      {this.iconColor, this.badge});
}


// ─── App Drawer ───────────────────────────────────────────────────────────────
class _AppDrawer extends StatefulWidget {
  final Function(int) onItemTapped;
  final VoidCallback onProfileUpdated;
  final Future<void> Function() onSupportTap;
  final bool isDark;

  const _AppDrawer({
    required this.onItemTapped,
    required this.onProfileUpdated,
    required this.onSupportTap,
    required this.isDark,
  });

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  bool _isLoadingChat = false;

  @override
  void initState() {
    super.initState();
    SettingsService.locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SettingsService.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final bg    = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text  = isDark ? AppColors.darkText    : AppColors.lightText;
    final sub   = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final border= isDark ? AppColors.darkBorder  : AppColors.lightBorder;

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
        child: Column(
          children: [
            // Profile header
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const ProfileScreen()));
                widget.onProfileUpdated();
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                ),
                child: Row(children: [
                  CircleAvatar(
                    key: ValueKey(currentUser['image'] ?? ''),
                    radius: 28,
                    backgroundImage: getImg(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser['name'] ?? 'User',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(currentUser['email'] ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.7),
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                ]),
              ),
            ),

            Divider(height: 1, color: border),
            const SizedBox(height: 8),

            _tile(context, Icons.home_rounded, loc.translate('home'), text, sub, () {
              widget.onItemTapped(0); Navigator.pop(context);
            }),
            _tile(context, Icons.calendar_month_rounded, loc.translate('my_bookings'), text, sub, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
            }),
            _tile(context, Icons.confirmation_number_rounded, 'My Tickets', text, sub, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
            }, iconColor: const Color(0xFF8B5CF6)),
            _isLoadingChat
                ? ListTile(
              leading: const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              title: Text(loc.translate('support_chat'),
                  style: TextStyle(color: text, fontWeight: FontWeight.w500)),
            )
                : _tile(context, Icons.support_agent_rounded, loc.translate('support_chat'), text, sub, () async {
              Navigator.pop(context);
              if (mounted) setState(() => _isLoadingChat = true);
              await widget.onSupportTap();
              if (mounted) setState(() => _isLoadingChat = false);
            }, iconColor: AppColors.primary),
            _tile(context, Icons.notifications_rounded, loc.translate('notifications'), text, sub, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            }, iconColor: AppColors.warning),
            _tile(context, Icons.settings_rounded, loc.translate('settings'), text, sub, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),

            const Spacer(),
            Divider(height: 1, color: border),

            _tile(context, Icons.logout_rounded, loc.translate('logout'), AppColors.error,
                AppColors.error, () async {
                  await AWSStorageService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()));
                  }
                }, iconColor: AppColors.error),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      Color textColor, Color subColor, VoidCallback onTap, {Color? iconColor}) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: (iconColor ?? subColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? subColor),
      ),
      title: Text(label, style: TextStyle(color: textColor,
          fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}