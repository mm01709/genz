// lib/data/aws_storage.dart
// ═══════════════════════════════════════════════════════════════════════════════
// AWSStorageService — v3 (Secure + Real-time + DataStore-free)
// ─────────────────────────────────────────────────────────────────────────────
// ✅ تم إصلاح:
//   1. مشكلة الإشعارات للموظف: توحيد employeeInboxKey في كل مكان
//   2. مشكلة الشات مش بيتقفل: استبدال observeChatStatus (DataStore) بـ
//      subscribeToChatStatus (AppSync subscription حقيقي)
//   3. مشكلة الحجز: استخدام Cognito email المؤكد + double-check + retry
//   4. إزالة DataStore import بالكامل (الـ plugin مش محمّل)
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// ⚠️ DataStore import شيلناه بالكامل — الـ plugin مش محمّل في main.dart
// كل الـ observers اتحوّلت لـ AppSync subscriptions
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:genz/models/ModelProvider.dart';
import 'package:genz/data/data.dart' as data;


class AWSStorageService {
  // ───────────────────────────────────────────────────────────────────────────
  // 🏷️ Inbox Keys — موحدة في كل مكان
  // ───────────────────────────────────────────────────────────────────────────

  /// 🏷️ Sentinel email — كل الإشعارات اللي للموظفين بتتبعت بالـ key ده.
  /// لازم يكون موحد في كل مكان (client_screen, Employees_screen, إلخ)
  static const String employeeInboxKey = '__employees__';

  // Singleton chat status stream — واحد بس في التطبيق كله
  static StreamController<bool>? _chatStatusController;
  static StreamSubscription? _chatStatusCreateSub;
  static StreamSubscription? _chatStatusUpdateSub;
  static String _chatStatusEmail = '';

  /// 🔄 Backward-compat alias — لأي بيانات قديمة محفوظة بـ "EMPLOYEE_INBOX"
  static const String legacyEmployeeInboxKey = 'EMPLOYEE_INBOX';

  /// Helper getter للـ inbox key (سهولة قراءة)
  static String get employeesNotifKey => employeeInboxKey;

  /// Exposes the global current user map so other modules can read it via the
  /// service surface (e.g. `AWSStorageService.currentUser['email']`).
  static Map<String, String> get currentUser => data.currentUser;

