import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genz/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const OnboardingScreen({super.key, this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _ctrl = PageController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  int _page = 0;

  static const _pages = [
    _OPage(
      icon: Icons.waving_hand_rounded,
      color: Color(0xFF6C63FF),
      title: 'Welcome to GenZ Studio',
      subtitle: 'Your complete studio booking platform',
      steps: [],
      isSplash: true,
    ),
    _OPage(
      icon: Icons.search_rounded,
      color: Color(0xFF22C55E),
      title: 'Browse Studios',
      subtitle: 'Find the perfect studio for your shoot',
      steps: [
        _Step(Icons.home_rounded,       'Open the app — studios appear on the home screen'),
        _Step(Icons.tune_rounded,        'Tap a studio card to see full details & photos'),
        _Step(Icons.check_circle_rounded,'Green badge = Available · Red badge = Unavailable'),
        _Step(Icons.photo_library_rounded,'Swipe photos in the gallery to see the space'),
      ],
    ),
    _OPage(
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF3B82F6),
      title: 'Book a Studio',
      subtitle: 'Reserve your session in a few taps',
      steps: [
        _Step(Icons.touch_app_rounded,   'Tap Book on any available studio'),
        _Step(Icons.edit_calendar_rounded,'Choose your date and start/end time'),
        _Step(Icons.send_rounded,        'Submit — your request goes to the team'),
        _Step(Icons.notifications_rounded,'You get notified when it\'s Approved or Rejected'),
      ],
    ),
    _OPage(
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF8B5CF6),
      title: 'Track Your Bookings',
      subtitle: 'Always know your booking status',
      steps: [
        _Step(Icons.menu_rounded,        'Open the side menu (drawer) → My Bookings'),
        _Step(Icons.pending_rounded,     'Pending = waiting for employee approval'),
        _Step(Icons.check_rounded,       'Approved = confirmed, show up on time!'),
        _Step(Icons.done_all_rounded,    'Done = session completed successfully'),
      ],
    ),
    _OPage(
      icon: Icons.support_agent_rounded,
      color: Color(0xFFF59E0B),
      title: 'Support & Help',
      subtitle: 'We\'re always here when you need us',
      steps: [
        _Step(Icons.chat_bubble_rounded, 'Menu → Support Chat to talk to our team'),
        _Step(Icons.smart_toy_rounded,   'Use the AI Assistant for instant answers'),
        _Step(Icons.confirmation_number_rounded, 'Menu → My Tickets to track support requests'),
        _Step(Icons.play_circle_rounded, 'Menu → App Tour to replay this guide anytime'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _animCtrl.forward(from: 0);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isLast = _page == _pages.length - 1;
    final p = _pages[_page];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(children: [
                if (_page > 0)
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: subText, size: 18),
                    onPressed: () => _ctrl.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut),
                  )
                else
                  const SizedBox(width: 48),
                const Spacer(),
                // Page counter
                Text('${_page + 1} / ${_pages.length}',
                    style: TextStyle(color: subText, fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: _finish,
                  child: Text('Skip',
                      style: TextStyle(
                          color: subText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),

            // ── Page content ───────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) => _buildPage(
                    _pages[i], textColor, subText, cardColor, borderColor),
              ),
            ),

            // ── Dots ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 24 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? p.color
                        : subText.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // ── Button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _ctrl.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      isLast ? 'Get Started' : 'Next',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isLast
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OPage p, Color textColor, Color subText,
      Color cardColor, Color borderColor) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + title block
            Center(
              child: Column(children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(p.icon, size: 52, color: p.color),
                ),
                const SizedBox(height: 20),
                Text(p.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 8),
                Text(p.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: subText, fontSize: 14, height: 1.5)),
              ]),
            ),

            if (p.isSplash) ...[
              const SizedBox(height: 32),
              _splashFeatures(p.color, textColor, subText),
            ] else ...[
              const SizedBox(height: 28),
              // Step-by-step cards
              ...p.steps.asMap().entries.map((e) {
                final idx = e.key;
                final step = e.value;
                return _stepCard(idx + 1, step, p.color, cardColor,
                    borderColor, textColor, subText);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepCard(int num, _Step step, Color accent, Color cardColor,
      Color borderColor, Color textColor, Color subText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        // Step number badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text('$num',
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        // Icon
        Icon(step.icon, color: accent, size: 20),
        const SizedBox(width: 10),
        // Text
        Expanded(
          child: Text(step.label,
              style: TextStyle(
                  color: textColor, fontSize: 13, height: 1.4)),
        ),
      ]),
    );
  }

  Widget _splashFeatures(Color accent, Color textColor, Color subText) {
    final features = [
      (Icons.camera_indoor_rounded, 'Multiple studio types', 'Portrait, Product, Wedding, Video, Fashion'),
      (Icons.calendar_today_rounded, 'Easy booking', 'Pick date & time, get instant confirmation'),
      (Icons.notifications_active_rounded, 'Real-time updates', 'Notifications for every status change'),
      (Icons.support_agent_rounded, 'Always supported', 'Chat support + AI assistant 24/7'),
    ];
    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(f.$1, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.$2, style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(f.$3, style: TextStyle(
                  color: subText, fontSize: 12, height: 1.4)),
            ],
          )),
        ]),
      )).toList(),
    );
  }
}

class _OPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<_Step> steps;
  final bool isSplash;
  const _OPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.steps,
    this.isSplash = false,
  });
}

class _Step {
  final IconData icon;
  final String label;
  const _Step(this.icon, this.label);
}
