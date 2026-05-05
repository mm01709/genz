// lib/screens/my_bookings_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:amplify_api/amplify_api.dart';
import 'package:genz/models/ModelProvider.dart';
import 'package:genz/data/data.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/screens/BookingDetailScreen.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/services/settings_service.dart';
import 'package:genz/theme/app_theme.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _bookingsSubscription;
  Timer? _bookingsPollingTimer;
  List<Map<String, String>> _myBookings = [];
  bool _isLoading = true;

  final List<String> _tabs = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    SettingsService.locale.addListener(_onLocaleChanged);
    _listenToBookings();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookingsSubscription?.cancel();
    _bookingsPollingTimer?.cancel();
    SettingsService.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  // ✅ DataStore معطل — API polling على كل الـ platforms
  bool get _isNative => false;

  void _listenToBookings() async {
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
      _bookingsSubscription?.cancel();
      _bookingsSubscription = AWSStorageService.observeBookings(
        clientEmail: email,
      ).listen((items) {
        if (!mounted) return;
        if (items.isEmpty) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        _processBookings(items.map((b) => <String, String>{
          'id': b.id,
          'clientEmail': b.clientEmail,
          'clientName': b.clientName ?? '',
          'clientPhone': b.clientPhone ?? '',
          'studio': b.studio,
          'date': b.date,
          'hours': b.hours,
          'price': b.price,
          'equipment': b.equipment ?? '',
          'status': b.status ?? 'Pending',
          'fullStartDateTime': b.fullStartDateTime,
          'fullEndDateTime': b.fullEndDateTime,
        }).toList());
      });
    } else {
      // ✅ Web/Windows: poll every 5s
      _fetchBookingsFromAPI(email);
      _bookingsPollingTimer = Timer.periodic(
        const Duration(seconds: 5),
            (_) => _fetchBookingsFromAPI(email),
      );
    }
  }

  Future<void> _fetchBookingsFromAPI(String email) async {
    try {
      final response = await Amplify.API.query(
        request: ModelQueries.list(
          BookingRequest.classType,
          where: BookingRequest.CLIENTEMAIL.eq(email),
          limit: 1000,
        ),
      ).response;
      final results =
          response.data?.items.whereType<BookingRequest>().toList() ?? [];
      _processBookings(results.map((b) => <String, String>{
        'id': b.id,
        'clientEmail': b.clientEmail,
        'clientName': b.clientName ?? '',
        'clientPhone': b.clientPhone ?? '',
        'studio': b.studio,
        'date': b.date,
        'hours': b.hours,
        'price': b.price,
        'equipment': b.equipment ?? '',
        'status': b.status ?? 'Pending',
        'fullStartDateTime': b.fullStartDateTime,
        'fullEndDateTime': b.fullEndDateTime,
      }).toList());
    } catch (e) {
      safePrint('fetchBookingsFromAPI (MyBookings) error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processBookings(List<Map<String, String>> mapped) {
    mapped.sort((a, b) {
      final aDate = a['fullStartDateTime'] ?? '';
      final bDate = b['fullStartDateTime'] ?? '';
      return bDate.compareTo(aDate);
    });
    if (mounted) setState(() {
      _myBookings = mapped;
      _isLoading = false;
    });
  }

  List<Map<String, String>> get _filteredBookings {
    final tab = _tabs[_tabController.index];
    if (tab == 'All') return _myBookings;
    return _myBookings.where((b) => b['status'] == tab).toList();
  }

  Future<void> _cancelBooking(int index, Map<String, String> booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkCard : Colors.white;
        final textColor = isDark ? AppColors.darkText : AppColors.lightText;
        return AlertDialog(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Cancel Booking',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
          content: Text(
            AppLocalizations.of(context).translate('confirm_cancel_booking'),
            style: TextStyle(
                color: isDark ? AppColors.darkSubText : AppColors.lightSubText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context).translate('no'),
                  style: const TextStyle(color: AppColors.darkSubText)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context).translate('yes'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final bookingId = booking['id'] ?? '';
    if (bookingId.isEmpty) return;

    final ok = await AWSStorageService.deleteBooking(bookingId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? AppLocalizations.of(context).translate('booking_cancelled')
            : AppLocalizations.of(context).translate('error')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }

  Future<void> _updateStatus(int index, String newStatus) async {
    final booking = _filteredBookings[index];
    await AWSStorageService.updateBookingStatus(booking['id'] ?? '', newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // ── Responsive breakpoints ────────────────────────────────────────────────
    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 900;
    final crossCount = isDesktop ? 3 : (isTablet ? 2 : 1);
    final hPad = isDesktop
        ? size.width * 0.08
        : isTablet
        ? size.width * 0.05
        : 16.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          loc.translate('my_bookings'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: subText,
            labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: _tabs.map((t) {
              final count = t == 'All'
                  ? _myBookings.length
                  : _myBookings.where((b) => b['status'] == t).length;
              return Tab(
                child: Row(children: [
                  Text(t),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$count',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ],
                ]),
              );
            }).toList(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5))
          : TabBarView(
        controller: _tabController,
        children: _tabs.map((_) {
          final bookings = _filteredBookings;

          if (bookings.isEmpty) return _buildEmpty(loc, subText);

          // ── Grid for tablet/desktop ─────────────────────────────────
          if (crossCount > 1) {
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.6 : 1.45,
              ),
              itemCount: bookings.length,
              itemBuilder: (ctx, i) => _BookingCard(
                booking: bookings[i],
                textColor: textColor,
                subText: subText,
                cardColor: cardColor,
                borderColor: borderColor,
                isCompact: true,
                onTap: () => _openDetail(ctx, bookings, i),
                onCancel: bookings[i]['status'] == 'Pending'
                    ? () => _cancelBooking(i, bookings[i])
                    : null,
              ),
            );
          }

          // ── List for phones ─────────────────────────────────────────
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
            itemCount: bookings.length,
            itemBuilder: (ctx, i) => _BookingCard(
              booking: bookings[i],
              textColor: textColor,
              subText: subText,
              cardColor: cardColor,
              borderColor: borderColor,
              isCompact: false,
              onTap: () => _openDetail(ctx, bookings, i),
              onCancel: bookings[i]['status'] == 'Pending'
                  ? () => _cancelBooking(i, bookings[i])
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openDetail(
      BuildContext ctx, List<Map<String, String>> bookings, int i) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          booking: bookings[i],
          index: i,
          onUpdateStatus: _updateStatus,
          onDelete: (idx) => _cancelBooking(idx, bookings[idx]),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations loc, Color subText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: subText.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(loc.translate('no_bookings'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: subText)),
          const SizedBox(height: 8),
          Text(loc.translate('no_bookings_sub'),
              style:
              TextStyle(fontSize: 13, color: subText.withOpacity(0.7))),
        ],
      ),
    );
  }
}

// ─── Booking Card Widget ──────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, String> booking;
  final Color textColor;
  final Color subText;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final bool isCompact;

  const _BookingCard({
    required this.booking,
    required this.textColor,
    required this.subText,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
    required this.isCompact,
    this.onCancel,
  });

  Color get _statusColor {
    switch (booking['status']) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData get _statusIcon {
    switch (booking['status']) {
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'Pending';
    final isPending = status == 'Pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: isCompact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Status header ─────────────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.08),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                border:
                Border(bottom: BorderSide(color: _statusColor.withOpacity(0.2))),
              ),
              child: Row(children: [
                Icon(_statusIcon, color: _statusColor, size: 15),
                const SizedBox(width: 6),
                Text(status,
                    style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const Spacer(),
                Text('\$${booking['price'] ?? '0'}',
                    style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ]),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Studio name
                  Row(children: [
                    const Icon(Icons.camera_indoor_rounded,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(booking['studio'] ?? '-',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: AppColors.darkSubText),
                  ]),
                  const SizedBox(height: 9),

                  // Date & hours chips
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _chip(Icons.calendar_today_rounded, booking['date'] ?? '-'),
                    _chip(Icons.access_time_rounded, booking['hours'] ?? '-'),
                    if (booking['equipment']?.isNotEmpty == true)
                      _chip(Icons.camera_alt_rounded, booking['equipment']!,
                          chipColor: AppColors.primary.withOpacity(0.08),
                          chipTextColor: AppColors.primary),
                  ]),

                  // Cancel button — list layout only
                  if (!isCompact && isPending && onCancel != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded,
                            size: 15, color: AppColors.error),
                        label: const Text('Cancel Booking',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.error.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label,
      {Color? chipColor, Color? chipTextColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor ?? Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: chipTextColor ?? AppColors.darkSubText),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: chipTextColor ?? AppColors.darkSubText,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}