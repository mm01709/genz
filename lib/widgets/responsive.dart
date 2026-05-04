// lib/widgets/responsive.dart
// ═══════════════════════════════════════════════════════════════════════════════
// Responsive — helpers لكل المقاسات
// ─────────────────────────────────────────────────────────────────────────────
// Breakpoints:
//   mobile  : < 600px
//   tablet  : 600 - 1024px
//   desktop : ≥ 1024px
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

enum DeviceType { mobile, tablet, desktop, largeDesktop }

class Responsive {
  /// تحديد نوع الجهاز حسب الـ width
  static DeviceType deviceType(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < Breakpoints.mobile) return DeviceType.mobile;
    if (w < Breakpoints.tablet) return DeviceType.tablet;
    if (w < Breakpoints.desktop) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.mobile;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= Breakpoints.mobile && w < Breakpoints.tablet;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet;

  /// عدد الـ columns للـ Grid حسب المقاس
  static int gridColumns(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    switch (deviceType(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
      case DeviceType.largeDesktop:
        return largeDesktop;
    }
  }

  /// Padding حسب المقاس
  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < Breakpoints.mobile) return const EdgeInsets.all(16);
    if (w < Breakpoints.tablet) return const EdgeInsets.all(24);
    if (w < Breakpoints.desktop) return const EdgeInsets.all(32);
    return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
  }

  /// Max content width — للـ desktop عشان مايبقاش الـ content بعرض الشاشة
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < Breakpoints.tablet) return w;
    return 1200; // max content width على الـ desktop
  }

  /// Font scale factor
  static double fontScale(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isTablet(context)) return 1.05;
    return 1.1;
  }
}

/// Widget يحدد نسخة الـ child حسب المقاس
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.deviceType(context));
  }
}

/// Constraint widget يحط max width للـ content
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  const CenteredContent({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final mw = maxWidth ?? Responsive.maxContentWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mw),
        child: child,
      ),
    );
  }
}