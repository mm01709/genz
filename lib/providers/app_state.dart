// lib/providers/app_state.dart
// ═══════════════════════════════════════════════════════════════════════════════
// AppState — central state management بـ ChangeNotifier
// ─────────────────────────────────────────────────────────────────────────────
// بديل صحي للـ global variables (bookingRequests, appNotifications...)
// بيدير الـ subscriptions تلقائياً + بيعمل setState مرتب لـ الـ UI
//
// Usage:
//   في main.dart:
//     ChangeNotifierProvider(create: (_) => AppState())
//   في widgets:
//     final state = context.watch<AppState>();
//     state.bookings, state.notifications, etc.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/models/ModelProvider.dart';

class AppState extends ChangeNotifier {
  // ─── Current User ────────────────────────────────────────────────────────
  String _email = '';
  String _name = '';
  String _userType = '';
  String _userImage = '';
  bool _chatEnabled = true;

  String get email => _email;
  String get name => _name;
  String get userType => _userType;
  String get userImage => _userImage;
  bool get chatEnabled => _chatEnabled;
  bool get isEmployee => _userType == 'employee';
  bool get isClient => _userType == 'client';
  bool get isSignedIn => _email.isNotEmpty;

  void setUser({
    required String email,
    required String name,
    required String type,
    String? image,
    bool chatEnabled = true,
  }) {
    _email = email;
    _name = name;
    _userType = type;
    _userImage = image ?? '';
    _chatEnabled = chatEnabled;
    notifyListeners();
  }

  void clearUser() {
    _email = '';
    _name = '';
    _userType = '';
    _userImage = '';
    _chatEnabled = true;
    _bookings.clear();
    _notifications.clear();
    _studios.clear();
    _disposeAllSubs();
    notifyListeners();
  }

  // ─── Studios ─────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _studios = [];
  List<Map<String, dynamic>> get studios => List.unmodifiable(_studios);
  bool _studiosLoading = false;
  bool get studiosLoading => _studiosLoading;

  StreamSubscription<Studio>? _studiosSub;

  Future<void> loadStudios() async {
    _studiosLoading = true;
    notifyListeners();
    try {
      final list = await AWSStorageService.loadStudios();
      _studios
        ..clear()
        ..addAll(list);
    } finally {
      _studiosLoading = false;
      notifyListeners();
    }
  }

  void startStudiosSubscription() {
    _studiosSub?.cancel();
    _studiosSub = AWSStorageService.subscribeToStudios().listen((studio) {
      // ✅ Re-fetch full list (ensures pre-signed URLs are fresh)
      loadStudios();
    });
  }

  // ─── Bookings ────────────────────────────────────────────────────────────
  final List<Map<String, String>> _bookings = [];
  List<Map<String, String>> get bookings => List.unmodifiable(_bookings);
  bool _bookingsLoading = false;
  bool get bookingsLoading => _bookingsLoading;

  StreamSubscription<BookingRequest>? _bookingsSub;

  Future<void> loadBookings() async {
    _bookingsLoading = true;
    notifyListeners();
    try {
      final list = await AWSStorageService.loadBookings(limit: 100);
      _bookings
        ..clear()
        ..addAll(list);
      _sortBookings();
    } finally {
      _bookingsLoading = false;
      notifyListeners();
    }
  }

  void startBookingsSubscription() {
    if (_email.isEmpty) return;

    _bookingsSub?.cancel();
    _bookingsSub = AWSStorageService.subscribeToBookings(
      clientEmail: isEmployee ? null : _email,
    ).listen((b) {
      // ✅ تحديث الحجز في الـ list أو إضافته
      final map = {
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
      };

      final idx = _bookings.indexWhere((x) => x['id'] == b.id);
      if (idx >= 0) {
        _bookings[idx] = map;
      } else {
        _bookings.add(map);
      }
      _sortBookings();
      notifyListeners();
    });
  }

  void _sortBookings() {
    _bookings.sort((a, b) =>
        (b['fullStartDateTime'] ?? '').compareTo(a['fullStartDateTime'] ?? ''));
  }

  /// ✅ Atomic booking — يستخدم الـ server-side check
  Future<({bool success, String? reason})> createBooking(
      Map<String, String> booking,
      ) async {
    final result = await AWSStorageService.saveBookingAtomic(booking);
    if (result['success'] == true) {
      // الـ subscription هيحدّث الـ list تلقائياً
      return (success: true, reason: null);
    }
    return (success: false, reason: result['reason'] as String?);
  }

  Future<bool> updateBookingStatus(String id, String newStatus) async {
    final ok = await AWSStorageService.updateBookingStatus(id, newStatus);
    if (ok) {
      final idx = _bookings.indexWhere((b) => b['id'] == id);
      if (idx >= 0) {
        _bookings[idx] = {..._bookings[idx], 'status': newStatus};
        notifyListeners();
      }
    }
    return ok;
  }

  Future<bool> deleteBooking(String id) async {
    final ok = await AWSStorageService.deleteBooking(id);
    if (ok) {
      _bookings.removeWhere((b) => b['id'] == id);
      notifyListeners();
    }
    return ok;
  }

  // ─── Notifications ───────────────────────────────────────────────────────
  final List<Map<String, String>> _notifications = [];
  List<Map<String, String>> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadNotificationsCount =>
      _notifications.where((n) => n['read'] != 'true').length;

  StreamSubscription<AppNotification>? _notifsSub;

  Future<void> loadNotifications() async {
    if (_email.isEmpty) return;
    final targetEmail = isEmployee ? 'EMPLOYEE_INBOX' : _email;
    final list = await AWSStorageService.loadNotifications(
      clientEmail: targetEmail,
    );
    _notifications
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  void startNotificationsSubscription() {
    if (_email.isEmpty) return;
    final targetEmail = isEmployee ? 'EMPLOYEE_INBOX' : _email;

    _notifsSub?.cancel();
    _notifsSub =
        AWSStorageService.subscribeToNotifications(targetEmail).listen((n) {
          final map = {
            'id': n.id,
            'clientEmail': n.clientEmail,
            'title': n.title ?? '',
            'body': n.body ?? '',
            'type': n.type ?? '',
            'time': n.time ?? '',
            'read': (n.read ?? false).toString(),
          };
          // unique by id
          final idx = _notifications.indexWhere((x) => x['id'] == n.id);
          if (idx >= 0) {
            _notifications[idx] = map;
          } else {
            _notifications.insert(0, map);
          }
          notifyListeners();
        });
  }

  Future<void> markNotificationRead(String id) async {
    await AWSStorageService.markNotificationRead(id);
    final idx = _notifications.indexWhere((n) => n['id'] == id);
    if (idx >= 0) {
      _notifications[idx] = {..._notifications[idx], 'read': 'true'};
      notifyListeners();
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────
  void _disposeAllSubs() {
    _studiosSub?.cancel();
    _bookingsSub?.cancel();
    _notifsSub?.cancel();
    _studiosSub = null;
    _bookingsSub = null;
    _notifsSub = null;
  }

  @override
  void dispose() {
    _disposeAllSubs();
    super.dispose();
  }
}