// lib/services/chatbot_booking_service.dart
//
// ربط الشات بوت بنظام الحجز الحقيقي (Amplify / BookingRequest).
//
// الفكرة:
//   - السيرفر (الـ AI) لما يجمع كل تفاصيل الحجز من العميل، بيطلّع في رده
//     "بطاقة حجز" مخفية بالصيغة دي:
//
//        [[BOOKING]]{"studio":"Studio A","date":"2026-06-09","startHour":14,
//                    "duration":"hourly","endHour":16,
//                    "clientName":"Ahmed","clientPhone":"0100..."}[[/BOOKING]]
//
//   - التطبيق (هنا) بيمسك البطاقة دي، بيحسب السعر والوقت بنفسه من بيانات
//     الاستوديوهات الحقيقية (اللي جاية من Amplify) — مش بيثق في حساب الـ AI —
//     وبيكتب الحجز فعلياً عن طريق نفس المسار العادي (saveBookingAtomic)
//     مع علامة إن "الحجز اتعمل عن طريق الشات بوت".
//
//   - الموظف بيشوف الحجز ده زي أي حجز عادي + بيوصله إشعار.
//
// كده الـ AI "بيحجز" فعلياً، والحجز بيبان للموظف زي ما طلبت بالظبط.

import 'dart:convert';
import 'package:genz/data/aws_storage.dart';

/// علامة بتتحط في حقل equipment عشان الموظف يعرف إن الحجز جه من البوت.
const String kChatbotBookingTag = '🤖 Booked via Chatbot';

/// مواعيد العمل (لازم تطابق اللي في client_screen / السيرفر)
const int _kOpenHour = 9; // 9 صباحاً
const int _kCloseHour = 19; // 7 مساءً (آخر حجز يبدأ 6م)

/// نتيجة محاولة الحجز من الشات بوت.
class ChatbotBookingResult {
  final bool success;

  /// سبب الفشل (لو فشل) — جاهز للعرض للعميل.
  final String? reason;

  /// تفاصيل الحجز اللي اتعمل (لو نجح).
  final Map<String, String>? booking;

  const ChatbotBookingResult({
    required this.success,
    this.reason,
    this.booking,
  });
}

