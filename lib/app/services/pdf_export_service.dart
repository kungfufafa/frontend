import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:frontend/app/services/chart_generator_service.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  static const String _appName = 'HelpDesk Dashboard';
  static const String _companyName = 'MEGAHUB';

  /// Generate dashboard report PDF for Direksi role
  static Future<Uint8List> generateDireksiDashboardReport({
    required Map<String, dynamic> dashboardData,
    required String userName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formatter = DateFormat('dd MMMM yyyy HH:mm');

    // Load font for better text rendering
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Extract data from dashboard observables
    final executiveSummary =
        dashboardData['executive_summary'] as Map<String, dynamic>? ?? {};
    final performanceMetrics =
        dashboardData['performance_metrics'] as Map<String, dynamic>? ?? {};
    final priorityDistribution =
        dashboardData['priority_distribution'] as List? ?? [];
    final unitPerformance = dashboardData['unit_performance'] as List? ?? [];
    final metadata =
        dashboardData['export_metadata'] as Map<String, dynamic>? ?? {};

    // Generate charts
    final totalTickets = (executiveSummary['total_tikets'] ?? 0) as int;
    final resolvedTickets = (executiveSummary['resolved_tikets'] ?? 0) as int;
    final openTickets = totalTickets - resolvedTickets;

    final ticketStatusChart =
        await ChartGeneratorService.generateTicketStatusChart(
          totalTickets: totalTickets,
          openTickets: openTickets > 0 ? openTickets : 0,
          closedTickets: resolvedTickets,
          width: 250,
          height: 250,
        );

    final priorityChart =
        await ChartGeneratorService.generatePriorityDistributionChart(
          priorityData: priorityDistribution.cast<Map<String, dynamic>>(),
          width: 250,
          height: 250,
        );

    final unitChart = await ChartGeneratorService.generateUnitPerformanceChart(
      unitData: unitPerformance.cast<Map<String, dynamic>>(),
      width: 350,
      height: 250,
    );

    final performanceChart =
        await ChartGeneratorService.generatePerformanceMetricsChart(
          metricsData: performanceMetrics,
          width: 350,
          height: 250,
        );

    // Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
                colors: [
                  PdfColor.fromHex('#1976D2'),
                  PdfColor.fromHex('#1565C0'),
                ],
              ),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    _appName,
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Laporan Dashboard Eksekutif',
                    style: pw.TextStyle(fontSize: 20, color: PdfColors.white),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Dibuat untuk: $userName',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Tanggal: ${formatter.format(now)}',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          _companyName,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Executive Summary Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Executive Summary'),
              pw.SizedBox(height: 20),

              // Key Metrics Grid
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricCard(
                    'Total Tickets',
                    '${executiveSummary['total_tikets'] ?? 0}',
                    PdfColor.fromHex('#FF9800'),
                  ),
                  _buildMetricCard(
                    'Resolved Tickets',
                    '${executiveSummary['resolved_tikets'] ?? 0}',
                    PdfColor.fromHex('#4CAF50'),
                  ),
                  _buildMetricCard(
                    'Completion Rate',
                    '${((executiveSummary['resolved_tikets'] ?? 0) / (executiveSummary['total_tikets'] ?? 1) * 100).toStringAsFixed(1)}%',
                    PdfColor.fromHex('#2196F3'),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Performance Highlights
              _buildSectionTitle('Performance Highlights'),
              pw.SizedBox(height: 15),

              if (performanceMetrics.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (performanceMetrics['completion_rate'] != null)
                        pw.Text(
                          '• Completion Rate: ${performanceMetrics['completion_rate']}%',
                        ),
                      if (performanceMetrics['avg_resolution_time'] != null)
                        pw.Text(
                          '• Average Resolution Time: ${performanceMetrics['avg_resolution_time']} hours',
                        ),
                      if (performanceMetrics['customer_satisfaction'] != null)
                        pw.Text(
                          '• Customer Satisfaction: ${performanceMetrics['customer_satisfaction']}%',
                        ),
                      if (performanceMetrics['total_units'] != null)
                        pw.Text(
                          '• Active Units: ${performanceMetrics['total_units']}',
                        ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 30),

              // Critical Insights
              _buildSectionTitle('Key Insights'),
              pw.SizedBox(height: 15),

              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F5F5'),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '• Dashboard data reflects current operational status',
                    ),
                    pw.Text(
                      '• Performance metrics calculated based on resolved tickets',
                    ),
                    pw.Text(
                      '• Unit performance ranking shows top-performing departments',
                    ),
                    pw.Text(
                      '• Priority distribution indicates workload balance',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Statistics and Charts Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Statistical Analysis'),
              pw.SizedBox(height: 20),

              // Ticket Status Chart
              _buildSectionTitle('Ticket Status Distribution'),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Image(pw.MemoryImage(ticketStatusChart)),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Tickets: ${executiveSummary['total_tikets'] ?? 0}',
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Active: ${(executiveSummary['total_tikets'] ?? 0) - (executiveSummary['resolved_tikets'] ?? 0)}',
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Resolved: ${executiveSummary['resolved_tikets'] ?? 0}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Priority Distribution Chart
              _buildSectionTitle('Priority Distribution'),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Image(pw.MemoryImage(priorityChart)),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: priorityDistribution.map((item) {
                        final priority = item['prioritas'] ?? 'Unknown';
                        final count = item['count'] ?? 0;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 5),
                          child: pw.Text('$priority: $count'),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Unit Performance Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Unit Performance Analysis'),
              pw.SizedBox(height: 20),

              // Unit Performance Chart
              _buildSectionTitle('Top Performing Units'),
              pw.SizedBox(height: 15),
              pw.Center(child: pw.Image(pw.MemoryImage(unitChart))),

              pw.SizedBox(height: 30),

              // Unit Performance Table
              if (unitPerformance.isNotEmpty) ...[
                _buildSectionTitle('Detailed Unit Performance'),
                pw.SizedBox(height: 15),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F5F5F5'),
                      ),
                      children: [
                        _buildTableCell('Unit Name', isHeader: true),
                        _buildTableCell('Resolved Tickets', isHeader: true),
                        _buildTableCell('Performance', isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...unitPerformance.take(10).map((unit) {
                      final unitName =
                          unit['nama_unit'] ?? unit['unit_name'] ?? 'Unknown';
                      final resolvedCount =
                          unit['resolved_tikets'] ?? unit['count'] ?? 0;
                      final performance = _calculatePerformanceLevel(
                        resolvedCount,
                      );

                      return pw.TableRow(
                        children: [
                          _buildTableCell(unitName.toString()),
                          _buildTableCell(resolvedCount.toString()),
                          _buildTableCell(performance),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],

              pw.SizedBox(height: 30),

              // Performance Metrics Chart
              _buildSectionTitle('Performance Metrics Trend'),
              pw.SizedBox(height: 15),
              pw.Center(child: pw.Image(pw.MemoryImage(performanceChart))),
            ],
          );
        },
      ),
    );

    // Report Footer Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Report Information'),
              pw.SizedBox(height: 20),

              _buildSectionTitle('Data Sources'),
              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '• Data Source: ${metadata['data_source'] ?? 'Current Dashboard Session'}',
                    ),
                    pw.Text(
                      '• Generation Time: ${metadata['generated_at'] ?? now.toIso8601String()}',
                    ),
                    pw.Text(
                      '• User Role: ${metadata['user_role'] ?? 'Direksi'}',
                    ),
                    pw.Text('• Report Type: Executive Dashboard Export'),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              _buildSectionTitle('Methodology Notes'),
              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8F9FA'),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• Charts generated from current dashboard data'),
                    pw.Text('• Performance metrics calculated in real-time'),
                    pw.Text('• Unit rankings based on resolved ticket counts'),
                    pw.Text('• Data reflects the state at the time of export'),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  children: [
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Generated by $_appName',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      _companyName,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build page header
  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromHex('#1976D2'), width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#1976D2'),
        ),
      ),
    );
  }

  /// Build section title
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#424242'),
      ),
    );
  }

  /// Build metric card
  static pw.Widget _buildMetricCard(
    String title,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Calculate performance level based on resolved tickets count
  static String _calculatePerformanceLevel(int resolvedCount) {
    if (resolvedCount >= 50) return 'Excellent';
    if (resolvedCount >= 30) return 'Good';
    if (resolvedCount >= 15) return 'Average';
    if (resolvedCount >= 5) return 'Below Average';
    return 'Poor';
  }

  /// Download PDF file in web browser
  static Future<void> downloadPdf(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }
}
