// lib/screens/ReportsScreen.dart
import 'package:flutter/material.dart';
import 'package:genz/data/data.dart';
import 'package:genz/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // which years to show — default: current year only
  late List<int> _visibleYears;
  // expanded state
  final Set<int> _expandedYears  = {};
  final Set<String> _expandedMonths = {}; // "2026-1"

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleYears = [now.year];
    _expandedYears.add(now.year);
  }

  // ── data helpers ───────────────────────────────────────────────────────────

  List<Map<String, String>> _bookingsForMonth(int year, int month) {
    return bookingRequests.where((b) {
      final dt = DateTime.tryParse(b['fullStartDateTime'] ?? b['date'] ?? '');
      return dt != null && dt.year == year && dt.month == month;
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['fullStartDateTime'] ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['fullStartDateTime'] ?? '') ?? DateTime(0);
        return da.compareTo(db);
      });
  }

  List<Map<String, String>> _bookingsForDay(int year, int month, int day) {
    return bookingRequests.where((b) {
      final dt = DateTime.tryParse(b['fullStartDateTime'] ?? b['date'] ?? '');
      return dt != null && dt.year == year && dt.month == month && dt.day == day;
    }).toList();
  }

  // returns unique days that have bookings in this month
  List<int> _daysWithBookings(int year, int month) {
    final days = <int>{};
    for (final b in _bookingsForMonth(year, month)) {
      final dt = DateTime.tryParse(b['fullStartDateTime'] ?? '');
      if (dt != null) days.add(dt.day);
    }
    return days.toList()..sort();
  }

  _MonthStats _statsForYear(int year) {
    final now = DateTime.now();
    int total = 0, approved = 0, pending = 0, rejected = 0, done = 0;
    double revenue = 0, hours = 0;
    for (int m = 1; m <= 12; m++) {
      if (year == now.year && m > now.month) break;
      final s = _statsForMonth(year, m);
      total    += s.total;
      approved += s.approved;
      pending  += s.pending;
      rejected += s.rejected;
      done     += s.done;
      revenue  += s.revenue;
      hours    += s.hours;
    }
    return _MonthStats(total: total, approved: approved, pending: pending,
        rejected: rejected, done: done, revenue: revenue, hours: hours);
  }

  _MonthStats _statsForMonth(int year, int month) {
    final list = _bookingsForMonth(year, month);
    final approved = list.where((b) => b['status'] == 'Approved').toList();
    final pending  = list.where((b) => b['status'] == 'Pending').toList();
    final rejected = list.where((b) => b['status'] == 'Rejected').toList();
    final done     = list.where((b) => b['status'] == 'Done').toList();
    double revenue = 0;
    double hours   = 0;
    for (final b in [...approved, ...done]) {
      revenue += double.tryParse(
              b['price']?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0;
      final s = DateTime.tryParse(b['fullStartDateTime'] ?? '');
      final e = DateTime.tryParse(b['fullEndDateTime']   ?? '');
      if (s != null && e != null && e.isAfter(s)) {
        hours += e.difference(s).inMinutes / 60.0;
      }
    }
    return _MonthStats(
      total:    list.length,
      approved: approved.length,
      pending:  pending.length,
      rejected: rejected.length,
      done:     done.length,
      revenue:  revenue,
      hours:    hours,
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDark ? AppColors.darkBg      : AppColors.lightBg;
    final textColor  = isDark ? AppColors.darkText    : AppColors.lightText;
    final subText    = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor  = isDark ? AppColors.darkCard    : AppColors.lightSurface;
    final borderColor= isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final now        = DateTime.now();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Reports',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          // toggle multi-year
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _showYearPicker,
              icon: Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary, size: 18),
              label: Text(
                _visibleYears.length == 1
                    ? '${_visibleYears.first}'
                    : '${_visibleYears.first}–${_visibleYears.last}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: _visibleYears.map((year) => _buildYear(
          year, isDark, bg, textColor, subText, cardColor, borderColor, now,
        )).toList(),
      ),
    );
  }

  // ── Year block ─────────────────────────────────────────────────────────────
  Widget _buildYear(int year, bool isDark, Color bg, Color textColor,
      Color subText, Color cardColor, Color borderColor, DateTime now) {
    final isExpanded = _expandedYears.contains(year);
    final isCurrent  = year == now.year;
    final yearStats  = _statsForYear(year);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 12, offset: const Offset(0, 3),
        )],
      ),
      child: Column(children: [
        // year header
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() {
            if (isExpanded) _expandedYears.remove(year);
            else _expandedYears.add(year);
          }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('$year',
                      style: TextStyle(color: textColor,
                          fontSize: 20, fontWeight: FontWeight.w900)),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Current',
                          style: TextStyle(color: AppColors.success,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text('${yearStats.total} bookings · \$${yearStats.revenue.toStringAsFixed(0)} revenue · ${yearStats.hours.toStringAsFixed(1)}h',
                    style: TextStyle(color: subText, fontSize: 12)),
              ])),
              GestureDetector(
                onTap: () => _generateYearPdf(year),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      color: AppColors.primary, size: 18),
                ),
              ),
              Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: subText),
            ]),
          ),
        ),

        // months
        if (isExpanded) ...[
          Divider(height: 1, color: borderColor),
          ...List.generate(12, (i) {
            final month = i + 1;
            if (isCurrent && month > now.month) return const SizedBox.shrink();
            return _buildMonth(year, month, isDark, textColor, subText,
                cardColor, borderColor, now);
          }),
        ],
      ]),
    );
  }

  // ── Month block ────────────────────────────────────────────────────────────
  Widget _buildMonth(int year, int month, bool isDark, Color textColor,
      Color subText, Color cardColor, Color borderColor, DateTime now) {
    final key       = '$year-$month';
    final isExpanded = _expandedMonths.contains(key);
    final stats     = _statsForMonth(year, month);
    final hasData   = stats.total > 0;
    final isCurrent = year == now.year && month == now.month;

    return Column(children: [
      InkWell(
        onTap: () => setState(() {
          if (isExpanded) _expandedMonths.remove(key);
          else _expandedMonths.add(key);
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            // month indicator
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: hasData ? AppColors.primary : borderColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Row(children: [
              Text(_monthNames[month - 1],
                  style: TextStyle(
                    color: hasData ? textColor : subText,
                    fontSize: 14,
                    fontWeight: hasData ? FontWeight.w700 : FontWeight.w400,
                  )),
              if (isCurrent) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Now',
                      style: TextStyle(color: AppColors.primary,
                          fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ])),
            // stats chips
            if (hasData) ...[
              _chip('${stats.total}', AppColors.primary),
              const SizedBox(width: 4),
              _chip('\$${stats.revenue.toStringAsFixed(0)}', AppColors.success),
              const SizedBox(width: 8),
              // print button
              GestureDetector(
                onTap: () => _generatePdf(year, month),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      color: AppColors.primary, size: 16),
                ),
              ),
            ] else
              Text('No bookings',
                  style: TextStyle(color: subText, fontSize: 11)),
            const SizedBox(width: 8),
            Icon(isExpanded ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
                color: subText, size: 18),
          ]),
        ),
      ),

      // days
      if (isExpanded && hasData)
        _buildMonthDetail(year, month, isDark, textColor, subText,
            cardColor, borderColor, stats),

      Divider(height: 1, color: borderColor, indent: 38),
    ]);
  }

  // ── Month detail: stats summary + days ────────────────────────────────────
  Widget _buildMonthDetail(int year, int month, bool isDark, Color textColor,
      Color subText, Color cardColor, Color borderColor, _MonthStats stats) {
    final days = _daysWithBookings(year, month);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: [
        // stats summary bar
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              _statBox('Total',    '${stats.total}',    AppColors.primary, isDark),
              const SizedBox(width: 6),
              _statBox('Approved', '${stats.approved}', AppColors.success, isDark),
              const SizedBox(width: 6),
              _statBox('Pending',  '${stats.pending}',  AppColors.warning, isDark),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _statBox('Rejected', '${stats.rejected}', AppColors.error, isDark),
              const SizedBox(width: 6),
              _statBox('Done', '${stats.done}', const Color(0xFF6366F1), isDark),
              const SizedBox(width: 6),
              _statBox('Revenue', '\$${stats.revenue.toStringAsFixed(0)}',
                  const Color(0xFF10B981), isDark),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _statBox('Hours', '${stats.hours.toStringAsFixed(1)}h',
                  const Color(0xFF0EA5E9), isDark),
              const Expanded(flex: 2, child: SizedBox()),
            ]),
          ]),
        ),

        Divider(height: 1, color: borderColor),

        // days list
        ...days.map((day) => _buildDay(year, month, day, isDark, textColor, subText, borderColor)),
      ]),
    );
  }

  // ── Day row ────────────────────────────────────────────────────────────────
  Widget _buildDay(int year, int month, int day, bool isDark, Color textColor,
      Color subText, Color borderColor) {
    final bookings = _bookingsForDay(year, month, day);
    final weekday  = DateFormat('EEE').format(DateTime(year, month, day));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$day',
                    style: const TextStyle(color: AppColors.primary,
                        fontSize: 14, fontWeight: FontWeight.w900)),
                Text(weekday,
                    style: TextStyle(color: subText, fontSize: 8)),
              ]),
            ),
            const SizedBox(width: 10),
            Text('${bookings.length} booking${bookings.length > 1 ? 's' : ''}',
                style: TextStyle(color: textColor,
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ...bookings.map((b) => _buildBookingRow(b, isDark, textColor, subText)),
        ]),
      ),
      Divider(height: 1, color: borderColor, indent: 14, endIndent: 14),
    ]);
  }

  Widget _buildBookingRow(Map<String, String> b, bool isDark,
      Color textColor, Color subText) {
    final status = b['status'] ?? 'Pending';
    Color statusColor;
    switch (status) {
      case 'Approved': statusColor = AppColors.success; break;
      case 'Rejected': statusColor = AppColors.error;   break;
      default:         statusColor = AppColors.warning;
    }

    String timeStr = '';
    final s = DateTime.tryParse(b['fullStartDateTime'] ?? '');
    final e = DateTime.tryParse(b['fullEndDateTime']   ?? '');
    if (s != null && e != null) {
      final fmt = DateFormat('HH:mm');
      final hrs = e.difference(s).inMinutes / 60.0;
      timeStr = '${fmt.format(s)} – ${fmt.format(e)} (${hrs.toStringAsFixed(1)}h)';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 46, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b['clientName'] ?? b['clientEmail'] ?? '',
                style: TextStyle(color: textColor,
                    fontSize: 12, fontWeight: FontWeight.w700)),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(timeStr, style: TextStyle(color: subText, fontSize: 11)),
            ],
            Text(b['studio'] ?? '',
                style: TextStyle(color: subText, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status,
                  style: TextStyle(color: statusColor,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Text('\$${b['price'] ?? '0'}',
                style: const TextStyle(color: AppColors.success,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  // ── small helpers ──────────────────────────────────────────────────────────
  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _statBox(String label, String value, Color color, bool isDark) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color,
            fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
            color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
            fontSize: 9)),
      ]),
    ),
  );

  // ── year picker ────────────────────────────────────────────────────────────
  Future<void> _showYearPicker() async {
    final now     = DateTime.now();
    final minYear = now.year - 5;
    final maxYear = now.year;

    Set<int> tempSelected = Set.from(_visibleYears);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Select Year(s)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Tap to select one or more years',
              style: TextStyle(fontSize: 12, color: AppColors.darkSubText)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: List.generate(maxYear - minYear + 1, (i) {
              final y = minYear + i;
              final sel = tempSelected.contains(y);
              return GestureDetector(
                onTap: () => setLocal(() {
                  if (sel) { if (tempSelected.length > 1) tempSelected.remove(y); }
                  else tempSelected.add(y);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: null, height: 48,
                  constraints: const BoxConstraints(minWidth: 72, maxWidth: 100),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text('$y',
                      style: TextStyle(
                        color: sel ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w700, fontSize: 15,
                      )),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final sorted = tempSelected.toList()..sort();
                setState(() {
                  _visibleYears = sorted;
                  for (final y in sorted) _expandedYears.add(y);
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Apply',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      )),
    );
  }

  // ── PDF generation ─────────────────────────────────────────────────────────
  // ── Yearly PDF ─────────────────────────────────────────────────────────────
  Future<void> _generateYearPdf(int year) async {
    final stats    = _statsForYear(year);
    final now      = DateTime.now();
    final pdf      = pw.Document();

    const primary = PdfColor.fromInt(0xFF6C63FF);
    const success = PdfColor.fromInt(0xFF22C55E);
    const warning = PdfColor.fromInt(0xFFF59E0B);
    const error   = PdfColor.fromInt(0xFFEF4444);
    const purple  = PdfColor.fromInt(0xFF6366F1);
    const teal    = PdfColor.fromInt(0xFF10B981);
    const sky     = PdfColor.fromInt(0xFF0EA5E9);
    const bgLight = PdfColor.fromInt(0xFFF8F9FF);
    const textDark= PdfColor.fromInt(0xFF1A1A2E);
    const subGrey = PdfColor.fromInt(0xFF64748B);
    const border  = PdfColor.fromInt(0xFFE2E8F0);

    // build per-month rows
    final monthRows = <pw.TableRow>[];
    // header
    monthRows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: bgLight),
      children: ['Month', 'Total', 'Approved', 'Pending', 'Rejected', 'Done', 'Revenue', 'Hours']
          .map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(7),
            child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
          )).toList(),
    ));
    for (int m = 1; m <= 12; m++) {
      if (year == now.year && m > now.month) break;
      final ms = _statsForMonth(year, m);
      final isEven = m.isEven;
      monthRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: isEven ? bgLight : PdfColors.white),
        children: [
          _monthNames[m - 1],
          '${ms.total}',
          '${ms.approved}',
          '${ms.pending}',
          '${ms.rejected}',
          '${ms.done}',
          '\$${ms.revenue.toStringAsFixed(0)}',
          '${ms.hours.toStringAsFixed(1)}h',
        ].map((v) => pw.Padding(
          padding: const pw.EdgeInsets.all(7),
          child: pw.Text(v, style: const pw.TextStyle(fontSize: 9, color: textDark)),
        )).toList(),
      ));
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // header
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: pw.BorderRadius.circular(16),
          ),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Annual Report',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Year $year',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 16)),
              pw.SizedBox(height: 4),
              pw.Text('Generated ${DateFormat('dd MMM yyyy – HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            ]),
            pw.Container(
              width: 64, height: 64,
              decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(14)),
              alignment: pw.Alignment.center,
              child: pw.Text('GZ', style: pw.TextStyle(color: primary, fontSize: 26, fontWeight: pw.FontWeight.bold)),
            ),
          ]),
        ),
        pw.SizedBox(height: 20),

        // KPI row 1
        pw.Row(children: [
          _pdfKpi('Total Bookings', '${stats.total}',    primary),
          pw.SizedBox(width: 8),
          _pdfKpi('Approved',       '${stats.approved}', success),
          pw.SizedBox(width: 8),
          _pdfKpi('Pending',        '${stats.pending}',  warning),
          pw.SizedBox(width: 8),
          _pdfKpi('Rejected',       '${stats.rejected}', error),
        ]),
        pw.SizedBox(height: 8),
        // KPI row 2
        pw.Row(children: [
          _pdfKpi('Done',    '${stats.done}',                          purple),
          pw.SizedBox(width: 8),
          _pdfKpi('Revenue', '\$${stats.revenue.toStringAsFixed(2)}',  teal),
          pw.SizedBox(width: 8),
          _pdfKpi('Hours',   '${stats.hours.toStringAsFixed(1)}h',     sky),
          pw.SizedBox(width: 8),
          _pdfKpi('Avg/Month', '\$${(stats.revenue / 12).toStringAsFixed(0)}', primary),
        ]),
        pw.SizedBox(height: 24),

        // monthly breakdown table
        pw.Text('Monthly Breakdown',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: textDark)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1),
            6: const pw.FlexColumnWidth(1.5),
            7: const pw.FlexColumnWidth(1.2),
          },
          children: monthRows,
        ),
        pw.SizedBox(height: 24),

        // per-month booking details
        pw.Text('All Booking Details',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: textDark)),
        pw.SizedBox(height: 12),
        ...List.generate(12, (i) {
          final m = i + 1;
          if (year == now.year && m > now.month) return pw.SizedBox();
          final bookings = _bookingsForMonth(year, m);
          if (bookings.isEmpty) return pw.SizedBox();
          final mn = _monthNames[m - 1];
          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: pw.BoxDecoration(
                color: primary.shade(0.1),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(children: [
                pw.Text('$mn $year',
                    style: pw.TextStyle(color: primary, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Spacer(),
                pw.Text('${bookings.length} booking${bookings.length > 1 ? 's' : ''}',
                    style: const pw.TextStyle(color: subGrey, fontSize: 10)),
              ]),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: bgLight),
                  children: ['Client', 'Studio', 'Date & Time', 'Status', 'Price']
                      .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                      )).toList(),
                ),
                ...bookings.map((b) {
                  final status = b['status'] ?? '';
                  PdfColor sc;
                  switch (status) {
                    case 'Approved': sc = success; break;
                    case 'Rejected': sc = error;   break;
                    case 'Done':     sc = purple;  break;
                    default:         sc = warning;
                  }
                  final s = DateTime.tryParse(b['fullStartDateTime'] ?? '');
                  final e = DateTime.tryParse(b['fullEndDateTime']   ?? '');
                  String timeStr = '';
                  if (s != null && e != null) {
                    final hrs = e.difference(s).inMinutes / 60.0;
                    timeStr = '${DateFormat('dd MMM').format(s)}  ${DateFormat('HH:mm').format(s)}–${DateFormat('HH:mm').format(e)} (${hrs.toStringAsFixed(1)}h)';
                  }
                  return pw.TableRow(children: [
                    _pdfCell(b['clientName'] ?? b['clientEmail'] ?? '', textDark),
                    _pdfCell(b['studio'] ?? '', subGrey),
                    _pdfCell(timeStr, subGrey),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: sc.shade(0.15),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(status, style: pw.TextStyle(color: sc, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                    _pdfCell('\$${b['price'] ?? '0'}', success),
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 14),
          ]);
        }),

        // footer
        pw.Divider(color: border),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('GENZ Studios · Annual Report $year',
              style: const pw.TextStyle(color: subGrey, fontSize: 9)),
          pw.Text('Total Revenue: \$${stats.revenue.toStringAsFixed(2)}  ·  Total Hours: ${stats.hours.toStringAsFixed(1)}h',
              style: pw.TextStyle(color: primary, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ]),
      ],
    ));

    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'GENZ_Annual_$year.pdf',
    );
  }

  Future<void> _generatePdf(int year, int month) async {
    final stats    = _statsForMonth(year, month);
    final days     = _daysWithBookings(year, month);
    final monthName = _monthNames[month - 1];

    final pdf = pw.Document();

    // colours
    const primary = PdfColor.fromInt(0xFF6C63FF);
    const success = PdfColor.fromInt(0xFF22C55E);
    const warning = PdfColor.fromInt(0xFFF59E0B);
    const error   = PdfColor.fromInt(0xFFEF4444);
    const purple  = PdfColor.fromInt(0xFF6366F1);
    const teal    = PdfColor.fromInt(0xFF10B981);
    const bgLight = PdfColor.fromInt(0xFFF8F9FF);
    const textDark= PdfColor.fromInt(0xFF1A1A2E);
    const subGrey = PdfColor.fromInt(0xFF64748B);
    const border  = PdfColor.fromInt(0xFFE2E8F0);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // ── header ────────────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: pw.BorderRadius.circular(16),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Monthly Report',
                    style: pw.TextStyle(color: PdfColors.white,
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('$monthName $year',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 14)),
                pw.SizedBox(height: 4),
                pw.Text('Generated ${DateFormat('dd MMM yyyy – HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              ]),
              pw.Container(
                width: 60, height: 60,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text('GZ',
                    style: pw.TextStyle(color: primary,
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // ── KPI cards ─────────────────────────────────────────────────────
        pw.Row(children: [
          _pdfKpi('Total',    '${stats.total}',    primary),
          pw.SizedBox(width: 8),
          _pdfKpi('Approved', '${stats.approved}', success),
          pw.SizedBox(width: 8),
          _pdfKpi('Pending',  '${stats.pending}',  warning),
          pw.SizedBox(width: 8),
          _pdfKpi('Rejected', '${stats.rejected}', error),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _pdfKpi('Done',    '${stats.done}',                         purple),
          pw.SizedBox(width: 8),
          _pdfKpi('Revenue', '\$${stats.revenue.toStringAsFixed(2)}', teal),
          pw.SizedBox(width: 8),
          _pdfKpi('Hours',   '${stats.hours.toStringAsFixed(1)}h',    PdfColor.fromInt(0xFF0EA5E9)),
          pw.SizedBox(width: 8),
          _pdfKpi('Avg Price', stats.approved + stats.done == 0
              ? '\$0'
              : '\$${(stats.revenue / (stats.approved + stats.done)).toStringAsFixed(0)}',
              primary),
        ]),
        pw.SizedBox(height: 24),

        // ── bookings table per day ─────────────────────────────────────────
        if (days.isEmpty)
          pw.Center(
            child: pw.Text('No bookings this month',
                style: const pw.TextStyle(color: subGrey)),
          )
        else ...[
          pw.Text('Booking Details',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textDark)),
          pw.SizedBox(height: 12),
          ...days.expand((day) {
            final bookings = _bookingsForDay(year, month, day);
            final weekday  = DateFormat('EEEE').format(DateTime(year, month, day));
            final dayRevenue = bookings.fold<double>(0, (sum, b) =>
                sum + (double.tryParse(b['price']?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0));
            return [
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: primary.shade(0.1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(children: [
                  pw.Text('$day $monthName  ($weekday)',
                      style: pw.TextStyle(color: primary, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Spacer(),
                  pw.Text('${bookings.length} booking${bookings.length > 1 ? 's' : ''}  ·  \$${dayRevenue.toStringAsFixed(0)}',
                      style: const pw.TextStyle(color: subGrey, fontSize: 10)),
                ]),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: border, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(1.8),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2.2),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.3),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: bgLight),
                    children: ['Client', 'Phone', 'Studio', 'Time', 'Status', 'Price']
                        .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(7),
                          child: pw.Text(h, style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                        )).toList(),
                  ),
                  ...bookings.map((b) {
                    final status = b['status'] ?? 'Pending';
                    PdfColor sc;
                    switch (status) {
                      case 'Approved': sc = success; break;
                      case 'Rejected': sc = error;   break;
                      case 'Done':     sc = purple;  break;
                      default:         sc = warning;
                    }
                    final s = DateTime.tryParse(b['fullStartDateTime'] ?? '');
                    final e = DateTime.tryParse(b['fullEndDateTime']   ?? '');
                    String timeStr = '';
                    if (s != null && e != null) {
                      final hrs = e.difference(s).inMinutes / 60.0;
                      timeStr = '${DateFormat('HH:mm').format(s)}–${DateFormat('HH:mm').format(e)}\n(${hrs.toStringAsFixed(1)}h)';
                    }
                    return pw.TableRow(children: [
                      _pdfCell(b['clientName'] ?? b['clientEmail'] ?? '', textDark),
                      _pdfCell(b['clientPhone'] ?? '—', subGrey),
                      _pdfCell(b['studio'] ?? '', subGrey),
                      _pdfCell(timeStr, subGrey),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: sc.shade(0.15),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(status, style: pw.TextStyle(
                              color: sc, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      _pdfCell('\$${b['price'] ?? '0'}', success),
                    ]);
                  }),
                ],
              ),
              pw.SizedBox(height: 14),
            ];
          }),
        ],

        // ── footer ────────────────────────────────────────────────────────
        pw.Divider(color: border),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('GENZ Studios · $monthName $year Report',
                style: const pw.TextStyle(color: subGrey, fontSize: 9)),
            pw.Text('Revenue: \$${stats.revenue.toStringAsFixed(2)}  ·  Hours: ${stats.hours.toStringAsFixed(1)}h',
                style: pw.TextStyle(color: primary, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    ));

    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'GENZ_${monthName}_$year.pdf',
    );
  }

  pw.Widget _pdfKpi(String label, String value, PdfColor color) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.08),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: color.shade(0.2), width: 0.5),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(value,
            style: pw.TextStyle(color: color, fontSize: 18,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style: const pw.TextStyle(color: PdfColor.fromInt(0xFF64748B), fontSize: 9)),
      ]),
    ),
  );

  pw.Widget _pdfCell(String text, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text,
        style: pw.TextStyle(color: color, fontSize: 10)),
  );
}

// ── stats model ────────────────────────────────────────────────────────────────
class _MonthStats {
  final int    total, approved, pending, rejected, done;
  final double revenue, hours;
  const _MonthStats({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.done,
    required this.revenue,
    required this.hours,
  });
}
