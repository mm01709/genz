import 'dart:math';
import 'package:genz/data/storage.dart';

// ─── Global State ──────────────────────────────────────────────────────────────

List<Map<String, String>> bookingRequests = [];
List<Map<String, String>> appNotifications = [];
List<Map<String, String>> appMessages = [];

List<String> enabledChatEmails = [];
Map<String, String> clientChatClearTimestamps = {};

Map<String, String> currentUser = {
  'name': '',
  'image': '',
  'type': '',   // ← فاضي عشان نعرف إنه لسه ما اتحملش من AWS
  'email': '',
};

// ─── Avatar Helpers ────────────────────────────────────────────────────────────

String getRandomAvatarUrl(String seed, {bool isGuest = false}) {
  if (isGuest) {
    return 'https://robohash.org/${Uri.encodeComponent(seed)}?set=set4';
  }
  return 'https://i.pravatar.cc/150?u=${Uri.encodeComponent(seed)}';
}

// ─── Studio & Equipment Pricing ────────────────────────────────────────────────

const Map<String, int> studioPrices = {
  'Studio A (Portrait)': 100,
  'Studio B (Product)': 150,
  'Studio C (Wedding)': 250,
};

const Map<String, int> equipmentPrices = {
  'Pro Lighting Kit': 50,
  '4K Camera (Sony A7IV)': 100,
  'Reflector Set': 20,
  'Smoke Machine': 40,
  'Background Stands': 30,
};

// ─── Availability Check ─────────────────────────────────────────────────────────

bool isStudioAvailable(
    String studioName, DateTime startRequest, DateTime endRequest) {
  for (final request in bookingRequests) {
    if (request['studio'] != studioName) continue;
    if (request['status'] == 'Rejected') continue;

    final existingStart = DateTime.tryParse(request['fullStartDateTime'] ?? '');
    final existingEnd = DateTime.tryParse(request['fullEndDateTime'] ?? '');
    if (existingStart == null || existingEnd == null) continue;

    if (startRequest.isBefore(existingEnd) &&
        endRequest.isAfter(existingStart)) {
      return false;
    }
  }
  return true;
}

// ─── Guest Data ────────────────────────────────────────────────────────────────

Future<void> generateGuestData() async {
  final permanentGuest = await StorageService.loadPermanentGuest();

  if (permanentGuest.isNotEmpty) {
    currentUser['name'] = permanentGuest['name']!;
    currentUser['image'] = permanentGuest['image']!;
    currentUser['email'] = permanentGuest['email']!;
    currentUser['type'] = 'guest';
  } else {
    const adjectives = [
      'Happy', 'Lucky', 'Sunny', 'Cool', 'Fast', 'Smart'
    ];
    const nouns = ['Tiger', 'Panda', 'Eagle', 'Traveler', 'Artist'];
    final random = Random();
    final name =
        '${adjectives[random.nextInt(adjectives.length)]} ${nouns[random.nextInt(nouns.length)]}';
    final image = getRandomAvatarUrl(name, isGuest: true);
    final email = 'guest_${random.nextInt(99999)}@guest.com';

    currentUser['name'] = name;
    currentUser['image'] = image;
    currentUser['type'] = 'guest';
    currentUser['email'] = email;

    await StorageService.savePermanentGuest(name, image, email);
  }

  await StorageService.saveCurrentUser();
}