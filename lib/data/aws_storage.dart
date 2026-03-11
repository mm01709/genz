// lib/data/aws_storage.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/painting.dart';
import 'package:genz/models/ModelProvider.dart';
import 'data.dart';

// ✅ DataStore معطل بسبب مشكلة Unauthorized على owner-based models (ChatMessage/BookingRequest/AppNotification)
// الحل: نستخدم API مباشرة على كل الـ platforms (Android/iOS/Web/Windows)
bool get _isDataStoreSupported => false;

/// ✅ AWS-only service layer (DataStore + Cognito).
class AWSStorageService {
  static const String employeeInboxKey = 'EMPLOYEE_INBOX';

  // ───────────────────────────────────────────────────────────────────────────
  // Auth helpers
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> requireSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    if (!session.isSignedIn) {
      throw Exception('NOT_SIGNED_IN');
    }
  }

  static Future<Map<String, String>> getCurrentUserInfo() async {
    try {
      final session =
      await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      // ✅ userPoolTokensResult.value يمكن يفشل على Web لو الـ token مش جاهز
      List<String> groups = [];
      try {
        groups = session.userPoolTokensResult.value.idToken.groups;
      } catch (e) {
        safePrint('⚠️ Could not read groups from token (Web): $e');
        // ✅ على Web: نجيب الـ groups من user attributes لو متاحة
      }

      final attrs = await Amplify.Auth.fetchUserAttributes();
      String name = '';
      String email = '';
      String customType = '';

      for (final attr in attrs) {
        if (attr.userAttributeKey.key == 'name') name = attr.value;
        if (attr.userAttributeKey.key == 'email') email = attr.value;
        // ✅ بعض Cognito setups بتخزن الـ groups في custom attribute
        if (attr.userAttributeKey.key == 'custom:type' ||
            attr.userAttributeKey.key == 'custom:role') {
          customType = attr.value;
        }
      }

      // ✅ حدد النوع: groups → customType → default user
      final isEmployee = groups.contains('Employee') ||
          customType.toLowerCase() == 'employee';

      return {
        'email': email,
        'name': name.isNotEmpty
            ? name
            : (email.isNotEmpty ? email.split('@').first : ''),
        'type': isEmployee ? 'employee' : 'user',
        'groups': groups.join(','),
      };
    } catch (e) {
      safePrint('getCurrentUserInfo error: $e');
      return {};
    }
  }

  static Future<void> loadCurrentUser() async {
    try {
      await requireSignedIn();

      final info = await getCurrentUserInfo();
      if (info.isEmpty) return;

      currentUser['email'] = info['email'] ?? '';
      currentUser['name'] = info['name'] ?? '';
      currentUser['type'] = info['type'] ?? 'user';

      final email = info['email'] ?? '';
      if (email.isEmpty) return;

      // ✅ اجلب من API مباشرة (مش DataStore cache) عشان نضمن أحدث بيانات
      List<UserProfile> profiles = [];
      try {
        final apiResponse = await Amplify.API.query(
          request: ModelQueries.list(
            UserProfile.classType,
            where: UserProfile.EMAIL.eq(email),
          ),
        ).response;
        profiles =
            apiResponse.data?.items.whereType<UserProfile>().toList() ?? [];
      } catch (_) {
        // fallback على DataStore لو API فشل
        try {
          profiles = await Amplify.DataStore.query(
            UserProfile.classType,
            where: UserProfile.EMAIL.eq(email),
          );
        } catch (_) {}
      }

      // ✅ لو profiles فاضية من الـ API، جرب DataStore كـ fallback
      if (profiles.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 800));
        try {
          profiles = await Amplify.DataStore.query(
            UserProfile.classType,
            where: UserProfile.EMAIL.eq(email),
          );
        } catch (_) {}
      }

      if (profiles.isNotEmpty) {
        final profile = profiles.first;

        // ✅ حمّل الاسم من UserProfile لو موجود ومختلف
        if (profile.name?.isNotEmpty ?? false) {
          currentUser['name'] = profile.name!;
        }

        // ✅ حمّل الشات status
        currentUser['chatEnabled'] = (profile.chatEnabled ?? true).toString();

        // ✅ حمّل الصورة
        if (profile.image?.isNotEmpty ?? false) {
          final storedValue = profile.image!;
          if (!storedValue.startsWith('http')) {
            // S3 Key → اجلب URL طازة
            final freshUrl = await getProfileImageUrl(storedValue);
            currentUser['image'] =
                freshUrl ?? 'https://i.pravatar.cc/150?u=$email';
          } else {
            currentUser['image'] = storedValue;
          }
        } else {
          // ✅ لو مفيش صورة في Profile، حافظ على الحالية لو موجودة
          if (currentUser['image'] == null || currentUser['image']!.isEmpty) {
            currentUser['image'] = 'https://i.pravatar.cc/150?u=$email';
          }
        }
      } else {
        // ✅ مفيش profile فعلاً → حط default وأنشئ واحد
        // بس لا تمسح الصورة الحالية لو موجودة من session سابقة
        if (currentUser['image'] == null || currentUser['image']!.isEmpty) {
          currentUser['image'] = 'https://i.pravatar.cc/150?u=$email';
        }
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

      List<UserProfile> results = [];
      try {
        final apiResponse = await Amplify.API.query(
          request: ModelQueries.list(
            UserProfile.classType,
            where: UserProfile.EMAIL.eq(email),
          ),
        ).response;
        results =
            apiResponse.data?.items.whereType<UserProfile>().toList() ?? [];
      } catch (_) {
        if (_isDataStoreSupported) {
          results = await Amplify.DataStore.query(
            UserProfile.classType,
            where: UserProfile.EMAIL.eq(email),
          );
        }
      }

      if (results.isEmpty) {
        final profile = UserProfile(
          email: email,
          name: currentUser['name'] ?? email.split('@').first,
          image: currentUser['image'],
          type: currentUser['type'],
          chatEnabled: true,
          lastUpdated: TemporalDateTime.now(),
        );
        // ✅ Web/Windows: API — Android/iOS: DataStore
        if (_isDataStoreSupported) {
          await Amplify.DataStore.save(profile);
        } else {
          await Amplify.API.mutate(
            request: ModelMutations.create(profile),
          ).response;
        }
      }
    } catch (e) {
      safePrint('ensureUserProfileExists error: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Real-time observe
  // ───────────────────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot<UserProfile>> observeChatStatus(String email) {
    if (!_isDataStoreSupported) return const Stream.empty(); // ✅ Web
    return Amplify.DataStore.observeQuery(
      UserProfile.classType,
      where: UserProfile.EMAIL.eq(email),
    );
  }

  static Stream<QuerySnapshot<Studio>> observeStudios() {
    if (_isDataStoreSupported) {
      return Amplify.DataStore.observeQuery(Studio.classType);
    }
    // ✅ Web: إرجع Stream فاضية — البيانات بتتحمل عن طريق loadStudios()
    return const Stream.empty();
  }

  static Stream<QuerySnapshot<ChatMessage>> observeMessages(
      String clientEmail) {
    if (!_isDataStoreSupported) return const Stream.empty(); // ✅ Web
    return Amplify.DataStore.observeQuery(
      ChatMessage.classType,
      where: ChatMessage.CLIENTEMAIL.eq(clientEmail),
    );
  }

  static Stream<QuerySnapshot<BookingRequest>> observeBookings({
    String? clientEmail,
  }) {
    if (!_isDataStoreSupported) return const Stream.empty(); // ✅ Web
    if (clientEmail != null && clientEmail.isNotEmpty) {
      return Amplify.DataStore.observeQuery(
        BookingRequest.classType,
        where: BookingRequest.CLIENTEMAIL.eq(clientEmail),
      );
    }
    return Amplify.DataStore.observeQuery(BookingRequest.classType);
  }

  static Stream<QuerySnapshot<ChatMessage>> observeAllMessages() {
    if (!_isDataStoreSupported) return const Stream.empty(); // ✅ Web
    return Amplify.DataStore.observeQuery(ChatMessage.classType);
  }

  static Stream<QuerySnapshot<AppNotification>> observeNotifications(
      String clientEmail) {
    if (!_isDataStoreSupported) return const Stream.empty(); // ✅ Web
    return Amplify.DataStore.observeQuery(
      AppNotification.classType,
      where: AppNotification.CLIENTEMAIL.eq(clientEmail),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Bookings
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> loadBookings() async {
    try {
      await requireSignedIn();

      final email = currentUser['email'] ?? '';
      final isEmployee = currentUser['type'] == 'employee';
      List<BookingRequest> results = [];

      if (_isDataStoreSupported) {
        // ✅ Android/iOS: DataStore
        results = isEmployee
            ? await Amplify.DataStore.query(BookingRequest.classType)
            : await Amplify.DataStore.query(
          BookingRequest.classType,
          where: BookingRequest.CLIENTEMAIL.eq(email),
        );
      } else {
        // ✅ API مباشرة مع limit كبير
        final request = isEmployee
            ? ModelQueries.list(BookingRequest.classType, limit: 1000)
            : ModelQueries.list(
          BookingRequest.classType,
          where: BookingRequest.CLIENTEMAIL.eq(email),
          limit: 1000,
        );
        final response = await Amplify.API.query(request: request).response;
        results = response.data?.items.whereType<BookingRequest>().toList() ?? [];
      }

      bookingRequests
        ..clear()
        ..addAll(results.map((b) => {
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
          'fullStartDateTime': b.fullStartDateTime ?? '',
          'fullEndDateTime': b.fullEndDateTime ?? '',
        }));
    } catch (e) {
      safePrint('loadBookings error: $e');
    }
  }

  static Future<bool> saveBooking(Map<String, String> booking) async {
    try {
      await requireSignedIn();

      final newBooking = BookingRequest(
        clientEmail: booking['clientEmail'] ?? '',
        clientName: booking['clientName'] ?? '',
        clientPhone: booking['clientPhone'],
        studio: booking['studio'] ?? '',
        date: booking['date'] ?? '',
        hours: booking['hours'] ?? '',
        price: booking['price'] ?? '0',
        equipment: booking['equipment'],
        status: booking['status'] ?? 'Pending',
        fullStartDateTime: booking['fullStartDateTime'] ?? '',
        fullEndDateTime: booking['fullEndDateTime'] ?? '',
      );

      if (_isDataStoreSupported) {
        // ✅ Android/iOS: DataStore
        final existingId = booking['id'];
        if (existingId != null && existingId.isNotEmpty) {
          final existing = await Amplify.DataStore.query(
            BookingRequest.classType,
            where: BookingRequest.ID.eq(existingId),
          );
          if (existing.isNotEmpty) {
            await Amplify.DataStore.save(
              existing.first.copyWith(status: booking['status'] ?? 'Pending'),
            );
            return true;
          }
        }
        await Amplify.DataStore.save(newBooking);
      } else {
        // ✅ Web/Windows: API mutation
        await Amplify.API.mutate(
          request: ModelMutations.create(newBooking),
        ).response;
      }

      booking['id'] = newBooking.id;
      return true;
    } catch (e) {
      safePrint('saveBooking error: $e');
      return false;
    }
  }

  static Future<bool> updateBookingStatus(
      String bookingId, String newStatus) async {
    try {
      await requireSignedIn();

      if (_isDataStoreSupported) {
        // ✅ Android/iOS: DataStore
        final results = await Amplify.DataStore.query(
          BookingRequest.classType,
          where: BookingRequest.ID.eq(bookingId),
        );
        if (results.isEmpty) return false;
        await Amplify.DataStore.save(results.first.copyWith(status: newStatus));
      } else {
        // ✅ Web/Windows: API
        final getResponse = await Amplify.API.query(
          request: ModelQueries.list(
            BookingRequest.classType,
            where: BookingRequest.ID.eq(bookingId),
          ),
        ).response;
        final items = getResponse.data?.items.whereType<BookingRequest>().toList() ?? [];
        if (items.isEmpty) return false;
        await Amplify.API.mutate(
          request: ModelMutations.update(items.first.copyWith(status: newStatus)),
        ).response;
      }

      return true;
    } catch (e) {
      safePrint('updateBookingStatus error: $e');
      return false;
    }
  }

  static Future<bool> deleteBooking(String bookingId) async {
    try {
      await requireSignedIn();

      if (_isDataStoreSupported) {
        // ✅ Android/iOS: DataStore
        final results = await Amplify.DataStore.query(
          BookingRequest.classType,
          where: BookingRequest.ID.eq(bookingId),
        );
        if (results.isEmpty) return false;
        await Amplify.DataStore.delete(results.first);
      } else {
        // ✅ Web/Windows: API
        final getResponse = await Amplify.API.query(
          request: ModelQueries.list(
            BookingRequest.classType,
            where: BookingRequest.ID.eq(bookingId),
          ),
        ).response;
        final items = getResponse.data?.items.whereType<BookingRequest>().toList() ?? [];
        if (items.isEmpty) return false;
        await Amplify.API.mutate(
          request: ModelMutations.delete(items.first),
        ).response;
      }

      return true;
    } catch (e) {
      safePrint('deleteBooking error: $e');
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Messages
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> loadMessages() async {
    try {
      await requireSignedIn();

      final email = currentUser['email'] ?? '';
      final isEmployee = currentUser['type'] == 'employee';
      List<ChatMessage> results = [];

      if (_isDataStoreSupported) {
        results = isEmployee
            ? await Amplify.DataStore.query(ChatMessage.classType)
            : await Amplify.DataStore.query(
          ChatMessage.classType,
          where: ChatMessage.CLIENTEMAIL.eq(email),
        );
      } else {
        // ✅ API مع limit كبير
        final request = isEmployee
            ? ModelQueries.list(ChatMessage.classType, limit: 1000)
            : ModelQueries.list(
          ChatMessage.classType,
          where: ChatMessage.CLIENTEMAIL.eq(email),
          limit: 1000,
        );
        final response = await Amplify.API.query(request: request).response;
        results = response.data?.items.whereType<ChatMessage>().toList() ?? [];
      }

      appMessages
        ..clear()
        ..addAll(results.map((m) => {
          'id': m.id,
          'senderName': m.senderName ?? '',
          'senderEmail': m.senderEmail ?? '',
          'clientEmail': m.clientEmail,
          'text': m.text ?? '',
          'time': m.time ?? '',
        }));

      appMessages.sort((a, b) => a['time']!.compareTo(b['time']!));
    } catch (e) {
      safePrint('loadMessages error: $e');
    }
  }

  static Future<bool> sendMessage(Map<String, String> msg) async {
    try {
      await requireSignedIn();

      final newMsg = ChatMessage(
        senderName: msg['senderName'] ?? '',
        senderEmail: msg['senderEmail'] ?? '',
        clientEmail: msg['clientEmail'] ?? '',
        text: msg['text'] ?? '',
        time: msg['time'] ?? DateTime.now().toIso8601String(),
      );

      if (_isDataStoreSupported) {
        await Amplify.DataStore.save(newMsg);
      } else {
        // ✅ Web/Windows: API mutation
        await Amplify.API.mutate(
          request: ModelMutations.create(newMsg),
        ).response;
      }

      msg['id'] = newMsg.id;
      return true;
    } catch (e) {
      safePrint('sendMessage error: $e');
      return false;
    }
  }

  static Future<void> deleteMessagesByClient(String clientEmail) async {
    try {
      await requireSignedIn();

      List<ChatMessage> msgs = [];
      if (_isDataStoreSupported) {
        msgs = await Amplify.DataStore.query(
          ChatMessage.classType,
          where: ChatMessage.CLIENTEMAIL.eq(clientEmail),
        );
        for (final m in msgs) await Amplify.DataStore.delete(m);
      } else {
        // ✅ Web/Windows: API
        final response = await Amplify.API.query(
          request: ModelQueries.list(
            ChatMessage.classType,
            where: ChatMessage.CLIENTEMAIL.eq(clientEmail),
          ),
        ).response;
        msgs = response.data?.items.whereType<ChatMessage>().toList() ?? [];
        for (final m in msgs) {
          await Amplify.API.mutate(request: ModelMutations.delete(m)).response;
        }
      }
    } catch (e) {
      safePrint('deleteMessagesByClient error: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Notifications
  // ───────────────────────────────────────────────────────────────────────────

  static Future<bool> sendEmployeeNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await requireSignedIn();
      final notif = AppNotification(
        clientEmail: employeeInboxKey,
        title: title,
        body: body,
        type: type,
        time: DateTime.now().toIso8601String(),
      );
      if (_isDataStoreSupported) {
        await Amplify.DataStore.save(notif);
      } else {
        await Amplify.API.mutate(request: ModelMutations.create(notif)).response;
      }
      return true;
    } catch (e) {
      safePrint('sendEmployeeNotification error: $e');
      return false;
    }
  }

  static Stream<QuerySnapshot<AppNotification>> observeEmployeeNotifications() {
    if (!_isDataStoreSupported) return const Stream.empty(); // ✅ Web/Windows
    return Amplify.DataStore.observeQuery(
      AppNotification.classType,
      where: AppNotification.CLIENTEMAIL.eq(employeeInboxKey),
      sortBy: [AppNotification.TIME.descending()],
    );
  }

  static Future<void> loadNotifications() async {
    try {
      await requireSignedIn();

      final email = currentUser['email'] ?? '';
      List<AppNotification> results = [];

      if (_isDataStoreSupported) {
        results = await Amplify.DataStore.query(
          AppNotification.classType,
          where: AppNotification.CLIENTEMAIL.eq(email),
          sortBy: [AppNotification.TIME.descending()],
        );
      } else {
        // ✅ Web/Windows: API
        final response = await Amplify.API.query(
          request: ModelQueries.list(
            AppNotification.classType,
            where: AppNotification.CLIENTEMAIL.eq(email),
          ),
        ).response;
        results = response.data?.items.whereType<AppNotification>().toList() ?? [];
        results.sort((a, b) => (b.time ?? '').compareTo(a.time ?? ''));
      }

      appNotifications
        ..clear()
        ..addAll(results.map((n) => {
          'id': n.id,
          'clientEmail': n.clientEmail,
          'title': n.title ?? '',
          'body': n.body ?? '',
          'type': n.type ?? '',
          'time': n.time ?? '',
        }));
    } catch (e) {
      safePrint('loadNotifications error: $e');
    }
  }

  static Future<bool> sendNotification({
    required String clientEmail,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await requireSignedIn();

      final notif = AppNotification(
        clientEmail: clientEmail,
        title: title,
        body: body,
        type: type,
        time: DateTime.now().toIso8601String(),
      );

      if (_isDataStoreSupported) {
        await Amplify.DataStore.save(notif);
      } else {
        // ✅ Web/Windows: API
        await Amplify.API.mutate(
          request: ModelMutations.create(notif),
        ).response;
      }
      return true;
    } catch (e) {
      safePrint('sendNotification error: $e');
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Chat enable/disable
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> enableChatForClient(String clientEmail,
      {bool enable = true}) async {
    try {
      await requireSignedIn();

      List<UserProfile> results = [];
      if (_isDataStoreSupported) {
        results = await Amplify.DataStore.query(
          UserProfile.classType,
          where: UserProfile.EMAIL.eq(clientEmail),
        );
      } else {
        final response = await Amplify.API.query(
          request: ModelQueries.list(UserProfile.classType,
              where: UserProfile.EMAIL.eq(clientEmail)),
        ).response;
        results = response.data?.items.whereType<UserProfile>().toList() ?? [];
      }

      if (results.isEmpty) {
        final profile = UserProfile(
          email: clientEmail,
          name: clientEmail.split('@').first,
          type: 'user',
          chatEnabled: enable,
          lastUpdated: TemporalDateTime.now(),
        );
        if (_isDataStoreSupported) {
          await Amplify.DataStore.save(profile);
        } else {
          await Amplify.API.mutate(request: ModelMutations.create(profile)).response;
        }
      } else {
        final updated = results.first.copyWith(
          chatEnabled: enable,
          lastUpdated: TemporalDateTime.now(),
        );
        if (_isDataStoreSupported) {
          await Amplify.DataStore.save(updated);
        } else {
          await Amplify.API.mutate(request: ModelMutations.update(updated)).response;
        }
      }
    } catch (e) {
      safePrint('enableChatForClient error: $e');
    }
  }

  // ✅ isChatEnabled — يجيب من API مباشرة (مش DataStore cache)
  static Future<bool> isChatEnabled(String clientEmail) async {
    try {
      await requireSignedIn();

      // ✅ اجلب من AppSync API مباشرة — بيضمن أحدث قيمة
      final response = await Amplify.API.query(
        request: ModelQueries.list(
          UserProfile.classType,
          where: UserProfile.EMAIL.eq(clientEmail),
        ),
      ).response;

      final items =
          response.data?.items.whereType<UserProfile>().toList() ?? [];

      if (items.isEmpty) return true; // default = enabled
      return items.first.chatEnabled ?? true;
    } catch (e) {
      safePrint('isChatEnabled API error: $e — falling back to DataStore');
      // fallback على DataStore لو API فشل
      try {
        final results = await Amplify.DataStore.query(
          UserProfile.classType,
          where: UserProfile.EMAIL.eq(clientEmail),
        );
        if (results.isEmpty) return true;
        return results.first.chatEnabled ?? true;
      } catch (_) {
        return true;
      }
    }
  }

  // ✅ isChatEnabledFromAPI — نفس isChatEnabled بس explicit من API
  static Future<bool> isChatEnabledFromAPI(String clientEmail) async {
    return isChatEnabled(clientEmail);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Studios
  // ───────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> loadStudios() async {
    await requireSignedIn();

    List<Studio> results = [];

    // ✅ API مباشرة على كل الـ platforms
    try {
      final response = await Amplify.API.query(
        request: ModelQueries.list(Studio.classType, limit: 1000),
      ).response;
      results = response.data?.items.whereType<Studio>().toList() ?? [];
    } catch (e) {
      safePrint('loadStudios API error: $e');
    }

    // ✅ تحويل S3 keys لـ URLs قابلة للعرض
    final List<Map<String, dynamic>> mapped = [];
    for (final s in results) {
      String imageUrl = s.image ?? '';
      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http') && !imageUrl.startsWith('data:')) {
        imageUrl = await getProfileImageUrl(imageUrl) ?? imageUrl;
      }
      mapped.add({
        'id': s.id,
        'name': s.name,
        'type': s.type,
        'pricePerHour': s.pricePerHour,
        'description': s.description ?? '',
        'image': imageUrl,
        'available': s.available,
      });
    }
    return mapped;
  }

  static Future<bool> saveStudio(Map<String, dynamic> data) async {
    try {
      await requireSignedIn();

      final studio = Studio(
        name: (data['name'] as String?) ?? '',
        type: (data['type'] as String?) ?? '',
        pricePerHour: (data['pricePerHour'] as int?) ?? 0,
        description: data['description'] as String?,
        image: data['image'] as String?,
        available: (data['available'] as bool?) ?? true,
      );

      if (_isDataStoreSupported) {
        await Amplify.DataStore.save(studio);
      } else {
        await Amplify.API.mutate(request: ModelMutations.create(studio)).response;
      }
      return true;
    } catch (e) {
      safePrint('saveStudio AWS error: $e');
      return false;
    }
  }

  static Future<bool> deleteStudio(String studioId) async {
    try {
      await requireSignedIn();

      List<Studio> results = [];
      if (_isDataStoreSupported) {
        results = await Amplify.DataStore.query(Studio.classType, where: Studio.ID.eq(studioId));
        if (results.isEmpty) return false;
        await Amplify.DataStore.delete(results.first);
      } else {
        final response = await Amplify.API.query(
          request: ModelQueries.list(Studio.classType, where: Studio.ID.eq(studioId)),
        ).response;
        results = response.data?.items.whereType<Studio>().toList() ?? [];
        if (results.isEmpty) return false;
        await Amplify.API.mutate(request: ModelMutations.delete(results.first)).response;
      }
      return true;
    } catch (e) {
      safePrint('deleteStudio AWS error: $e');
      return false;
    }
  }

  static Future<bool> updateStudio(
      String studioId, Map<String, dynamic> data) async {
    try {
      await requireSignedIn();

      List<Studio> results = [];
      if (_isDataStoreSupported) {
        results = await Amplify.DataStore.query(Studio.classType, where: Studio.ID.eq(studioId));
      } else {
        final response = await Amplify.API.query(
          request: ModelQueries.list(Studio.classType, where: Studio.ID.eq(studioId)),
        ).response;
        results = response.data?.items.whereType<Studio>().toList() ?? [];
      }
      if (results.isEmpty) return false;

      final updated = results.first.copyWith(
        name: data['name'] as String?,
        type: data['type'] as String?,
        pricePerHour: data['pricePerHour'] as int?,
        description: data['description'] as String?,
        image: data['image'] as String?,
        available: data['available'] as bool?,
      );

      if (_isDataStoreSupported) {
        await Amplify.DataStore.save(updated);
      } else {
        await Amplify.API.mutate(request: ModelMutations.update(updated)).response;
      }
      return true;
    } catch (e) {
      safePrint('updateStudio AWS error: $e');
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // S3 Image Upload
  // ───────────────────────────────────────────────────────────────────────────

  static Future<String?> uploadProfileImage(String localFilePath) async {
    try {
      await requireSignedIn();

      final email = currentUser['email'] ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = localFilePath.split('.').last.toLowerCase();
      final s3Key = 'private/profile-images/$email-$timestamp.$ext';

      final file = AWSFile.fromPath(localFilePath);

      await Amplify.Storage.uploadFile(
        localFile: file,
        path: StoragePath.fromString(s3Key),
        options: const StorageUploadFileOptions(
          metadata: {'content-type': 'image/jpeg'},
        ),
      ).result;

      safePrint('✅ Image uploaded to S3: $s3Key');
      return s3Key;
    } catch (e) {
      safePrint('uploadProfileImage error: $e');
      return null;
    }
  }

  /// ✅ رفع صورة من Bytes — يشتغل على Web + Windows + Android
  static Future<String?> uploadProfileImageBytes({
    required Uint8List bytes,
    required String extension,
  }) async {
    try {
      await requireSignedIn();

      final email = currentUser['email'] ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mimeType = extension == 'jpg' ? 'image/jpeg' : 'image/$extension';
      final s3Key = 'private/profile-images/$email-$timestamp.$extension';

      final file = AWSFile.fromData(bytes, contentType: mimeType);

      await Amplify.Storage.uploadFile(
        localFile: file,
        path: StoragePath.fromString(s3Key),
        options: StorageUploadFileOptions(metadata: {'content-type': mimeType}),
      ).result;

      safePrint('✅ Image (bytes) uploaded to S3: $s3Key');
      return s3Key;
    } catch (e) {
      safePrint('uploadProfileImageBytes error: $e');
      return null;
    }
  }

  static Future<String?> getProfileImageUrl(String s3Key) async {
    try {
      if (s3Key.isEmpty) return null;
      final urlResult = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(s3Key),
        options: const StorageGetUrlOptions(
          pluginOptions: S3GetUrlPluginOptions(
            expiresIn: Duration(hours: 1),
          ),
        ),
      ).result;
      return urlResult.url.toString();
    } catch (e) {
      safePrint('getProfileImageUrl error: $e');
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Update User Profile
  // ───────────────────────────────────────────────────────────────────────────

  static Future<bool> updateUserProfile({
    required String email,
    String? name,
    String? imageUrl,
  }) async {
    try {
      await requireSignedIn();

      // ✅ ابحث عبر AppSync API مباشرة
      List<UserProfile> results = [];
      try {
        final apiResponse = await Amplify.API.query(
          request: ModelQueries.list(
            UserProfile.classType,
            where: UserProfile.EMAIL.eq(email),
          ),
        ).response;
        results =
            apiResponse.data?.items.whereType<UserProfile>().toList() ?? [];
      } catch (_) {
        results = await Amplify.DataStore.query(
          UserProfile.classType,
          where: UserProfile.EMAIL.eq(email),
        );
      }

      if (results.isEmpty) {
        final profile = UserProfile(
          email: email,
          name: name ?? currentUser['name'],
          image: imageUrl,
          type: currentUser['type'],
          chatEnabled: true,
          lastUpdated: TemporalDateTime.now(),
        );
        // ✅ Web/Windows: API — Android/iOS: DataStore
        if (_isDataStoreSupported) {
          await Amplify.DataStore.save(profile);
        } else {
          await Amplify.API.mutate(
            request: ModelMutations.create(profile),
          ).response;
        }
      } else {
        final updated = results.first.copyWith(
          name: name ?? results.first.name,
          image: imageUrl ?? results.first.image,
          lastUpdated: TemporalDateTime.now(),
        );
        // ✅ Web/Windows: API — Android/iOS: DataStore
        if (_isDataStoreSupported) {
          await Amplify.DataStore.save(updated);
        } else {
          await Amplify.API.mutate(
            request: ModelMutations.update(updated),
          ).response;
        }
      }

      // ✅ تحديث Cognito name attribute عشان يتزامن عند فتح التطبيق تاني
      if (name != null && name.isNotEmpty) {
        try {
          await Amplify.Auth.updateUserAttribute(
            userAttributeKey: CognitoUserAttributeKey.name,
            value: name,
          );
          safePrint('✅ Cognito name updated to: $name');
        } catch (e) {
          safePrint('updateCognito name warning (non-fatal): $e');
        }
      }

      // ✅ تحديث currentUser محلياً فوراً
      if (name != null && name.isNotEmpty) {
        currentUser['name'] = name;
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          if (currentUser['image']?.startsWith('http') == true) {
            NetworkImage(currentUser['image']!).evict();
          }
          PaintingBinding.instance.imageCache.clear();
        } catch (_) {}

        if (!imageUrl.startsWith('http')) {
          final freshUrl = await getProfileImageUrl(imageUrl);
          currentUser['image'] = freshUrl ?? imageUrl;
        } else {
          currentUser['image'] = imageUrl;
        }
      }

      safePrint('✅ updateUserProfile done: name=$name, image=$imageUrl');
      return true;
    } catch (e) {
      safePrint('updateUserProfile error: $e');
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DataStore readiness
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> ensureDataStoreReady({bool clearFirst = false}) async {
    if (!_isDataStoreSupported) return; // ✅ DataStore: Android/iOS فقط
    try {
      if (clearFirst) {
        await Amplify.DataStore.clear();
        safePrint('🔄 DataStore cleared – starting fresh sync');
      }
      final completer = Completer<void>();
      late StreamSubscription sub;

      sub = Amplify.Hub.listen(HubChannel.DataStore, (event) {
        if (event.eventName == 'ready') {
          if (!completer.isCompleted) completer.complete();
          sub.cancel();
        }
      });

      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          sub.cancel();
          safePrint('⚠️ DataStore ready timeout – continuing anyway');
        },
      );

      safePrint('✅ DataStore ready');
    } catch (e) {
      safePrint('ensureDataStoreReady error: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Sign out
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      if (_isDataStoreSupported) await Amplify.DataStore.clear(); // ✅ DataStore: Android/iOS فقط

      currentUser['email'] = '';
      currentUser['name'] = '';
      currentUser['type'] = 'user';
      currentUser['image'] = '';
      currentUser['chatEnabled'] = 'true';

      bookingRequests.clear();
      appMessages.clear();
      appNotifications.clear();
    } catch (e) {
      safePrint('signOut error: $e');
    }
  }
}