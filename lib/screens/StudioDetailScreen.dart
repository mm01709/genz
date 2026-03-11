// lib/screens/StudioDetailScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:genz/data/data.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/theme/app_theme.dart';

class StudioDetailScreen extends StatelessWidget {
  final Map<String, dynamic> studio;
  final VoidCallback? onBook;

  const StudioDetailScreen({super.key, required this.studio, this.onBook});

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDark ? AppColors.darkBg      : AppColors.lightBg;
    final cardColor  = isDark ? AppColors.darkCard    : AppColors.lightSurface;
    final textColor  = isDark ? AppColors.darkText    : AppColors.lightText;
    final subText    = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final borderColor= isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final loc        = AppLocalizations.of(context);

    final name        = studio['name'] as String? ?? '';
    final type        = studio['type'] as String? ?? '';
    final price       = studio['pricePerHour'] as int? ?? 0;
    final description = studio['description'] as String? ?? '';
    final available   = studio['available'] as bool? ?? true;
    final image       = studio['image'] as String?;

    final Map<String, IconData> typeIcons = {
      'Portrait': Icons.portrait_rounded,
      'Product' : Icons.inventory_2_rounded,
      'Wedding' : Icons.favorite_rounded,
      'Video'   : Icons.videocam_rounded,
      'Fashion' : Icons.style_rounded,
    };
    final icon = typeIcons[type] ?? Icons.camera_alt_rounded;

    final Map<String, Color> typeColors = {
      'Portrait': const Color(0xFF6C63FF),
      'Product' : const Color(0xFF22C55E),
      'Wedding' : const Color(0xFFEF4444),
      'Video'   : const Color(0xFF3B82F6),
      'Fashion' : const Color(0xFFF59E0B),
    };
    final accent = typeColors[type] ?? AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: accent,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or gradient
                  (image != null && image.startsWith('data:image'))
                      ? Image.memory(
                    base64Decode(image.split(',')[1]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientBg(accent, icon),
                  )
                      : (image != null && image.startsWith('http'))
                      ? Image.network(image, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientBg(accent, icon))
                      : _gradientBg(accent, icon),
                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                      ),
                    ),
                  ),
                  // Price badge
                  Positioned(top: 90, right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('\$$price/hr',
                          style: TextStyle(color: accent,
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  // Availability badge
                  Positioned(top: 90, left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: available ? AppColors.success : AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(available ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(available ? 'Available' : 'Unavailable',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
              title: Text(name,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 18)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),

          // ─── Content ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type chip
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, color: accent, size: 16),
                        const SizedBox(width: 6),
                        Text(type, style: TextStyle(color: accent,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Description
                  if (description.isNotEmpty) ...[
                    Text('About This Studio',
                        style: TextStyle(color: textColor,
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: TextStyle(color: subText, fontSize: 14, height: 1.6)),
                    const SizedBox(height: 20),
                  ],

                  // Details card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(children: [
                      _detailRow(Icons.attach_money_rounded, 'Price per Hour',
                          '\$$price', AppColors.success, subText, borderColor),
                      _divider(borderColor),
                      _detailRow(Icons.camera_indoor_rounded, 'Studio Type',
                          type, accent, subText, borderColor),
                      _divider(borderColor),
                      _detailRow(Icons.circle_rounded, 'Availability',
                          available ? 'Open for Booking' : 'Currently Unavailable',
                          available ? AppColors.success : AppColors.error, subText, borderColor),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // Book button (client only)
                  if (onBook != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: available ? onBook : null,
                        icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
                        label: Text(loc.translate('book'),
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          disabledBackgroundColor: subText.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBg(Color accent, IconData icon) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [accent, accent.withOpacity(0.6)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.3)),
  );

  Widget _divider(Color color) => Divider(height: 1, color: color, indent: 16, endIndent: 16);

  Widget _detailRow(IconData icon, String label, String value,
      Color iconColor, Color subColor, Color borderColor) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: subColor, fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: iconColor,
              fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
}