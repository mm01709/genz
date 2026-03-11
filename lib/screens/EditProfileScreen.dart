// lib/screens/EditProfileScreen.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genz/data/data.dart';
import 'package:genz/data/aws_storage.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/services/settings_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();

  // ✅ بدل File: XFile + Bytes (يشتغل على Web, Windows, Android)
  XFile? _pickedFile;
  Uint8List? _pickedBytes;

  String _displayImageUrl = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    SettingsService.locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SettingsService.locale.removeListener(_onLocaleChanged);
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    _nameCtrl.text = currentUser['name'] ?? '';
    final imageVal = currentUser['image'] ?? '';
    if (imageVal.isNotEmpty) {
      if (imageVal.startsWith('http')) {
        if (mounted) setState(() => _displayImageUrl = imageVal);
      } else {
        final freshUrl = await AWSStorageService.getProfileImageUrl(imageVal);
        if (mounted) setState(() => _displayImageUrl = freshUrl ?? '');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      // ✅ readAsBytes يشتغل على كل المنصات
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _pickedFile = image;
          _pickedBytes = bytes;
          _displayImageUrl = '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final newName = _nameCtrl.text.trim().isEmpty
          ? (currentUser['name'] ?? 'User')
          : _nameCtrl.text.trim();

      String finalImageKey = currentUser['image'] ?? '';

      if (_pickedFile != null && _pickedBytes != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Row(children: [
              SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('Uploading image...'),
            ]),
            duration: Duration(seconds: 30),
            backgroundColor: AppColors.primary,
          ));
        }

        String? uploadedKey;
        final ext = _pickedFile!.name.split('.').last.toLowerCase();

        // ✅ Web / Windows: رفع من bytes
        // ✅ Android: رفع من path (أسرع)
        if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
          uploadedKey = await AWSStorageService.uploadProfileImageBytes(
            bytes: _pickedBytes!,
            extension: ext,
          );
        } else {
          uploadedKey = await AWSStorageService.uploadProfileImage(_pickedFile!.path);
        }

        if (uploadedKey != null) {
          finalImageKey = uploadedKey;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to upload image. Name will still be saved.'),
              backgroundColor: AppColors.warning,
            ));
          }
        }
      }

      final saved = await AWSStorageService.updateUserProfile(
        email: currentUser['email'] ?? '',
        name: newName,
        imageUrl: finalImageKey.isNotEmpty ? finalImageKey : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (saved) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ));
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to save profile.'),
            backgroundColor: AppColors.warning,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.warning,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider _profileImage() {
    if (_pickedBytes != null) return MemoryImage(_pickedBytes!);
    if (_displayImageUrl.isNotEmpty) return NetworkImage(_displayImageUrl);
    final seed = currentUser['email'] ?? 'user';
    return NetworkImage('https://i.pravatar.cc/150?u=$seed');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final inputColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? 60.0 : 24.0;
    final avatarR = size.width > 600 ? 70.0 : 54.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(loc.translate('edit_profile'),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : TextButton(
                onPressed: _saveProfile,
                child: Text(loc.translate('save'),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
          child: Column(children: [
            Center(
              child: Stack(children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                    boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: CircleAvatar(
                    radius: avatarR,
                    backgroundColor: AppColors.darkBorder,
                    backgroundImage: _profileImage(),
                  ),
                ),
                Positioned(
                  bottom: 4, right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text(loc.translate('tap_to_change_photo'),
                style: TextStyle(fontSize: 12, color: subText)),
            const SizedBox(height: 32),

            // Name field
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loc.translate('full_name'),
                  style: TextStyle(fontSize: 13, color: subText, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true, fillColor: inputColor,
                  hintText: loc.translate('enter_your_name'),
                  hintStyle: TextStyle(color: subText),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  prefixIcon: Icon(Icons.person_outline, color: subText, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Email (read-only)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loc.translate('email'),
                  style: TextStyle(fontSize: 13, color: subText, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: inputColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(children: [
                  Icon(Icons.email_outlined, color: subText, size: 20),
                  const SizedBox(width: 12),
                  Text(currentUser['email'] ?? '',
                      style: TextStyle(color: subText, fontSize: 14)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}