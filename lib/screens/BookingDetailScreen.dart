// lib/screens/BookingDetailScreen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:genz/data/data.dart';
import 'package:genz/screens/chat_screen.dart';
import 'package:genz/services/app_localizations.dart';
import 'package:genz/theme/app_theme.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, String> booking;
  final int index;
  final Future<void> Function(int, String) onUpdateStatus;
  final Future<void> Function(int) onDelete;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.index,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late Map<String, String> booking;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    booking = Map.from(widget.booking);
  }

  Color get _statusColor {
    if (booking['status'] == 'Approved') return AppColors.success;
    if (booking['status'] == 'Rejected') return AppColors.error;
    return AppColors.warning;
  }

  IconData get _statusIcon {
    if (booking['status'] == 'Approved') return Icons.check_circle_rounded;
    if (booking['status'] == 'Rejected') return Icons.cancel_rounded;
    return Icons.hourglass_empty_rounded;
  }

  Future<void> _handleStatus(String newStatus) async {
    await widget.onUpdateStatus(widget.index, newStatus);
    if (mounted) setState(() => booking['status'] = newStatus);
  }

  // ── PDF Generation ──────────────────────────────────────────────────────────
  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();

    // Load Cairo font (supports Arabic & English)
    final fontData =
    await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldFontData =
    await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);

    // Status color mapping
    final statusHex = booking['status'] == 'Approved'
        ? PdfColor.fromHex('22C55E')
        : booking['status'] == 'Rejected'
        ? PdfColor.fromHex('EF4444')
        : PdfColor.fromHex('F59E0B');

    const primaryColor = PdfColor.fromInt(0xFF6C63FF);
    const darkText = PdfColor.fromInt(0xFF0D0D1A);
    const subText = PdfColor.fromInt(0xFF6B6B8A);
    const bgColor = PdfColor.fromInt(0xFFF5F5FA);
    const white = PdfColors.white;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header gradient-like bar ───────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 40, vertical: 28),
                color: const PdfColor.fromInt(0xFF6C63FF),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('GENZ Studios',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 22,
                              color: white,
                            )),
                        pw.SizedBox(height: 4),
                        pw.Text('Booking Confirmation',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              color: PdfColor.fromHex('C4C0FF'),
                            )),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: statusHex,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        booking['status'] ?? 'Pending',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 13,
                          color: white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              pw.Expanded(
                child: pw.Container(
                  color: bgColor,
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Booking ID
                      pw.Text('Booking ID',
                          style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10,
                              color: subText,
                              letterSpacing: 1.2)),
                      pw.SizedBox(height: 4),
                      pw.Text(booking['id'] ?? '-',
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 11,
                              color: darkText)),
                      pw.SizedBox(height: 28),

                      // ── Studio info card ─────────────────────────────
                      _pdfCard(
                        boldFont: boldFont,
                        font: font,
                        title: 'STUDIO DETAILS',
                        primaryColor: primaryColor,
                        children: [
                          _pdfRow('Studio', booking['studio'] ?? '-',
                              font: font, boldFont: boldFont,
                              valueColor: primaryColor),
                          _pdfDivider(),
                          _pdfRow('Date', booking['date'] ?? '-',
                              font: font, boldFont: boldFont),
                          _pdfDivider(),
                          _pdfRow('Session Hours', booking['hours'] ?? '-',
                              font: font, boldFont: boldFont),
                          _pdfDivider(),
                          _pdfRow(
                              'Total Price',
                              '\$${booking['price'] ?? '0'}',
                              font: font,
                              boldFont: boldFont,
                              valueColor: PdfColor.fromHex('22C55E')),
                        ],
                      ),

                      pw.SizedBox(height: 20),

                      // ── Client info card ─────────────────────────────
                      _pdfCard(
                        boldFont: boldFont,
                        font: font,
                        title: 'CLIENT INFORMATION',
                        primaryColor: primaryColor,
                        children: [
                          _pdfRow('Name', booking['clientName'] ?? '-',
                              font: font, boldFont: boldFont),
                          _pdfDivider(),
                          _pdfRow('Email', booking['clientEmail'] ?? '-',
                              font: font, boldFont: boldFont),
                          if (booking['clientPhone']?.isNotEmpty == true) ...[
                            _pdfDivider(),
                            _pdfRow('Phone', booking['clientPhone']!,
                                font: font, boldFont: boldFont),
                          ],
                        ],
                      ),

                      // ── Equipment ────────────────────────────────────
                      if (booking['equipment']?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 20),
                        _pdfCard(
                          boldFont: boldFont,
                          font: font,
                          title: 'EXTRA EQUIPMENT',
                          primaryColor: primaryColor,
                          children: [
                            pw.Text(booking['equipment'] ?? '',
                                style: pw.TextStyle(
                                    font: font,
                                    fontSize: 12,
                                    color: darkText)),
                          ],
                        ),
                      ],

                      pw.Spacer(),

                      // ── Footer ───────────────────────────────────────
                      pw.Divider(color: PdfColor.fromHex('E8E8F0')),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Generated by GENZ Studios App',
                              style: pw.TextStyle(
                                  font: font,
                                  fontSize: 9,
                                  color: subText)),
                          pw.Text(
                              DateTime.now()
                                  .toString()
                                  .substring(0, 16),
                              style: pw.TextStyle(
                                  font: font,
                                  fontSize: 9,
                                  color: subText)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfCard({
    required pw.Font boldFont,
    required pw.Font font,
    required String title,
    required PdfColor primaryColor,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('E8E8F0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding:
            const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.vertical(
                  top: pw.Radius.circular(10)),
            ),
            child: pw.Text(title,
                style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: PdfColors.white,
                    letterSpacing: 0.8)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(children: children),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfRow(
      String label,
      String value, {
        required pw.Font font,
        required pw.Font boldFont,
        PdfColor? valueColor,
      }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: const PdfColor.fromInt(0xFF6B6B8A))),
        pw.Text(value,
            style: pw.TextStyle(
                font: boldFont,
                fontSize: 12,
                color: valueColor ?? const PdfColor.fromInt(0xFF0D0D1A))),
      ],
    );
  }

  pw.Widget _pdfDivider() => pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 8),
    height: 0.5,
    color: PdfColor.fromHex('E8E8F0'),
  );

  // ── Print / Share ────────────────────────────────────────────────────────────
  Future<void> _printBooking() async {
    setState(() => _isPrinting = true);
    try {
      final pdfBytes = await _buildPdf();
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _shareAsPdf() async {
    setState(() => _isPrinting = true);
    try {
      final pdfBytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
        'booking_${booking['studio']?.replaceAll(' ', '_')}_${booking['date']?.replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showPdfOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Booking Receipt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  )),
              const SizedBox(height: 6),
              Text('Choose an option below',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkSubText
                        : AppColors.lightSubText,
                  )),
              const SizedBox(height: 24),

              // Print option
              _bottomSheetOption(
                icon: Icons.print_rounded,
                iconColor: AppColors.primary,
                title: 'Print Booking',
                subtitle: 'Send to printer or save as PDF',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _printBooking();
                },
              ),
              const SizedBox(height: 12),

              // Share / Download option
              _bottomSheetOption(
                icon: Icons.share_rounded,
                iconColor: AppColors.success,
                title: 'Share as PDF',
                subtitle: 'Share via WhatsApp, Email, etc.',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _shareAsPdf();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSheetOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color:
                        isDark ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: isDark
                            ? AppColors.darkSubText
                            : AppColors.lightSubText,
                        fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subText = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final loc = AppLocalizations.of(context);

    // ── Responsive ─────────────────────────────────────────────────────────
    final isTablet = size.width >= 600;
    final hPad = isTablet ? size.width * 0.1 : 20.0;
    final maxWidth = isTablet ? 720.0 : double.infinity;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(loc.translate('booking_request'),
            style:
            TextStyle(color: textColor, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          // Print / PDF button
          _isPrinting
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2)),
          )
              : IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.primary),
            tooltip: 'Print / Save PDF',
            onPressed: _showPdfOptions,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary),
            tooltip: loc.translate('support_chat'),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(targetUser: {
                      'name': booking['clientName'] ?? '',
                      'email': booking['clientEmail'] ?? '',
                    }))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            tooltip: loc.translate('delete'),
            onPressed: () async {
              await widget.onDelete(widget.index);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Banner ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _statusColor.withOpacity(0.15),
                        _statusColor.withOpacity(0.05)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:
                      Icon(_statusIcon, color: _statusColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking['status'] ?? '',
                              style: TextStyle(
                                  color: _statusColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                          Text('\$${booking['price'] ?? '0'}',
                              style: TextStyle(
                                  color: _statusColor.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    // Quick PDF button in banner
                    OutlinedButton.icon(
                      onPressed: _isPrinting ? null : _showPdfOptions,
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('PDF',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _statusColor,
                        side: BorderSide(
                            color: _statusColor.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Tablet: 2-column layout ────────────────────────────────
                if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(children: [
                          _sectionHeader(
                              Icons.person_rounded, 'Client Info', textColor),
                          const SizedBox(height: 12),
                          _infoCard(cardColor, borderColor, [
                            _infoRow(Icons.badge_rounded, 'Name',
                                booking['clientName'] ?? '-',
                                textColor, subText),
                            _divider(borderColor),
                            _infoRow(Icons.email_rounded, 'Email',
                                booking['clientEmail'] ?? '-',
                                textColor, subText),
                            _divider(borderColor),
                            _infoRow(
                                Icons.phone_rounded,
                                'Phone',
                                booking['clientPhone']?.isNotEmpty == true
                                    ? booking['clientPhone']!
                                    : '-',
                                textColor,
                                subText),
                          ]),
                        ]),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(children: [
                          _sectionHeader(Icons.event_rounded,
                              'Booking Details', textColor),
                          const SizedBox(height: 12),
                          _infoCard(cardColor, borderColor, [
                            _infoRow(
                                Icons.camera_indoor_rounded,
                                'Studio',
                                booking['studio'] ?? '-',
                                AppColors.primary,
                                subText,
                                valueColor: AppColors.primary),
                            _divider(borderColor),
                            _infoRow(Icons.calendar_today_rounded, 'Date',
                                booking['date'] ?? '-', textColor, subText),
                            _divider(borderColor),
                            _infoRow(Icons.access_time_rounded, 'Hours',
                                booking['hours'] ?? '-', textColor, subText),
                            _divider(borderColor),
                            _infoRow(
                                Icons.attach_money_rounded,
                                'Total Price',
                                '\$${booking['price'] ?? '0'}',
                                AppColors.success,
                                subText,
                                valueColor: AppColors.success),
                          ]),
                        ]),
                      ),
                    ],
                  )

                // ── Phone: single column ────────────────────────────────────
                else ...[
                  _sectionHeader(
                      Icons.person_rounded, 'Client Info', textColor),
                  const SizedBox(height: 12),
                  _infoCard(cardColor, borderColor, [
                    _infoRow(Icons.badge_rounded, 'Name',
                        booking['clientName'] ?? '-', textColor, subText),
                    _divider(borderColor),
                    _infoRow(Icons.email_rounded, 'Email',
                        booking['clientEmail'] ?? '-', textColor, subText),
                    _divider(borderColor),
                    _infoRow(
                        Icons.phone_rounded,
                        'Phone',
                        booking['clientPhone']?.isNotEmpty == true
                            ? booking['clientPhone']!
                            : '-',
                        textColor,
                        subText),
                  ]),
                  const SizedBox(height: 20),
                  _sectionHeader(
                      Icons.event_rounded, 'Booking Details', textColor),
                  const SizedBox(height: 12),
                  _infoCard(cardColor, borderColor, [
                    _infoRow(
                        Icons.camera_indoor_rounded,
                        'Studio',
                        booking['studio'] ?? '-',
                        AppColors.primary,
                        subText,
                        valueColor: AppColors.primary),
                    _divider(borderColor),
                    _infoRow(Icons.calendar_today_rounded, 'Date',
                        booking['date'] ?? '-', textColor, subText),
                    _divider(borderColor),
                    _infoRow(Icons.access_time_rounded, 'Hours',
                        booking['hours'] ?? '-', textColor, subText),
                    _divider(borderColor),
                    _infoRow(
                        Icons.attach_money_rounded,
                        'Total Price',
                        '\$${booking['price'] ?? '0'}',
                        AppColors.success,
                        subText,
                        valueColor: AppColors.success),
                  ]),
                ],

                // ── Equipment ────────────────────────────────────────────────
                if (booking['equipment']?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  _sectionHeader(
                      Icons.camera_rounded, 'Extra Equipment', textColor),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (booking['equipment'] ?? '')
                          .split(', ')
                          .where((e) => e.isNotEmpty)
                          .map((e) => Chip(
                        label: Text(e,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor:
                        AppColors.primary.withOpacity(0.1),
                        side: BorderSide(
                            color:
                            AppColors.primary.withOpacity(0.3)),
                        labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ))
                          .toList(),
                    ),
                  ),
                ],

                // ── Actions (Employee Only) ──────────────────────────────────
                if (booking['status'] == 'Pending' &&
                    currentUser['type'] == 'employee') ...[
                  const SizedBox(height: 20),
                  _sectionHeader(
                      Icons.rule_rounded, 'Actions', textColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleStatus('Approved'),
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white),
                        label: Text(loc.translate('approved'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleStatus('Rejected'),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                        label: Text(loc.translate('rejected'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ]),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color textColor) =>
      Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor)),
      ]);

  Widget _infoCard(Color cardColor, Color borderColor,
      List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(children: children),
      );

  Widget _divider(Color borderColor) =>
      Divider(height: 1, color: borderColor, indent: 16, endIndent: 16);

  Widget _infoRow(IconData icon, String label, String value,
      Color iconColor, Color subColor,
      {Color? valueColor}) =>
      Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: subColor, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? iconColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}