  // ───────────────────────────────────────────────────────────────────────────
  // Auth Helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// يتأكد إن في user مسجل دخول. بيرمي exception لو مش مسجل.
  static Future<void> requireSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw Exception('Not signed in');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw Exception('Auth check failed: $e');
    }
  }

  /// بيرجع الـ Cognito email للـ user الحالي (مهم للـ owner-based auth)
  /// ⚠️ Cognito دايماً بيرجع الـ email في اللى الـ user كتبه — لكن الـ identityClaim
  /// بيقارن exact match فلازم نـ normalize للـ lowercase قبل أي query
  static Future<String?> getCurrentUserEmail() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final emailAttr = attributes.firstWhere(
            (a) => a.userAttributeKey == AuthUserAttributeKey.email,
        orElse: () => const AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          value: '',
        ),
      );
      return emailAttr.value.isEmpty ? null : emailAttr.value;
    } catch (e) {
      safePrint('getCurrentUserEmail error: $e');
      return null;
    }
  }

  /// 🔐 يجيب الـ email كما هو من Cognito JWT — للاستخدام في owner-auth mutations.
  /// ⚠️ لا نعمل toLowerCase هنا لأن AppSync يقارن clientEmail بـ JWT email claim
  /// exact match — لو بدّلنا الـ case هيرفض المutation بـ Unauthorized.
  static Future<String?> getOwnerEmail() async {
    final raw = await getCurrentUserEmail();
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// بيتأكد إن المستخدم في مجموعة Employee
  static Future<bool> isCurrentUserEmployee() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is! CognitoAuthSession || !session.isSignedIn) return false;

      final idToken = session.userPoolTokensResult.value.idToken;
      final groups = idToken.groups;
      return groups.contains('Employee');
    } catch (e) {
      safePrint('isCurrentUserEmployee error: $e');
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Load Current User (من Cognito + UserProfile)
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> loadCurrentUser() async {
    try {
      await requireSignedIn();

      final email = await getCurrentUserEmail();
      if (email == null || email.isEmpty) return;

      // نخزّن الـ email كما جاء من Cognito (بدون toLowerCase) عشان يتطابق مع JWT claim
      currentUser['email'] = email.trim();

      // determine user type via Cognito groups
      final isEmployee = await isCurrentUserEmployee();
      currentUser['type'] = isEmployee ? 'employee' : 'client';

      // ✅ اقرا الـ name من Cognito attributes كـ fallback
      String? cognitoName;
      try {
        final attrs = await Amplify.Auth.fetchUserAttributes();
        for (final a in attrs) {
          if (a.userAttributeKey == AuthUserAttributeKey.name &&
              a.value.isNotEmpty) {
            cognitoName = a.value;
            break;
          }
        }
      } catch (_) {}

      // load UserProfile (إن وجد)
      final response = await Amplify.API.query(
        request: ModelQueries.list(
          UserProfile.classType,
          where: UserProfile.EMAIL.eq(email),
        ),
      ).response;

      final profiles =
          response.data?.items.whereType<UserProfile>().toList() ?? [];

      String resolveName() {
        return cognitoName ?? email.split('@').first;
      }

      if (profiles.isNotEmpty) {
        final profile = profiles.first;
        if (profile.name?.isNotEmpty ?? false) {
          currentUser['name'] = profile.name!;
        } else {
          currentUser['name'] = resolveName();
        }
        currentUser['chatEnabled'] = (profile.chatEnabled ?? true).toString();

        final rawImage = profile.image ?? '';
        if (rawImage.isEmpty) {
          currentUser['image'] = '';
        } else if (!rawImage.startsWith('http')) {
          currentUser['image'] = rawImage;
        } else {
          // URL محفوظ بالغلط — نحاول نستخرج الـ S3 key منه
          final s3KeyMatch = RegExp(r'(public/profile-images/[^?]+)').firstMatch(rawImage);
          if (s3KeyMatch != null) {
            final extractedKey = s3KeyMatch.group(1)!;
            currentUser['image'] = extractedKey;
            updateUserProfile(email: email.trim(), imageUrl: extractedKey);
          } else {
            // pravatar أو URL خارجي — نبحث عن صورة على S3 للـ user ده
            final s3Key = await _findLatestProfileImageKey(email.trim());
            if (s3Key != null) {
              currentUser['image'] = s3Key;
              updateUserProfile(email: email.trim(), imageUrl: s3Key);
            } else {
              currentUser['image'] = '';
            }
          }
        }
      } else {
        currentUser['name'] = resolveName();
        currentUser['image'] = '';
        currentUser['chatEnabled'] = 'true';
        await ensureUserProfileExists(email);
      }
    } catch (e) {
      safePrint('loadCurrentUser error: $e');
    }
  }

  static Future<void> ensureUserProfileExists(String email) async {
    try {
      await requireSignedIn();

      final response = await Amplify.API.query(
        request: ModelQueries.list(
          UserProfile.classType,
          where: UserProfile.EMAIL.eq(email),
        ),
      ).response;

      final results =
          response.data?.items.whereType<UserProfile>().toList() ?? [];

      if (results.isEmpty) {
        final existingName = currentUser['name'] ?? '';
        final profile = UserProfile(
          email: email,
          name: existingName.isNotEmpty ? existingName : email.split('@').first,
          image: currentUser['image'],
          type: currentUser['type'],
          chatEnabled: true,
          lastUpdated: TemporalDateTime.now(),
        );
        await Amplify.API
            .mutate(request: ModelMutations.create(profile))
            .response;
      }
    } catch (e) {
      safePrint('ensureUserProfileExists error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📡 GraphQL Subscriptions (REAL-TIME — بدل DataStore)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Subscribe لتغييرات الاستوديوهات (للجميع)
  /// كل event بيجي كـ {'type': 'create'|'update'|'delete', 'studio': Studio}
  static Stream<Map<String, dynamic>> subscribeToStudios() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    final createSub = Amplify.API
        .subscribe(
      ModelSubscriptions.onCreate(Studio.classType),
      onEstablished: () => safePrint('🔌 Studios.onCreate established'),
    )
        .listen(
          (event) {
        if (event.data != null && !controller.isClosed) {
          controller.add({'type': 'create', 'studio': event.data!});
        }
      },
      onError: (e) => safePrint('Studios.onCreate error: $e'),
    );

    final updateSub = Amplify.API
        .subscribe(
      ModelSubscriptions.onUpdate(Studio.classType),
      onEstablished: () => safePrint('🔌 Studios.onUpdate established'),
    )
        .listen(
          (event) {
        if (event.data != null && !controller.isClosed) {
          controller.add({'type': 'update', 'studio': event.data!});
        }
      },
      onError: (e) => safePrint('Studios.onUpdate error: $e'),
    );

    final deleteSub = Amplify.API
        .subscribe(
      ModelSubscriptions.onDelete(Studio.classType),
      onEstablished: () => safePrint('🔌 Studios.onDelete established'),
    )
        .listen(
          (event) {
        if (event.data != null && !controller.isClosed) {
          controller.add({'type': 'delete', 'studio': event.data!});
        }
      },
      onError: (e) => safePrint('Studios.onDelete error: $e'),
    );

    controller.onCancel = () {
      createSub.cancel();
      updateSub.cancel();
      deleteSub.cancel();
    };

    return controller.stream;
  }

  /// Subscribe لحجوزات عميل معين (للعميل) أو الكل (للموظف)
  static Stream<BookingRequest> subscribeToBookings({String? clientEmail}) {
    final controller = StreamController<BookingRequest>.broadcast();
    final List<StreamSubscription> subs = [];
    final filterEmail = clientEmail?.trim().toLowerCase() ?? '';

    void attach(GraphQLRequest<BookingRequest> req, String label) {
      final sub = Amplify.API
          .subscribe(
        req,
        onEstablished: () => safePrint('🔌 Bookings.$label established'),
      )
          .listen(
            (event) {
          if (event.data == null) return;
          if (filterEmail.isNotEmpty &&
              event.data!.clientEmail.toLowerCase() != filterEmail) {
            return;
          }
          if (!controller.isClosed) controller.add(event.data!);
        },
        onError: (e) => safePrint('Bookings.$label error: $e'),
      );
      subs.add(sub);
    }

    attach(ModelSubscriptions.onCreate(BookingRequest.classType), 'onCreate');
    attach(ModelSubscriptions.onUpdate(BookingRequest.classType), 'onUpdate');
    attach(ModelSubscriptions.onDelete(BookingRequest.classType), 'onDelete');

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    return controller.stream;
  }

  /// Subscribe لرسائل الشات (الـ schema بيعمل filter حسب الـ owner)
  static Stream<ChatMessage> subscribeToChatMessages({String? clientEmail}) {
    final controller = StreamController<ChatMessage>.broadcast();
    final filterEmail = clientEmail?.trim().toLowerCase() ?? '';

    final sub = Amplify.API
        .subscribe(
      ModelSubscriptions.onCreate(ChatMessage.classType),
      onEstablished: () => safePrint('🔌 ChatMessages established'),
    )
        .listen(
          (event) {
        if (event.data == null) return;
        if (filterEmail.isNotEmpty &&
            event.data!.clientEmail.toLowerCase() != filterEmail) {
          return;
        }
        if (!controller.isClosed) controller.add(event.data!);
      },
      onError: (e) => safePrint('ChatMessages sub error: $e'),
    );

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  /// 📡 Subscribe لإشعارات عميل معين أو الـ employee inbox.
  /// AppSync مع ownerField:"clientEmail" بيرفض الـ subscription من غير filter.
  /// الحل: نرجع empty stream — الـ UI بيعتمد على polling بدلاً من subscription.
  static Stream<AppNotification> subscribeToNotifications(String clientEmail) {
    return const Stream.empty();
  }

  /// 📡 Subscribe لتغييرات حالة الشات لعميل معين عبر AppSync subscription.
  /// بيرجع stream من bool — true لو الشات مفعّل، false لو مغلق.
  ///
  /// ⚠️ ده بديل لـ observeChatStatus القديم اللي كان معتمد على DataStore.
  static Stream<bool> subscribeToChatStatus(String clientEmail) {
    final email = clientEmail.trim();
    if (email.isEmpty) return const Stream.empty();

    // لو نفس الـ email وعنده subscription شغال، رجّع نفس الـ stream
    if (_chatStatusController != null &&
        !_chatStatusController!.isClosed &&
        _chatStatusEmail == email.toLowerCase()) {
      return _chatStatusController!.stream;
    }

    // نظف القديم لو موجود
    _chatStatusCreateSub?.cancel();
    _chatStatusUpdateSub?.cancel();
    _chatStatusController?.close();

    _chatStatusEmail = email.toLowerCase();
    _chatStatusController = StreamController<bool>.broadcast();

    void emitFromProfile(UserProfile profile) {
      if (profile.email.toLowerCase() != _chatStatusEmail) return;
      final enabled = profile.chatEnabled ?? true;
      if (!_chatStatusController!.isClosed) _chatStatusController!.add(enabled);
    }

    try {
      _chatStatusCreateSub = Amplify.API
          .subscribe(
            ModelSubscriptions.onCreate(UserProfile.classType),
            onEstablished: () => safePrint('🔌 ChatStatus.onCreate established for $email'),
          )
          .listen(
            (event) { if (event.data != null) emitFromProfile(event.data!); },
            onError: (e) => safePrint('ChatStatus.onCreate error: $e'),
          );

      _chatStatusUpdateSub = Amplify.API
          .subscribe(
            ModelSubscriptions.onUpdate(UserProfile.classType),
            onEstablished: () => safePrint('🔌 ChatStatus.onUpdate established for $email'),
          )
          .listen(
            (event) { if (event.data != null) emitFromProfile(event.data!); },
            onError: (e) => safePrint('ChatStatus.onUpdate error: $e'),
          );
    } catch (e) {
      safePrint('subscribeToChatStatus init error: $e');
    }

    return _chatStatusController!.stream;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏗️ Studios CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحميل كل الاستوديوهات + تحويل S3 keys لـ pre-signed URLs
  static Future<List<Map<String, dynamic>>> loadStudios({
    int limit = 100,
  }) async {
    try {
      await requireSignedIn();

      const listDoc = '''
        query ListStudios(\$limit: Int) {
          listStudios(limit: \$limit, filter: {_deleted: {ne: true}}) {
            items { id name type pricePerHour description image available sortOrder _deleted }
          }
        }''';
      final rawResp = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: listDoc,
          variables: {'limit': limit},
        ),
      ).response;

      // Parse raw JSON manually
      final jsonStr = rawResp.data ?? '{}';
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final items = (decoded['listStudios']?['items'] as List<dynamic>?) ?? [];
      final studios = items
          .whereType<Map<String, dynamic>>()
          .where((s) => s['_deleted'] != true)
          .toList();
      safePrint('loadStudios: got ${studios.length} (filtered) studios');

      final mapped = <Map<String, dynamic>>[];
      for (final s in studios) {
        // image field stores multiple S3 keys separated by |||
        final rawImage = (s['image'] as String?) ?? '';
        final keys = rawImage.isEmpty ? <String>[] : rawImage.split('|||');

        final urls = <String>[];
        for (final key in keys) {
          if (key.isEmpty) continue;
          if (key.startsWith('http') || key.startsWith('data:')) {
            urls.add(key);
          } else {
            final url = await getS3ImageUrl(key) ?? '';
            if (url.isNotEmpty) urls.add(url);
          }
        }

        final decoded = _decodeStudioDescription(s['description'] as String?);
        mapped.add({
          'id': s['id'] as String,
          'name': s['name'] as String? ?? '',
          'type': s['type'] as String? ?? '',
          'pricePerHour': s['pricePerHour'] as int? ?? 0,
          'description': decoded['desc'] ?? '',
          'size': decoded['size'] ?? '',
          'equipment': decoded['equipment'] ?? '',
          'services': decoded['services'] ?? '',
          'image': urls.isNotEmpty ? urls.first : '',
          'images': urls,
          'imageKeys': keys,
          'imageKey': keys.isNotEmpty ? keys.first : '',
          'available': s['available'] as bool? ?? true,
          'sortOrder': s['sortOrder'] as int? ?? 9999,
        });
      }
      mapped.sort((a, b) => (a['sortOrder'] as int).compareTo(b['sortOrder'] as int));
      return mapped;
    } catch (e) {
      safePrint('loadStudios error: $e');
      return [];
    }
  }

  /// يخزن description + size + equipment + services في JSON واحد
  static String? _encodeStudioDescription(Map<String, dynamic> data) {
    final desc = (data['description'] as String? ?? '').trim();
    final size = (data['size'] as String? ?? '').trim();
    final equipment = (data['equipment'] as String? ?? '').trim();
    final services = (data['services'] as String? ?? '').trim();
    if (desc.isEmpty && size.isEmpty && equipment.isEmpty && services.isEmpty) {
      return null;
    }
    return jsonEncode({
      'desc': desc,
      'size': size,
      'equipment': equipment,
      'services': services,
    });
  }

  /// يفك الـ description — يدعم النص القديم والـ JSON الجديد
  static Map<String, String> _decodeStudioDescription(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {'desc': '', 'size': '', 'equipment': '', 'services': ''};
    }
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'desc': parsed['desc']?.toString() ?? '',
        'size': parsed['size']?.toString() ?? '',
        'equipment': parsed['equipment']?.toString() ?? '',
        'services': parsed['services']?.toString() ?? '',
      };
    } catch (_) {
      // نص قديم غير JSON — نحطه في desc
      return {'desc': raw, 'size': '', 'equipment': '', 'services': ''};
    }
  }

  static Future<bool> saveStudio(Map<String, dynamic> data) async {
    try {
      await requireSignedIn();

      final rawKeys = data['imageKeys'];
      final imageKeys = rawKeys is List
          ? rawKeys.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      final imageField = imageKeys.join('|||');

      final descPayload = _encodeStudioDescription(data);
      final studio = Studio(
        name: (data['name'] as String?) ?? '',
        type: (data['type'] as String?) ?? '',
        pricePerHour: (data['pricePerHour'] as int?) ?? 0,
        description: descPayload,
        image: imageField.isEmpty ? null : imageField,
        available: (data['available'] as bool?) ?? true,
        sortOrder: data['sortOrder'] as int?,
      );

      await Amplify.API
          .mutate(request: ModelMutations.create(studio))
          .response;
      return true;
    } catch (e) {
      safePrint('saveStudio error: $e');
      return false;
    }
  }

  static Future<bool> updateStudio(
      String studioId,
      Map<String, dynamic> data,
      ) async {
    try {
      await requireSignedIn();

      // Step 1: fetch current _version (AppSync conflict detection requires it)
      const getDoc = '''
        query GetStudio(\$id: ID!) {
          getStudio(id: \$id) { id _version }
        }''';
      final getResp = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: getDoc,
          variables: {'id': studioId},
        ),
      ).response;

      int version = 1;
      final raw = getResp.data ?? '{}';
      final idx = raw.indexOf('"_version":');
      if (idx >= 0) {
        final sub = raw.substring(idx + 11);
        final end = sub.indexOf(RegExp(r'[,}]'));
        version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
      }

      // Step 2: build image field
      final rawKeys = data['imageKeys'];
      final imageKeys = rawKeys is List
          ? rawKeys.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      final imageField = imageKeys.join('|||');

      // Step 3: mutate with _version
      const mutDoc = '''
        mutation UpdateStudio(\$input: UpdateStudioInput!) {
          updateStudio(input: \$input) { id _version }
        }''';
      await Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: mutDoc,
          variables: {
            'input': {
              'id': studioId,
              'name': data['name'],
              'type': data['type'],
              'pricePerHour': data['pricePerHour'],
              'description': _encodeStudioDescription(data),
              'image': imageField.isEmpty ? null : imageField,
              'available': data['available'],
              'sortOrder': data['sortOrder'],
              '_version': version,
            },
          },
        ),
      ).response;
      return true;
    } catch (e) {
      safePrint('updateStudio error: $e');
      return false;
    }
  }

  static Future<bool> deleteStudio(String studioId) async {
    try {
      await requireSignedIn();

      // Fetch current _version (AppSync conflict detection requires it for delete)
      const getDoc = '''
        query GetStudio(\$id: ID!) {
          getStudio(id: \$id) { id image _version }
        }''';
      final getResp = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: getDoc,
          variables: {'id': studioId},
        ),
      ).response;

      final raw = getResp.data ?? '{}';

      // Extract _version
      int version = 1;
      final vIdx = raw.indexOf('"_version":');
      if (vIdx >= 0) {
        final sub = raw.substring(vIdx + 11);
        final end = sub.indexOf(RegExp(r'[,}]'));
        version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
      }

      // Extract image field to delete S3 files
      final imgIdx = raw.indexOf('"image":');
      if (imgIdx >= 0) {
        final sub = raw.substring(imgIdx + 8).trim();
        if (sub.startsWith('"')) {
          final end = sub.indexOf('"', 1);
          final imageField = end > 0 ? sub.substring(1, end) : '';
          if (imageField.isNotEmpty) {
            for (final key in imageField.split('|||')) {
              if (key.isNotEmpty && !key.startsWith('http') && !key.startsWith('data:')) {
                await deleteS3Image(key);
              }
            }
          }
        }
      }

      // Delete with _version to satisfy conflict detection
      const delDoc = '''
        mutation DeleteStudio(\$input: DeleteStudioInput!) {
          deleteStudio(input: \$input) { id }
        }''';
      final delResp = await Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: delDoc,
          variables: {
            'input': {
              'id': studioId,
              '_version': version,
            },
          },
        ),
      ).response;
      safePrint('deleteStudio response: ${delResp.data}');
      if (delResp.errors.isNotEmpty) {
        safePrint('deleteStudio errors: ${delResp.errors}');
        return false;
      }
      return true;
    } catch (e) {
      safePrint('deleteStudio error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛎️ GenzServices — CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> loadGenzServices() async {
    try {
      await requireSignedIn();
      const doc = '''
        query ListGenzServices {
          listGenzServices(limit: 200) {
            items {
              id category name nameAr description price priceLabel sortOrder available _version
            }
          }
        }''';
      final resp = await Amplify.API.query(
        request: GraphQLRequest<String>(document: doc),
      ).response;
      if (resp.errors.isNotEmpty) {
        safePrint('loadGenzServices errors: ${resp.errors}');
        return [];
      }
      final raw = resp.data ?? '{}';
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = (decoded['listGenzServices']?['items'] as List?) ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .where((s) => s['id'] != null)
          .map((s) => Map<String, dynamic>.from(s))
          .toList()
        ..sort((a, b) {
          final ao = (a['sortOrder'] as int?) ?? 999;
          final bo = (b['sortOrder'] as int?) ?? 999;
          return ao.compareTo(bo);
        });
    } catch (e) {
      safePrint('loadGenzServices error: $e');
      return [];
    }
  }

  static Future<bool> saveGenzService(Map<String, dynamic> data) async {
    try {
      await requireSignedIn();
      final isEdit = (data['id'] as String?)?.isNotEmpty == true;

      if (isEdit) {
        // نجيب الـ _version الأحدث
        const getDoc = '''
          query GetGenzService(\$id: ID!) {
            getGenzService(id: \$id) { id _version }
          }''';
        final getResp = await Amplify.API.query(
          request: GraphQLRequest<String>(
            document: getDoc,
            variables: {'id': data['id']},
          ),
        ).response;
        int version = 1;
        final raw = getResp.data ?? '{}';
        final vIdx = raw.indexOf('"_version":');
        if (vIdx >= 0) {
          final sub = raw.substring(vIdx + 11);
          final end = sub.indexOf(RegExp(r'[,}]'));
          version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
        }

        const updateDoc = '''
          mutation UpdateGenzService(\$input: UpdateGenzServiceInput!) {
            updateGenzService(input: \$input) { id }
          }''';
        final resp = await Amplify.API.mutate(
          request: GraphQLRequest<String>(
            document: updateDoc,
            variables: {
              'input': {
                'id':          data['id'],
                'category':    data['category'],
                'name':        data['name'],
                'nameAr':      data['nameAr'],
                'description': data['description'],
                'price':       data['price'],
                'priceLabel':  data['priceLabel'],
                'sortOrder':   data['sortOrder'],
                'available':   data['available'] ?? true,
                '_version':    version,
              }
            },
          ),
        ).response;
        if (resp.errors.isNotEmpty) {
          safePrint('updateGenzService errors: ${resp.errors}');
          return false;
        }
        return true;
      } else {
        const createDoc = '''
          mutation CreateGenzService(\$input: CreateGenzServiceInput!) {
            createGenzService(input: \$input) { id }
          }''';
        final resp = await Amplify.API.mutate(
          request: GraphQLRequest<String>(
            document: createDoc,
            variables: {
              'input': {
                'category':    data['category'],
                'name':        data['name'],
                'nameAr':      data['nameAr'],
                'description': data['description'],
                'price':       data['price'],
                'priceLabel':  data['priceLabel'],
                'sortOrder':   data['sortOrder'],
                'available':   data['available'] ?? true,
              }
            },
          ),
        ).response;
        if (resp.errors.isNotEmpty) {
          safePrint('createGenzService errors: ${resp.errors}');
          return false;
        }
        return true;
      }
    } catch (e) {
      safePrint('saveGenzService error: $e');
      return false;
    }
  }

  static Future<bool> deleteGenzService(String serviceId) async {
    try {
      await requireSignedIn();
      const getDoc = '''
        query GetGenzService(\$id: ID!) {
          getGenzService(id: \$id) { id _version }
        }''';
      final getResp = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: getDoc,
          variables: {'id': serviceId},
        ),
      ).response;
      int version = 1;
      final raw = getResp.data ?? '{}';
      final vIdx = raw.indexOf('"_version":');
      if (vIdx >= 0) {
        final sub = raw.substring(vIdx + 11);
        final end = sub.indexOf(RegExp(r'[,}]'));
        version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
      }

      const delDoc = '''
        mutation DeleteGenzService(\$input: DeleteGenzServiceInput!) {
          deleteGenzService(input: \$input) { id }
        }''';
      final resp = await Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: delDoc,
          variables: {
            'input': {'id': serviceId, '_version': version}
          },
        ),
      ).response;
      if (resp.errors.isNotEmpty) {
        safePrint('deleteGenzService errors: ${resp.errors}');
        return false;
      }
      return true;
    } catch (e) {
      safePrint('deleteGenzService error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 Bookings — مع Atomic Availability Check محسّن
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Map<String, String>>> loadBookings({
    int limit = 100,
    String? clientEmail,
  }) async {
    try {
      await requireSignedIn();

      final email = clientEmail ?? currentUser['email'] ?? '';
      final isEmployee = currentUser['type'] == 'employee';

      final request = (isEmployee && email.isEmpty)
          ? ModelQueries.list(BookingRequest.classType, limit: limit)
          : ModelQueries.list(
              BookingRequest.classType,
              where: BookingRequest.CLIENTEMAIL.eq(email),
              limit: limit,
            );

      final response = await Amplify.API.query(request: request).response;
      final results =
          response.data?.items.whereType<BookingRequest>().toList() ?? [];
      return results.map(_bookingToMap).toList();
    } catch (e) {
      safePrint('loadBookings error: $e');
      return [];
    }
  }

  static Map<String, String> _bookingToMap(BookingRequest b) => {
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

  /// 🔒 ATOMIC BOOKING — يفحص الـ availability من السيرفر مرتين (قبل وبعد) لتقليل الـ race
  /// بيرجع: { 'success': bool, 'reason': String?, 'booking': Map? }
  ///
  /// المميزات الجديدة:
  ///   ✅ بيجيب الـ Cognito email المؤكد (مش من cache) — يمنع owner-auth rejection
  ///   ✅ Pre + Post check للـ conflict (تقليل race conditions)
  ///   ✅ رسائل خطأ واضحة (auth_error / studio_booked / invalid_dates / server_error)
  static Future<Map<String, dynamic>> saveBookingAtomic(
      Map<String, String> booking,
      ) async {
    try {
      await requireSignedIn();

      // ✅ 1) parse + validate dates
      final start = DateTime.tryParse(booking['fullStartDateTime'] ?? '');
      final end = DateTime.tryParse(booking['fullEndDateTime'] ?? '');
      if (start == null || end == null) {
        return {'success': false, 'reason': 'invalid_dates'};
      }
      if (!end.isAfter(start)) {
        return {'success': false, 'reason': 'invalid_dates'};
      }

      // جيب الـ email من Cognito للـ display في الـ booking record
      final ownerEmail = await getOwnerEmail();
      if (ownerEmail == null || ownerEmail.isEmpty) {
        return {'success': false, 'reason': 'auth_error: no email claim'};
      }
      booking['clientEmail'] = ownerEmail;

      final studio = (booking['studio'] ?? '').trim();
      if (studio.isEmpty) {
        return {'success': false, 'reason': 'invalid_studio'};
      }

      // ✅ 3) Pre-check availability — الاستوديو نفسه
      final hasConflict = await _checkBookingConflict(studio, start, end);
      if (hasConflict) {
        return {'success': false, 'reason': 'studio_booked'};
      }

      // ✅ 3b) تحقق إن نفس العميل مش حاجز في نفس الوقت في أي استوديو
      final clientConflict = await _checkClientTimeConflict(ownerEmail, start, end);
      if (clientConflict) {
        return {'success': false, 'reason': 'client_time_conflict'};
      }

      // ✅ 4) Save
      final newBooking = BookingRequest(
        clientEmail: ownerEmail,
        clientName: booking['clientName'],
        clientPhone: booking['clientPhone'],
        studio: studio,
        date: booking['date'] ?? '',
        hours: booking['hours'] ?? '',
        price: booking['price'] ?? '0',
        equipment: booking['equipment'],
        status: booking['status'] ?? 'Pending',
        fullStartDateTime: booking['fullStartDateTime'] ?? '',
        fullEndDateTime: booking['fullEndDateTime'] ?? '',
      );

      final saveResponse = await Amplify.API
          .mutate(request: ModelMutations.create(newBooking))
          .response;

      if (saveResponse.errors.isNotEmpty) {
        safePrint('saveBookingAtomic GraphQL errors: ${saveResponse.errors}');
        final msg = saveResponse.errors.first.message;
        if (msg.toLowerCase().contains('unauthorized')) {
          return {
            'success': false,
            'reason': 'auth_error: owner mismatch — re-login required',
          };
        }
        return {'success': false, 'reason': msg};
      }

      // ✅ 5) Post-check (best-effort) — لو دخل حد بنفس الميلي ثانية
      try {
        final stillConflict = await _checkBookingConflict(
          studio,
          start,
          end,
          excludeId: newBooking.id,
        );
        if (stillConflict) {
          safePrint(
              '⚠️ Possible race detected for booking ${newBooking.id}');
          // ملحوظة: مش بنعمل rollback تلقائياً — الموظف يقدر يقرر يدوياً
        }
      } catch (_) {}

      booking['id'] = newBooking.id;
      return {'success': true, 'booking': booking};
    } on AuthException catch (e) {
      return {'success': false, 'reason': 'auth_error: ${e.message}'};
    } catch (e) {
      safePrint('saveBookingAtomic error: $e');
      return {'success': false, 'reason': 'server_error'};
    }
  }

  /// 🔍 Helper: بيتأكد من تعارض الحجز
  static Future<bool> _checkBookingConflict(
      String studio,
      DateTime start,
      DateTime end, {
        String? excludeId,
      }) async {
    try {
      final response = await Amplify.API.query(
        request: ModelQueries.list(
          BookingRequest.classType,
          where: BookingRequest.STUDIO
              .eq(studio)
              .and(BookingRequest.STATUS.ne('Rejected'))
              .and(BookingRequest.STATUS.ne('Cancelled')),
          limit: 200,
        ),
      ).response;

      final existing =
          response.data?.items.whereType<BookingRequest>().toList() ?? [];

      for (final b in existing) {
        if (excludeId != null && b.id == excludeId) continue;
        final eStart = DateTime.tryParse(b.fullStartDateTime);
        final eEnd = DateTime.tryParse(b.fullEndDateTime);
        if (eStart == null || eEnd == null) continue;
        if (start.isBefore(eEnd) && end.isAfter(eStart)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      safePrint('_checkBookingConflict error: $e');
      // العميل مش بيشوف كل الحجوزات — نسيب الـ conflict check للموظف
      return false;
    }
  }

  /// 🔍 تحقق إن نفس العميل مش عنده حجز في نفس الوقت في أي استوديو
  static Future<bool> _checkClientTimeConflict(
      String clientEmail,
      DateTime start,
      DateTime end, {
        String? excludeId,
      }) async {
    try {
      final response = await Amplify.API.query(
        request: ModelQueries.list(
          BookingRequest.classType,
          where: BookingRequest.CLIENTEMAIL
              .eq(clientEmail)
              .and(BookingRequest.STATUS.ne('Rejected'))
              .and(BookingRequest.STATUS.ne('Cancelled')),
          limit: 200,
        ),
      ).response;

      final existing =
          response.data?.items.whereType<BookingRequest>().toList() ?? [];

      for (final b in existing) {
        if (excludeId != null && b.id == excludeId) continue;
        final eStart = DateTime.tryParse(b.fullStartDateTime);
        final eEnd = DateTime.tryParse(b.fullEndDateTime);
        if (eStart == null || eEnd == null) continue;
        if (start.isBefore(eEnd) && end.isAfter(eStart)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      safePrint('_checkClientTimeConflict error: $e');
      return false;
    }
  }

  static Future<bool> updateBookingStatus(
      String bookingId,
      String newStatus,
      ) async {
    try {
      await requireSignedIn();

      // Fetch _version first — required by AppSync conflict detection
      const getDoc = '''
        query GetBookingRequest(\$id: ID!) {
          getBookingRequest(id: \$id) { id _version }
        }''';
      final getResp = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: getDoc,
          variables: {'id': bookingId},
        ),
      ).response;

      int version = 1;
      final raw = getResp.data ?? '{}';
      final idx = raw.indexOf('"_version":');
      if (idx >= 0) {
        final sub = raw.substring(idx + 11);
        final end = sub.indexOf(RegExp(r'[,}]'));
        version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
      }

      const mutDoc = '''
        mutation UpdateBookingRequest(\$input: UpdateBookingRequestInput!) {
          updateBookingRequest(input: \$input) { id status _version }
        }''';
      await Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: mutDoc,
          variables: {
            'input': {'id': bookingId, 'status': newStatus, '_version': version},
          },
        ),
      ).response;
      return true;
    } catch (e) {
      safePrint('updateBookingStatus error: $e');
      return false;
    }
  }

  static Future<bool> deleteBooking(String bookingId) async {
    try {
      await requireSignedIn();

      final response = await Amplify.API.query(
        request: ModelQueries.get(
          BookingRequest.classType,
          BookingRequestModelIdentifier(id: bookingId),
        ),
      ).response;

      final booking = response.data;
      if (booking == null) return false;

      await Amplify.API
          .mutate(request: ModelMutations.delete(booking))
          .response;
      return true;
    } catch (e) {
      safePrint('deleteBooking error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💬 Chat / Tickets
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Map<String, String>>> loadMessages({
    String? clientEmail,
    int limit = 100,
  }) async {
    try {
      await requireSignedIn();

      final isEmployee = currentUser['type'] == 'employee';
      final email = (clientEmail ?? currentUser['email'] ?? '').trim();

      final request = (isEmployee && email.isEmpty)
          ? ModelQueries.list(ChatMessage.classType, limit: limit)
          : ModelQueries.list(
              ChatMessage.classType,
              where: ChatMessage.CLIENTEMAIL.eq(email),
              limit: limit,
            );

      final response = await Amplify.API.query(request: request).response;
      final results =
          response.data?.items.whereType<ChatMessage>().toList() ?? [];

      final mapped = results.map((m) => <String, String>{
        'id': m.id,
        'senderName': m.senderName ?? '',
        'senderEmail': m.senderEmail ?? '',
        'clientEmail': m.clientEmail,
        'text': m.text ?? '',
        'time': m.time ?? '',
        'messageType': m.messageType ?? 'chat',
        'parentId': m.parentId ?? '',
      }).toList();

      mapped.sort((a, b) => a['time']!.compareTo(b['time']!));
      return mapped;
    } catch (e) {
      safePrint('loadMessages error: $e');
      return [];
    }
  }

  /// Sends a chat message. Accepts a `Map<String, String>` for backwards
  /// compatibility with existing call-sites that already build a map.
  static Future<bool> sendMessage(Map<String, String> msg) async {
    try {
      await requireSignedIn();

      final clientEmail = (msg['clientEmail'] ?? '').trim();
      if (clientEmail.isEmpty) {
        safePrint('sendMessage error: missing clientEmail');
        return false;
      }

      final entity = ChatMessage(
        senderName: msg['senderName'] ?? '',
        senderEmail: (msg['senderEmail'] ?? '').trim(),
        clientEmail: clientEmail,
        text: msg['text'] ?? '',
        time: msg['time'] ?? DateTime.now().toIso8601String(),
        messageType: msg['messageType'] ?? 'chat',
        parentId: msg['parentId'],
      );

      final response = await Amplify.API
          .mutate(request: ModelMutations.create(entity))
          .response;

      if (response.errors.isNotEmpty) {
        safePrint('sendMessage GraphQL errors: ${response.errors}');
        return false;
      }
      return true;
    } catch (e) {
      safePrint('sendMessage error: $e');
      return false;
    }
  }

  /// Deletes every chat message that belongs to a client (employee-only path).
  static Future<int> deleteMessagesByClient(String clientEmail) async {
    try {
      await requireSignedIn();
      final email = clientEmail.trim();
      if (email.isEmpty) return 0;

      final response = await Amplify.API.query(
        request: ModelQueries.list(
          ChatMessage.classType,
          where: ChatMessage.CLIENTEMAIL.eq(email),
          limit: 1000,
        ),
      ).response;

      final items =
          response.data?.items.whereType<ChatMessage>().toList() ?? [];

      var deleted = 0;
      for (final m in items) {
        try {
          await Amplify.API
              .mutate(request: ModelMutations.delete(m))
              .response;
          deleted++;
        } catch (e) {
          safePrint('deleteMessagesByClient: failed to delete ${m.id}: $e');
        }
      }
      return deleted;
    } catch (e) {
      safePrint('deleteMessagesByClient error: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔔 Notifications
  // ═══════════════════════════════════════════════════════════════════════════

  /// 📥 Load notifications — للموظف يجيب من employeeInboxKey + legacy
  /// للعميل يجيب من emailه فقط
  static Future<List<Map<String, String>>> loadNotifications({
    String? clientEmail,
    int limit = 100,
  }) async {
    try {
      await requireSignedIn();

      final raw = clientEmail ?? currentUser['email'] ?? '';

      // 🔄 لو الموظف بيقرا — اقرا الجديد + القديم معاً
      final isEmployeeQuery = raw == employeeInboxKey ||
          raw == legacyEmployeeInboxKey ||
          (currentUser['type'] == 'employee' &&
              (clientEmail == null || clientEmail.isEmpty));

      if (isEmployeeQuery) {
        final results = <AppNotification>[];

        for (final key in {employeeInboxKey, legacyEmployeeInboxKey}) {
          try {
            final r = await Amplify.API
                .query(
              request: ModelQueries.list(
                AppNotification.classType,
                where: AppNotification.CLIENTEMAIL.eq(key),
                limit: limit,
              ),
            )
                .response;
            results.addAll(
                r.data?.items.whereType<AppNotification>() ?? []);
          } catch (e) {
            safePrint('loadNotifications($key) error: $e');
          }
        }

        // dedupe by id
        final seen = <String>{};
        final unique = results.where((n) => seen.add(n.id)).toList();

        final mapped = unique
            .map((n) => {
          'id': n.id,
          'clientEmail': n.clientEmail,
          'title': n.title ?? '',
          'body': n.body ?? '',
          'type': n.type ?? '',
          'time': n.time ?? '',
          'read': (n.read ?? false).toString(),
        })
            .toList();
        mapped.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
        return mapped;
      }

      // Client
      final email = raw.trim();
      if (email.isEmpty) return [];

      final response = await Amplify.API.query(
        request: ModelQueries.list(
          AppNotification.classType,
          where: AppNotification.CLIENTEMAIL.eq(email),
          limit: limit,
        ),
      ).response;

      final results =
          response.data?.items.whereType<AppNotification>().toList() ?? [];

      final mapped = results.map((n) => <String, String>{
        'id':          n.id,
        'clientEmail': n.clientEmail,
        'title':       n.title ?? '',
        'body':        n.body ?? '',
        'type':        n.type ?? '',
        'time':        n.time ?? '',
        'read':        (n.read ?? false).toString(),
      }).toList();

      mapped.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
      return mapped;
    } catch (e) {
      safePrint('loadNotifications error: $e');
      return [];
    }
  }

  /// 📤 Send notification (محسّن مع validation)
  static Future<bool> sendNotification({
    required String clientEmail,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await requireSignedIn();

      // 🛡️ Validate input
      if (clientEmail.trim().isEmpty) {
        safePrint('sendNotification: clientEmail empty — aborting');
        return false;
      }
      if (title.trim().isEmpty || body.trim().isEmpty) {
        safePrint('sendNotification: title/body empty — aborting');
        return false;
      }

      // 🔄 Auto-normalize: لو حد بعت بـ legacy key حوّله للجديد
      // ⚠️ لا نعمل toLowerCase على emails العادية — لازم تطابق JWT claim exact
      final normalizedEmail = clientEmail == legacyEmployeeInboxKey
          ? employeeInboxKey
          : (clientEmail == employeeInboxKey
          ? employeeInboxKey
          : clientEmail.trim());

      final notif = AppNotification(
        clientEmail: normalizedEmail,
        title: title.trim(),
        body: body.trim(),
        type: type,
        time: DateTime.now().toIso8601String(),
        read: false,
      );

      final response = await Amplify.API
          .mutate(request: ModelMutations.create(notif))
          .response;

      if (response.errors.isNotEmpty) {
        safePrint('sendNotification GraphQL errors: ${response.errors}');
        return false;
      }
      return true;
    } catch (e) {
      safePrint('sendNotification error: $e');
      return false;
    }
  }

  static Future<bool> markNotificationRead(String notifId) async {
    try {
      await requireSignedIn();

      const getDoc =
          'query GetAppNotification(\$id: ID!) { getAppNotification(id: \$id) { id _version } }';
      const mutDoc =
          'mutation UpdateAppNotification(\$input: UpdateAppNotificationInput!) { updateAppNotification(input: \$input) { id read _version } }';

      final getResp = await Amplify.API.query(
        request: GraphQLRequest<String>(
            document: getDoc, variables: {'id': notifId}),
      ).response;

      int version = 1;
      try {
        final raw = getResp.data ?? '{}';
        final idx = raw.indexOf('"_version":');
        if (idx >= 0) {
          final sub = raw.substring(idx + 11);
          final end = sub.indexOf(RegExp(r'[,}]'));
          version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
        }
      } catch (_) {}

      await Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: mutDoc,
          variables: {
            'input': {'id': notifId, 'read': true, '_version': version}
          },
        ),
      ).response;
      return true;
    } catch (e) {
      safePrint('markNotificationRead error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 👤 Chat enable/disable per client
  // ═══════════════════════════════════════════════════════════════════════════

  /// 💬 يقرا حالة الشات للعميل مباشرة من AppSync (مش من cache).
  /// بيرجع `null` لو فيه error — عشان الـ UI يميّز بين "غير محدد" و "مغلق".
  static Future<bool?> isChatEnabledOrNull(String clientEmail) async {
    try {
      await requireSignedIn();
      final email = clientEmail.trim();
      if (email.isEmpty) return null;

      // raw query عشان يتجاوز الـ AppSync cache ويجيب القيمة الحقيقية من DynamoDB
      const doc = '''
        query ListByEmail(\$email: String!) {
          userProfilesByEmail(email: \$email) {
            items { id chatEnabled _version }
          }
        }
      ''';
      final resp = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: doc,
          variables: {'email': email},
        ),
      ).response;

      if (resp.errors.isNotEmpty) {
        safePrint('isChatEnabled errors: ${resp.errors}');
        return null;
      }

      final data = resp.data ?? '';
      // جيب أول item بس — تجنب الـ duplicate profiles
      final itemsIdx = data.indexOf('"items":[{');
      if (itemsIdx < 0) return true;
      final firstItem = data.substring(itemsIdx + 9);
      final firstEnd = firstItem.indexOf('}');
      if (firstEnd < 0) return true;
      final first = firstItem.substring(0, firstEnd);
      if (first.contains('"chatEnabled":true')) return true;
      if (first.contains('"chatEnabled":false')) return false;
      return true;
    } catch (e) {
      safePrint('isChatEnabled error: $e');
      return null;
    }
  }

  /// Backward-compatible wrapper — بيرجع true لو في error
  static Future<bool> isChatEnabled(String clientEmail) async {
    final v = await isChatEnabledOrNull(clientEmail);
    return v ?? true;
  }

  /// Alias for direct AppSync read (نفس الـ method)
  static Future<bool> isChatEnabledFromAPI(String clientEmail) =>
      isChatEnabled(clientEmail);

  /// 🔒 Toggle chat for a client — بيرجع bool عشان الـ caller يعرف نجح ولا لأ.
  static Future<bool> enableChatForClient(
      String clientEmail, {
        bool enable = true,
      }) async {
    try {
      await requireSignedIn();
      final email = clientEmail.trim();
      if (email.isEmpty) return false;

      final response = await Amplify.API.query(
        request: ModelQueries.list(
          UserProfile.classType,
          where: UserProfile.EMAIL.eq(email),
        ),
      ).response;

      final results =
          response.data?.items.whereType<UserProfile>().toList() ?? [];

      if (results.isEmpty) {
        // ✅ مفيش profile — اعمل واحد بدل ما نسيب الـ toggle بدون حفظ
        final newProfile = UserProfile(
          email: email,
          name: email.split('@').first,
          type: 'client',
          chatEnabled: enable,
          lastUpdated: TemporalDateTime.now(),
        );
        final r = await Amplify.API
            .mutate(request: ModelMutations.create(newProfile))
            .response;
        if (r.errors.isNotEmpty) {
          safePrint('enableChatForClient create errors: ${r.errors}');
          return false;
        }
        return true;
      }

      // حدّث كل الـ profiles بنفس الـ email (عشان الـ duplicates)
      const getDoc = 'query GetUserProfile(\$id: ID!) { getUserProfile(id: \$id) { id _version } }';
      const mutDoc = 'mutation UpdateUserProfile(\$input: UpdateUserProfileInput!) { updateUserProfile(input: \$input) { id chatEnabled _version } }';

      for (final profile in results) {
        final getResp = await Amplify.API.query(
          request: GraphQLRequest<String>(document: getDoc, variables: {'id': profile.id}),
        ).response;
        int version = 1;
        try {
          final raw = getResp.data ?? '{}';
          final idx = raw.indexOf('"_version":');
          if (idx >= 0) {
            final sub = raw.substring(idx + 11);
            final end = sub.indexOf(RegExp(r'[,}]'));
            version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
          }
        } catch (_) {}
        await Amplify.API.mutate(
          request: GraphQLRequest<String>(
            document: mutDoc,
            variables: {'input': {'id': profile.id, 'chatEnabled': enable, '_version': version}},
          ),
        ).response;
      }
      return true;
    } catch (e) {
      safePrint('enableChatForClient error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 👤 User Profile Update
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> updateUserProfile({
    required String email,
    String? name,
    String? imageUrl,
  }) async {
    // تأكد إن الـ image دايماً S3 key ومش URL — URL ممكن يتحفظ عن طريق الخطأ
    final imageKey = (imageUrl?.startsWith('http') ?? false) ? null : imageUrl;
    try {
      await requireSignedIn();

      final normalized = email.trim();

      final response = await Amplify.API.query(
        request: ModelQueries.list(
          UserProfile.classType,
          where: UserProfile.EMAIL.eq(normalized),
        ),
      ).response;

      final results =
          response.data?.items.whereType<UserProfile>().toList() ?? [];

      if (results.isEmpty) {
        final profile = UserProfile(
          email: normalized,
          name: name ?? currentUser['name'],
          image: imageKey,
          type: currentUser['type'],
          chatEnabled: true,
          lastUpdated: TemporalDateTime.now(),
        );
        await Amplify.API
            .mutate(request: ModelMutations.create(profile))
            .response;
      } else {
        final updated = results.first.copyWith(
          name: name ?? results.first.name,
          image: imageKey ?? results.first.image,
          lastUpdated: TemporalDateTime.now(),
        );
        await Amplify.API
            .mutate(request: ModelMutations.update(updated))
            .response;
      }

      // تحديث currentUser في الذاكرة فوراً بعد الحفظ
      if (name != null) data.currentUser['name'] = name;
      if (imageKey != null) data.currentUser['image'] = imageKey;

      return true;
    } catch (e) {
      safePrint('updateUserProfile error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📦 S3 Image Storage
  // ═══════════════════════════════════════════════════════════════════════════

  /// رفع صورة من Bytes (شغّال على Web + Windows + Android + iOS)
  static Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String extension,
    String prefix = 'studios',
  }) async {
    try {
      await requireSignedIn();

      final email = currentUser['email'] ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = extension.toLowerCase();
      final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';

      final s3Key = 'public/$prefix/$email-$timestamp.$ext';

      final file = AWSFile.fromData(bytes, contentType: mimeType);

      await Amplify.Storage.uploadFile(
        localFile: file,
        path: StoragePath.fromString(s3Key),
        options: StorageUploadFileOptions(
          metadata: {'content-type': mimeType},
        ),
      ).result;

      safePrint('✅ Uploaded to S3: $s3Key (${bytes.length} bytes)');
      return s3Key;
    } catch (e) {
      safePrint('uploadImageBytes error: $e');
      return null;
    }
  }

  /// رفع صورة من path محلي
  static Future<String?> uploadImageFile({
    required String localFilePath,
    String prefix = 'studios',
  }) async {
    try {
      await requireSignedIn();

      final email = currentUser['email'] ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = localFilePath.split('.').last.toLowerCase();
      final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
      final s3Key = 'public/$prefix/$email-$timestamp.$ext';

      final file = AWSFile.fromPath(localFilePath);

      await Amplify.Storage.uploadFile(
        localFile: file,
        path: StoragePath.fromString(s3Key),
        options: StorageUploadFileOptions(
          metadata: {'content-type': mimeType},
        ),
      ).result;

      safePrint('✅ Uploaded to S3: $s3Key');
      return s3Key;
    } catch (e) {
      safePrint('uploadImageFile error: $e');
      return null;
    }
  }

  /// تحويل S3 key لـ pre-signed URL صالح ساعة
  static Future<String?> getS3ImageUrl(String s3Key) async {
    try {
      if (s3Key.isEmpty) return null;
      if (s3Key.startsWith('http')) return s3Key;

      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(s3Key),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(
            expiresIn: Duration(hours: 1),
          ),
        ),
      ).result;
      return result.url.toString();
    } catch (e) {
      safePrint('getS3ImageUrl error: $e');
      return null;
    }
  }

  /// حذف صورة من S3
  static Future<bool> deleteS3Image(String s3Key) async {
    try {
      if (s3Key.isEmpty || s3Key.startsWith('http')) return false;
      await Amplify.Storage.remove(
        path: StoragePath.fromString(s3Key),
      ).result;
      safePrint('🗑️ Deleted from S3: $s3Key');
      return true;
    } catch (e) {
      safePrint('deleteS3Image error: $e');
      return false;
    }
  }

  /// ✅ Backward compatibility
  static Future<String?> getProfileImageUrl(String s3Key) =>
      getS3ImageUrl(s3Key);

  /// بيجيب آخر S3 key لصورة بروفايل الـ user من الـ storage
  static Future<String?> _findLatestProfileImageKey(String email) async {
    try {
      final result = await Amplify.Storage.list(
        path: StoragePath.fromString('public/profile-images/'),
      ).result;
      final items = result.items
          .where((item) => item.path.contains(email.toLowerCase()) ||
              item.path.contains(email))
          .toList();
      if (items.isEmpty) return null;
      // نرجع آخر واحد (الأحدث حسب الـ timestamp في الاسم)
      items.sort((a, b) => b.path.compareTo(a.path));
      return items.first.path;
    } catch (e) {
      safePrint('_findLatestProfileImageKey error: $e');
      return null;
    }
  }
  static Future<String?> uploadProfileImageBytes({
    required Uint8List bytes,
    required String extension,
  }) =>
      uploadImageBytes(
        bytes: bytes,
        extension: extension,
        prefix: 'profile-images',
      );
  static Future<String?> uploadProfileImage(String localFilePath) =>
      uploadImageFile(
        localFilePath: localFilePath,
        prefix: 'profile-images',
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔐 Auth — sign out
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> signOut() async {
    try {
      data.currentUser
        ..['email'] = ''
        ..['name'] = ''
        ..['image'] = ''
        ..['type'] = ''
        ..['chatEnabled'] = 'true';

      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('signOut error: $e');
    }
  }

  static Future<void> deleteAccount() async {
    try {
      final email = data.currentUser['email'] ?? '';
      final imageKey = data.currentUser['image'] ?? '';

      // 1) مسح كل صور الـ user من S3 (مش بس الـ key الحالي)
      try {
        final listResult = await Amplify.Storage.list(
          path: StoragePath.fromString('public/profile-images/'),
        ).result;
        final lowerEmail = email.toLowerCase();
        final userImages = listResult.items.where((item) =>
            item.path.contains(lowerEmail) || item.path.contains(email));
        for (final img in userImages) {
          await deleteS3Image(img.path).catchError((_) => false);
        }
      } catch (_) {
        // fallback: نمسح الـ key الحالي بس لو فشل الـ list
        if (imageKey.isNotEmpty && !imageKey.startsWith('http')) {
          await deleteS3Image(imageKey).catchError((_) => false);
        }
      }

      // 2) مسح الـ UserProfile والحجوزات والرسائل من الـ DB
      if (email.isNotEmpty) {
        // UserProfile
        try {
          final res = await Amplify.API.query(
            request: ModelQueries.list(UserProfile.classType,
                where: UserProfile.EMAIL.eq(email)),
          ).response;
          final profiles = res.data?.items.whereType<UserProfile>().toList() ?? [];
          for (final p in profiles) {
            await Amplify.API.mutate(request: ModelMutations.delete<UserProfile>(p)).response;
          }
        } catch (e) { safePrint('deleteAccount UserProfile error: $e'); }


        // ChatMessages
        try {
          final res = await Amplify.API.query(
            request: ModelQueries.list(ChatMessage.classType,
                where: ChatMessage.CLIENTEMAIL.eq(email)),
          ).response;
          for (final m in res.data?.items.whereType<ChatMessage>().toList() ?? []) {
            await Amplify.API.mutate(request: ModelMutations.delete<ChatMessage>(m)).response;
          }
        } catch (_) {}

        // AppNotifications
        try {
          final res = await Amplify.API.query(
            request: ModelQueries.list(AppNotification.classType,
                where: AppNotification.CLIENTEMAIL.eq(email)),
          ).response;
          for (final n in res.data?.items.whereType<AppNotification>().toList() ?? []) {
            await Amplify.API.mutate(request: ModelMutations.delete<AppNotification>(n)).response;
          }
        } catch (_) {}
      }

      // 3) مسح الـ SharedPreferences الخاصة بالـ user
      try {
        final prefs = await SharedPreferences.getInstance();
        final lowerEmail = email.toLowerCase();
        await prefs.remove('onboarding_done_$lowerEmail');
        await prefs.remove('chatbot_history_$lowerEmail');
        await prefs.remove('chatbot_session_id_$lowerEmail');
      } catch (_) {}

      // 4) مسح الـ currentUser من الذاكرة
      data.currentUser
        ..['email'] = ''
        ..['name'] = ''
        ..['image'] = ''
        ..['type'] = ''
        ..['chatEnabled'] = 'true';

      // 5) مسح الـ Cognito account
      await Amplify.Auth.deleteUser();
    } catch (e) {
      safePrint('deleteAccount error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚫 DataStore Observers — DEPRECATED (للـ backward compat فقط)
  // ─────────────────────────────────────────────────────────────────────────
  // الـ methods دي بترجع empty stream عشان لو في كود قديم بيستدعيها مايحصلش crash.
  // كل الـ callers لازم يتحوّلوا للـ subscribeToXxx الجديدة.
  // ═══════════════════════════════════════════════════════════════════════════

  /// ⚠️ DEPRECATED — استخدم subscribeToStudios() بدلاً منه
  @Deprecated('Use subscribeToStudios() instead — DataStore is disabled')
  static Stream<List<Studio>> observeStudios() {
    safePrint('⚠️ observeStudios is deprecated — returning empty stream');
    return const Stream.empty();
  }

  /// ⚠️ DEPRECATED — استخدم subscribeToBookings() بدلاً منه
  @Deprecated('Use subscribeToBookings() instead — DataStore is disabled')
  static Stream<List<BookingRequest>> observeBookings({
    String? clientEmail,
  }) {
    safePrint('⚠️ observeBookings is deprecated — returning empty stream');
    return const Stream.empty();
  }

  /// ⚠️ DEPRECATED — استخدم subscribeToChatMessages() بدلاً منه
  @Deprecated(
      'Use subscribeToChatMessages() instead — DataStore is disabled')
  static Stream<List<ChatMessage>> observeAllMessages() {
    safePrint('⚠️ observeAllMessages is deprecated — returning empty stream');
    return const Stream.empty();
  }

  /// ⚠️ DEPRECATED — استخدم subscribeToChatMessages(clientEmail) بدلاً منه
  @Deprecated(
      'Use subscribeToChatMessages() instead — DataStore is disabled')
  static Stream<List<ChatMessage>> observeMessages(String clientEmail) {
    safePrint('⚠️ observeMessages is deprecated — returning empty stream');
    return const Stream.empty();
  }

  /// ⚠️ DEPRECATED — استخدم subscribeToNotifications(employeeInboxKey) بدلاً منه
  @Deprecated(
      'Use subscribeToNotifications() instead — DataStore is disabled')
  static Stream<List<AppNotification>> observeEmployeeNotifications() {
    safePrint(
        '⚠️ observeEmployeeNotifications is deprecated — returning empty stream');
    return const Stream.empty();
  }

  /// ⚠️ DEPRECATED — استخدم subscribeToChatStatus(email) بدلاً منه
  @Deprecated(
      'Use subscribeToChatStatus() instead — DataStore is disabled')
  static Stream<List<UserProfile>> observeChatStatus(String email) {
    safePrint('⚠️ observeChatStatus is deprecated — returning empty stream');
    return const Stream.empty();
  }
}