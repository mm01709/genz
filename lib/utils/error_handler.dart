// lib/utils/error_handler.dart
// ═══════════════════════════════════════════════════════════════════════════════
// ErrorHandler — تحويل exceptions لرسائل واضحة للمستخدم
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  /// تحويل exception لرسالة واضحة
  static String friendlyMessage(Object error, {String? locale}) {
    final isArabic = locale == 'ar';

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('user does not exist') || msg.contains('not exist')) {
        return isArabic ? 'هذا الحساب غير موجود' : 'Account not found';
      }
      if (msg.contains('incorrect') || msg.contains('not authorized')) {
        return isArabic
            ? 'كلمة المرور غير صحيحة'
            : 'Incorrect email or password';
      }
      if (msg.contains('not confirmed') ||
          msg.contains('user is not confirmed')) {
        return isArabic
            ? 'يجب تأكيد البريد أولاً'
            : 'Please verify your email first';
      }
      if (msg.contains('username already exists') ||
          msg.contains('already exists')) {
        return isArabic
            ? 'هذا البريد مسجل بالفعل'
            : 'Email already registered';
      }
      if (msg.contains('password did not conform') ||
          msg.contains('invalidpassword')) {
        return isArabic
            ? 'كلمة المرور ضعيفة (8 أحرف على الأقل)'
            : 'Password too weak (at least 8 characters)';
      }
      if (msg.contains('limit exceeded')) {
        return isArabic
            ? 'محاولات كثيرة. جرّب بعد قليل'
            : 'Too many attempts. Try later';
      }
      if (msg.contains('network')) {
        return isArabic
            ? 'لا يوجد اتصال بالإنترنت'
            : 'No internet connection';
      }
      return isArabic
          ? 'خطأ في تسجيل الدخول'
          : 'Authentication error';
    }

    if (error is ApiException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('unauthorized') || msg.contains('not authorized')) {
        return isArabic
            ? 'ليس لديك صلاحية للوصول'
            : 'You do not have permission';
      }
      if (msg.contains('network')) {
        return isArabic
            ? 'لا يوجد اتصال بالإنترنت'
            : 'No internet connection';
      }
      return isArabic
          ? 'حدث خطأ في الخادم'
          : 'Server error. Please try again';
    }

    if (error is StorageException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('size') || msg.contains('too large')) {
        return isArabic
            ? 'حجم الملف كبير جداً'
            : 'File is too large';
      }
      return isArabic
          ? 'فشل في رفع الملف'
          : 'File upload failed';
    }

    return isArabic ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
  }

  /// إظهار snackbar مع رسالة الخطأ
  static void showError(BuildContext context, Object error, {String? locale}) {
    if (!context.mounted) return;
    final msg = friendlyMessage(error, locale: locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// إظهار snackbar نجاح
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}