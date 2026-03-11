import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StorageService: يستخدم SharedPreferences فقط (بدون ملفات خارجية)
// البيانات الحقيقية (bookings / messages / notifications) تُخزَّن في AWS
// هذا الملف مسؤول فقط عن: currentUser + guest + إعدادات الشات
// ─────────────────────────────────────────────────────────────────────────────

class StorageService {
  // ─── Current User ───────────────────────────────────────────────────────────

  static Future<void> saveCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser_name', currentUser['name'] ?? '');
    await prefs.setString('currentUser_image', currentUser['image'] ?? '');
    await prefs.setString('currentUser_type', currentUser['type'] ?? 'guest');
    await prefs.setString('currentUser_email', currentUser['email'] ?? '');
  }

  static Future<void> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUser['name'] = prefs.getString('currentUser_name') ?? '';
    currentUser['image'] = prefs.getString('currentUser_image') ?? '';
    currentUser['type'] = prefs.getString('currentUser_type') ?? 'guest';
    currentUser['email'] = prefs.getString('currentUser_email') ?? '';
  }

  static Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser_name');
    await prefs.remove('currentUser_image');
    await prefs.remove('currentUser_type');
    await prefs.remove('currentUser_email');

    currentUser['name'] = '';
    currentUser['image'] = '';
    currentUser['type'] = 'guest';
    currentUser['email'] = '';
  }

  // ─── Permanent Guest ────────────────────────────────────────────────────────

  static Future<void> savePermanentGuest(
      String name, String image, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('permanent_guest_name', name);
    await prefs.setString('permanent_guest_image', image);
    await prefs.setString('permanent_guest_email', email);
  }

  static Future<Map<String, String>> loadPermanentGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('permanent_guest_name');
    if (name == null) return {};
    return {
      'name': name,
      'image': prefs.getString('permanent_guest_image') ?? '',
      'email': prefs.getString('permanent_guest_email') ?? '',
    };
  }

  // ─── Chat Settings (enabled emails + clear timestamps) ─────────────────────
  // NOTE: الحجوزات والرسائل والإشعارات تُدار الآن بالكامل من AWSStorageService

  static Future<void> saveChatSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('enabledChatEmails', enabledChatEmails);
    await prefs.setString(
        'clientChatClearTimestamps', jsonEncode(clientChatClearTimestamps));
  }

  static Future<void> loadChatSettings() async {
    final prefs = await SharedPreferences.getInstance();
    enabledChatEmails = prefs.getStringList('enabledChatEmails') ?? [];
    final clearJson = prefs.getString('clientChatClearTimestamps');
    if (clearJson != null) {
      clientChatClearTimestamps =
      Map<String, String>.from(jsonDecode(clearJson));
    }
  }

  // ─── Legacy stubs (kept for backward compatibility) ─────────────────────────
  // These are no-ops — data is now handled by AWSStorageService

  static Future<void> saveBookings() async {}
  static Future<void> loadBookings() async {}
  static Future<void> saveMessages() async {}
  static Future<void> loadMessages() async {}
  static Future<void> loadClients() async {}
  static Future<void> saveClients() async {}
}