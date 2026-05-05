import 'package:amplify_flutter/amplify_flutter.dart';

class AuthManager {
  static String? _cachedEmail;
  static String? _cachedName;

  /// 🧠 هل المستخدم logged in؟
  static Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (_) {
      return false;
    }
  }

  /// 📧 هات الإيميل من Cognito (المصدر الحقيقي)
  static Future<String> getEmail() async {
    if (_cachedEmail != null) return _cachedEmail!;

    final attrs = await Amplify.Auth.fetchUserAttributes();

    for (final attr in attrs) {
      if (attr.userAttributeKey.key == 'email') {
        _cachedEmail = attr.value.trim().toLowerCase();
        return _cachedEmail!;
      }
    }

    throw Exception('Email not found in Cognito');
  }

  /// 👤 اسم المستخدم
  static Future<String> getName() async {
    if (_cachedName != null) return _cachedName!;

    final attrs = await Amplify.Auth.fetchUserAttributes();

    for (final attr in attrs) {
      if (attr.userAttributeKey.key == 'name') {
        _cachedName = attr.value;
        return _cachedName!;
      }
    }

    return 'User';
  }

  /// 🔄 Sync مع currentUser القديم (لو لسه محتاجه)
  static Future<void> syncToLocal(Map<String, dynamic> currentUser) async {
    currentUser['email'] = await getEmail();
    currentUser['name'] = await getName();
  }

  /// 🚪 logout
  static Future<void> signOut() async {
    await Amplify.Auth.signOut();
    _cachedEmail = null;
    _cachedName = null;
  }
}