class ChatbotBookingService {
  /// بيدوّر على بطاقة حجز [[BOOKING]]...[[/BOOKING]] جوّا رد الـ AI.
  /// بيرجّع الـ JSON كـ Map لو لقاها، أو null لو الرد عادي.
  static Map<String, dynamic>? extractBookingIntent(String aiReply) {
    final match = _bookingRegex.firstMatch(aiReply);
    if (match == null) return null;
    final raw = match.group(1)?.trim();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      // الـ AI طلّع JSON بايظ — نتجاهل البطاقة ونسيب الرد نصّي عادي.
      return null;
    }
  }

  /// بيشيل بطاقة الحجز من النص عشان العميل ميشوفش الـ JSON الخام.
  static String stripBookingIntent(String aiReply) {
    return aiReply.replaceAll(_bookingRegex, '').trim();
  }

  static final RegExp _bookingRegex = RegExp(
    r'\[\[BOOKING\]\](.*?)\[\[/BOOKING\]\]',
    dotAll: true,
  );

  /// بياخد نية الحجز اللي طلّعها الـ AI + قائمة الاستوديوهات الحقيقية،
  /// بيحسب السعر/الوقت بنفسه، وبينفّذ الحجز عبر المسار الرسمي.
  ///
  /// [intent]  = الـ Map اللي رجّعته extractBookingIntent.
  /// [studios] = نفس بيانات الاستوديوهات اللي بيستخدمها الحجز العادي
  ///             (AWSStorageService.loadStudios) — فيها name + pricePerHour.
  static Future<ChatbotBookingResult> confirmBooking({
    required Map<String, dynamic> intent,
    required List<Map<String, dynamic>> studios,
  }) async {
    // ── 1) اطلع البيانات من نية الحجز ─────────────────────────────────
    final studioName = (intent['studio'] ?? '').toString().trim();
    final dateStr = (intent['date'] ?? '').toString().trim(); // YYYY-MM-DD
    final duration = (intent['duration'] ?? 'hourly').toString().trim();
    final startHour = _asInt(intent['startHour']);
    final clientName = (intent['clientName'] ?? '').toString().trim();
    final clientPhone = (intent['clientPhone'] ?? '').toString().trim();

    if (studioName.isEmpty || dateStr.isEmpty || startHour == null) {
      return const ChatbotBookingResult(
        success: false,
        reason: 'missing_info',
      );
    }

    // ── 2) لاقي الاستوديو الحقيقي وسعره من Amplify ───────────────────
    final studioData = studios.firstWhere(
      (s) => (s['name'] ?? '').toString().trim() == studioName,
      orElse: () => const {},
    );
    if (studioData.isEmpty) {
      return const ChatbotBookingResult(
        success: false,
        reason: 'studio_not_found',
      );
    }
    final pricePerHour = (studioData['pricePerHour'] as int?) ?? 0;

    // ── 3) احسب وقت البداية/النهاية والمدة بالساعات ──────────────────
    final start = DateTime.tryParse(
      '$dateStr ${startHour.toString().padLeft(2, '0')}:00:00',
    );
    if (start == null) {
      return const ChatbotBookingResult(
        success: false,
        reason: 'invalid_dates',
      );
    }

    // تحقّق من مواعيد العمل (نفس قواعد الحجز العادي)
    if (start.weekday == DateTime.friday) {
      return const ChatbotBookingResult(
        success: false,
        reason: 'closed_friday',
      );
    }
    if (start.hour < _kOpenHour || start.hour >= _kCloseHour) {
      return const ChatbotBookingResult(
        success: false,
        reason: 'outside_working_hours',
      );
    }

    int hours;
    DateTime end;
    String hoursLabel;
    if (duration == 'half_day') {
      hours = 4;
      end = start.add(const Duration(hours: 4));
      hoursLabel = 'Half Day (4h) - ${startHour.toString().padLeft(2, '0')}:00';
    } else if (duration == 'full_day') {
      hours = 8;
      end = start.add(const Duration(hours: 8));
      hoursLabel = 'Full Day (8h) - ${startHour.toString().padLeft(2, '0')}:00';
    } else {
      // hourly — محتاجين endHour
      final endHour = _asInt(intent['endHour']) ?? (startHour + 1);
      hours = endHour - startHour;
      if (hours <= 0) {
        return const ChatbotBookingResult(
          success: false,
          reason: 'invalid_dates',
        );
      }
      end = start.add(Duration(hours: hours));
      hoursLabel =
          '$hours h - ${startHour.toString().padLeft(2, '0')}:00 to ${endHour.toString().padLeft(2, '0')}:00';
    }

    // لازم الحجز كله جوّا مواعيد العمل
    if (end.hour > _kCloseHour ||
        (end.hour == _kCloseHour && end.minute > 0) ||
        end.day != start.day) {
      return const ChatbotBookingResult(
        success: false,
        reason: 'outside_working_hours',
      );
    }

    // ── 4) التطبيق هو اللي بيحسب السعر (مش الـ AI) ───────────────────
    final totalPrice = pricePerHour * hours;

    // ── 5) جهّز الحجز بنفس صيغة الحجز العادي بالظبط ──────────────────
    final booking = <String, String>{
      'clientName': clientName,
      'clientPhone': clientPhone,
      'studio': studioName,
      'fullStartDateTime': start.toIso8601String(),
      'fullEndDateTime': end.toIso8601String(),
      'date': dateStr,
      'hours': hoursLabel,
      'status': 'Pending',
      'price': totalPrice.toString(),
      // العلامة اللي بتخلّي الموظف يعرف إن البوت حجز
      'equipment': kChatbotBookingTag,
    };

    // ── 6) نفّذ الحجز عبر المسار الرسمي (auth + conflict checks) ─────
    final result = await AWSStorageService.saveBookingAtomic(booking);
    if (result['success'] != true) {
      return ChatbotBookingResult(
        success: false,
        reason: (result['reason'] ?? 'server_error').toString(),
      );
    }

    final saved = Map<String, String>.from(
      (result['booking'] as Map).map((k, v) => MapEntry('$k', '$v')),
    );

    // ── 7) ابعت إشعار للموظفين (زي الحجز العادي) ────────────────────
    try {
      await AWSStorageService.sendNotification(
        clientEmail: AWSStorageService.employeeInboxKey,
        title: 'New Chatbot Booking',
        body:
            '$clientName booked $studioName on $dateStr ($hoursLabel) — via Chatbot',
        type: 'booking',
      );
    } catch (_) {
      // فشل الإشعار مش بيلغي الحجز — الحجز اتسجّل بالفعل.
    }

    return ChatbotBookingResult(success: true, booking: saved);
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }
}
