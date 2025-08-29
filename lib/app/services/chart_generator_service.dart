import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartGeneratorService {
  /// Generate pie chart image for ticket status distribution
  static Future<Uint8List> generateTicketStatusChart({
    required int totalTickets,
    required int openTickets,
    required int closedTickets,
    double width = 300,
    double height = 300,
  }) async {
    final activeTickets = openTickets;
    final resolvedTickets = closedTickets;
    
    if (totalTickets == 0) {
      return _generateEmptyChart(width, height, 'Tidak ada data tiket tersedia');
    }

    final chart = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox(
          width: width,
          height: height,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: activeTickets.toDouble(),
                  title: 'Aktif\n$activeTickets',
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  color: Colors.orange,
                  radius: 80,
                ),
                PieChartSectionData(
                  value: resolvedTickets.toDouble(),
                  title: 'Selesai\n$resolvedTickets',
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  color: Colors.green,
                  radius: 80,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return _widgetToImage(chart, width, height);
  }

  /// Generate donut chart for priority distribution
  static Future<Uint8List> generatePriorityDistributionChart({
    required List<Map<String, dynamic>> priorityData,
    double width = 300,
    double height = 300,
  }) async {
    if (priorityData.isEmpty) {
      return _generateEmptyChart(width, height, 'Tidak ada data prioritas tersedia');
    }

    final sections = priorityData.map((data) {
      final priority = data['prioritas']?.toString() ?? 'Unknown';
      final count = (data['count'] ?? 0) as int;
      
      Color color;
      String displayName;
      switch (priority.toLowerCase()) {
        case 'high':
        case 'tinggi':
          color = Colors.red;
          displayName = 'Tinggi';
          break;
        case 'medium':
        case 'sedang':
          color = Colors.orange;
          displayName = 'Sedang';
          break;
        case 'low':
        case 'rendah':
          color = Colors.green;
          displayName = 'Rendah';
          break;
        default:
          color = Colors.grey;
          displayName = priority;
      }

      return PieChartSectionData(
        value: count.toDouble(),
        title: '$displayName\n$count',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        color: color,
        radius: 80,
      );
    }).toList();

    final chart = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox(
          width: width,
          height: height,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: sections,
            ),
          ),
        ),
      ),
    );

    return _widgetToImage(chart, width, height);
  }

  /// Generate bar chart for unit performance
  static Future<Uint8List> generateUnitPerformanceChart({
    required List<Map<String, dynamic>> unitData,
    double width = 400,
    double height = 300,
  }) async {
    if (unitData.isEmpty) {
      return _generateEmptyChart(width, height, 'Tidak ada data performa unit tersedia');
    }

    // Sort by performance descending and take top 5
    final sortedData = List<Map<String, dynamic>>.from(unitData);
    sortedData.sort((a, b) {
      final aCount = (a['resolved_tikets'] ?? a['count'] ?? 0) as int;
      final bCount = (b['resolved_tikets'] ?? b['count'] ?? 0) as int;
      return bCount.compareTo(aCount);
    });
    
    final topUnits = sortedData.take(5).toList();

    final barGroups = topUnits.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final count = (data['resolved_tikets'] ?? data['count'] ?? 0) as int;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Colors.blue,
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    final chart = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: topUnits.isEmpty ? 10.0 : 
                       (((topUnits.first['resolved_tikets'] ?? topUnits.first['count'] ?? 0) as int) * 1.2),
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topUnits.length) {
                          final unitName = topUnits[index]['nama_unit']?.toString() ?? 
                                          topUnits[index]['unit_name']?.toString() ?? 
                                          'Unit ${index + 1}';
                          return Text(
                            unitName.length > 8 ? '${unitName.substring(0, 8)}...' : unitName,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
              ),
            ),
          ),
        ),
      ),
    );

    return _widgetToImage(chart, width, height);
  }

  /// Generate line chart for performance metrics trend
  static Future<Uint8List> generatePerformanceMetricsChart({
    required Map<String, dynamic> metricsData,
    double width = 400,
    double height = 300,
  }) async {
    if (metricsData.isEmpty) {
      return _generateEmptyChart(width, height, 'Tidak ada metrik performa tersedia');
    }

    // Extract sample data points for trend visualization
    final completionRate = (metricsData['completion_rate'] ?? 0.0) as double;
    final avgResolutionTime = (metricsData['avg_resolution_time'] ?? 0.0) as double;
    final customerSatisfaction = (metricsData['customer_satisfaction'] ?? 0.0) as double;

    final spots = [
      FlSpot(0, completionRate),
      FlSpot(1, avgResolutionTime * 10), // Scale for visibility
      FlSpot(2, customerSatisfaction),
    ];

    final chart = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Penyelesaian', style: TextStyle(fontSize: 10));
                          case 1:
                            return const Text('Waktu Rata-rata', style: TextStyle(fontSize: 10));
                          case 2:
                            return const Text('Kepuasan', style: TextStyle(fontSize: 10));
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: 2,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return _widgetToImage(chart, width, height);
  }

  /// Generate empty chart placeholder
  static Future<Uint8List> _generateEmptyChart(double width, double height, String message) async {
    final chart = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox(
          width: width,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return _widgetToImage(chart, width, height);
  }

  /// Convert widget to image bytes
  static Future<Uint8List> _widgetToImage(Widget widget, double width, double height) async {
    // Create a simple widget wrapper with MediaQuery
    final wrappedWidget = MediaQuery(
      data: const MediaQueryData(
        size: Size(800, 600),
        devicePixelRatio: 2.0,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    );
    
    final repaintBoundary = RenderRepaintBoundary();
    
    // Create a simple render setup
    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center, 
        child: repaintBoundary
      ),
      configuration: ViewConfiguration.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: wrappedWidget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}