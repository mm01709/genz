import 'package:flutter/material.dart';
import 'package:genz/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final int initialTab;
  const PrivacyPolicyScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          title: Text('Legal',
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: subText,
            indicatorColor: AppColors.primary,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'Privacy Policy'),
              Tab(text: 'Terms of Service'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TextPage(content: _privacyText, textColor: textColor, subText: subText),
            _TextPage(content: _termsText,   textColor: textColor, subText: subText),
          ],
        ),
      ),
    );
  }
}

class _TextPage extends StatelessWidget {
  final List<_Block> content;
  final Color textColor;
  final Color subText;
  const _TextPage({required this.content, required this.textColor, required this.subText});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      itemCount: content.length,
      itemBuilder: (_, i) {
        final b = content[i];
        if (b.isHeading) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(b.text,
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(b.text,
              style: TextStyle(
                  color: subText, fontSize: 14, height: 1.65)),
        );
      },
    );
  }
}

class _Block {
  final String text;
  final bool isHeading;
  const _Block(this.text, {this.isHeading = false});
}

const _privacyText = [
  _Block('Privacy Policy', isHeading: true),
  _Block('Last updated: May 2026'),

  _Block('1. Information We Collect', isHeading: true),
  _Block(
      'We collect information you provide when you create an account, including your name, email address, and profile photo. We also collect booking details such as the studio you select, the date and time of your session, and the total price.'),

  _Block('2. How We Store Your Data', isHeading: true),
  _Block(
      'Your data is stored securely on Amazon Web Services (AWS). Account credentials are managed through Amazon Cognito with industry-standard encryption. Profile images and studio photos are stored in Amazon S3 with restricted access.'),

  _Block('3. Data Sharing', isHeading: true),
  _Block(
      'We do not sell your personal information to any third party. Your booking details are shared only with studio employees so they can process your reservation. We do not share your data with advertisers or analytics companies.'),

  _Block('4. Notifications', isHeading: true),
  _Block(
      'We send in-app notifications to inform you about booking status changes — such as when your booking is Approved, Rejected, or marked as Done. You may manage notification preferences in the Settings screen.'),

  _Block('5. Your Rights & Data Deletion', isHeading: true),
  _Block(
      'You have the right to access, correct, or delete your personal data at any time. To permanently delete your account, go to the side menu and tap "Delete Account." This action removes your credentials from Amazon Cognito immediately. Some booking history may be retained for business and legal records as required by applicable law.'),

  _Block('6. Security', isHeading: true),
  _Block(
      'All data transmitted between the app and our servers is encrypted using HTTPS. Passwords are never stored in plain text. We regularly review our security practices to keep your data safe.'),

  _Block('7. Children\'s Privacy', isHeading: true),
  _Block(
      'GenZ Studio is not intended for users under the age of 13. We do not knowingly collect personal information from children. If you believe a child has provided us with personal data, please contact us so we can delete it.'),

  _Block('8. Changes to This Policy', isHeading: true),
  _Block(
      'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app. Continued use of GenZ Studio after any changes constitutes your acceptance of the updated policy.'),

  _Block('9. Contact', isHeading: true),
  _Block(
      'If you have any questions or concerns about this Privacy Policy, please reach out to us through the in-app Support Chat.'),
];

const _termsText = [
  _Block('Terms of Service', isHeading: true),
  _Block('Last updated: May 2026'),

  _Block('1. Acceptance of Terms', isHeading: true),
  _Block(
      'By creating an account and using GenZ Studio, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree with any part of these terms, please do not use the application.'),

  _Block('2. Account Responsibilities', isHeading: true),
  _Block(
      'You are responsible for maintaining the confidentiality of your account password. You agree to provide accurate and up-to-date information when registering and to keep your profile current. You may not share your account with others or use another person\'s account without permission.'),

  _Block('3. Booking Policy', isHeading: true),
  _Block(
      'Bookings are subject to studio availability at the time of your request. Once a booking is submitted, it enters a Pending state until reviewed by a studio employee. Upon approval, your session is confirmed for the selected time slot. '
      'You are expected to arrive on time for your booking. Repeated no-shows or late cancellations may result in restrictions on your account.'),

  _Block('4. Cancellations', isHeading: true),
  _Block(
      'If you need to cancel a booking, please do so as early as possible by contacting the team through the in-app Support Chat. Cancellation policies may vary and will be communicated by the studio team upon approval of your booking.'),

  _Block('5. Prohibited Conduct', isHeading: true),
  _Block(
      'You agree not to misuse the platform in any way, including but not limited to: submitting false or duplicate bookings, harassing or threatening employees or other users, attempting to access systems or data beyond your authorization, or using the app for any unlawful purpose.'),

  _Block('6. In-App Communication', isHeading: true),
  _Block(
      'The in-app chat and support features are provided for booking-related communication only. Abusive, offensive, or inappropriate messages are strictly prohibited and may result in immediate account suspension.'),

  _Block('7. Intellectual Property', isHeading: true),
  _Block(
      'All content within GenZ Studio — including designs, logos, text, and code — is the property of GenZ Studio and is protected by applicable intellectual property laws. You may not copy, reproduce, or distribute any part of the app without our written permission.'),

  _Block('8. Limitation of Liability', isHeading: true),
  _Block(
      'GenZ Studio is provided "as is" without warranties of any kind. We are not liable for any indirect, incidental, or consequential damages arising from your use of the platform, including scheduling conflicts, technical outages, or data loss caused by circumstances beyond our control.'),

  _Block('9. Account Termination', isHeading: true),
  _Block(
      'We reserve the right to suspend or terminate your account at any time if you violate these Terms of Service, without prior notice. You may also delete your own account at any time from the drawer menu.'),

  _Block('10. Changes to Terms', isHeading: true),
  _Block(
      'We reserve the right to modify these Terms of Service at any time. You will be notified of significant changes through the app. Your continued use of GenZ Studio after any modification constitutes your acceptance of the revised terms.'),

  _Block('11. Contact', isHeading: true),
  _Block(
      'If you have any questions about these Terms of Service, please contact us through the in-app Support Chat.'),
];
