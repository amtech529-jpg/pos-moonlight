import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/services/api_client.dart';
import '../../../src/config/api_config.dart';

class SalesOverviewChart extends StatefulWidget {
  final Map<String, dynamic> analytics;
  
  const SalesOverviewChart({
    super.key,
    required this.analytics,
  });

  @override
  State<SalesOverviewChart> createState() => _SalesOverviewChartState();
}

class _SalesOverviewChartState extends State<SalesOverviewChart> {
  List<dynamic> dailySalesData = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchLast7DaysSales();
  }

  Future<void> _fetchLast7DaysSales() async {
    try {
      final apiClient = ApiClient();
      
      // Calculate date range for last 7 days
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: 6));
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = now.toIso8601String().split('T')[0];
      
      // Fetch sales data from existing API
      final response = await apiClient.get(
        ApiConfig.sales,
        queryParameters: {
          'date_from': startDateStr,
          'date_to': endDateStr,
          'page_size': 100, // Get more records to ensure we have all
        }
      );

      if (response.statusCode == 200) {
        print('🔍 Sales API Response: ${response.data}');
        
        // Try different response structures
        List<dynamic> salesData = [];
        
        if (response.data['success'] == true) {
          salesData = response.data['data'] as List<dynamic>? ?? [];
        } else if (response.data['data'] != null) {
          salesData = response.data['data'] as List<dynamic>? ?? [];
        } else if (response.data['results'] != null) {
          salesData = response.data['results'] as List<dynamic>? ?? [];
        } else {
          salesData = response.data as List<dynamic>? ?? [];
        }
        
        print('🔍 Extracted sales data: $salesData');
        print('🔍 Sales data count: ${salesData.length}');
        
        // Group sales by date and count orders per day
        Map<String, int> dailyOrders = {};
        
        // Initialize all 7 days with 0 orders
        for (int i = 0; i < 7; i++) {
          final date = startDate.add(Duration(days: i));
          final dateStr = date.toIso8601String().split('T')[0];
          dailyOrders[dateStr] = 0;
        }
        
        // Count orders for each day
        for (var sale in salesData) {
          String? saleDate;
          if (sale['date_of_sale'] != null) {
            saleDate = sale['date_of_sale'].toString().split('T')[0];
          } else if (sale['date'] != null) {
            saleDate = sale['date'].toString().split('T')[0];
          }
          
          if (saleDate != null && dailyOrders.containsKey(saleDate)) {
            dailyOrders[saleDate] = (dailyOrders[saleDate] ?? 0) + 1;
          }
        }
        
        // Convert to chart data format with day names
        List<Map<String, dynamic>> chartData = [];
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        
        for (int i = 0; i < 7; i++) {
          final date = startDate.add(Duration(days: i));
          final dateStr = date.toIso8601String().split('T')[0];
          final dayName = dayNames[date.weekday - 1];
          
          chartData.add({
            'date': dateStr,
            'day_name': dayName,
            'order_count': dailyOrders[dateStr] ?? 0,
          });
        }
        
        setState(() {
          dailySalesData = chartData;
          isLoading = false;
        });
        
        print('🔍 Final chart data: $chartData');
      } else {
        print('🔍 Error fetching sales data: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('🔍 Error fetching sales data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: context.cardPadding),
          if (isLoading)
            _buildLoadingState()
          else if (dailySalesData.isEmpty)
            _buildEmptyState()
          else
            _buildChart(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Icon(
            Icons.trending_up_rounded,
            color: AppTheme.primaryMaroon,
            size: context.iconSize('medium'),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales Overview',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
              ),
              Text(
                'Last 7 days performance',
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.smallPadding,
            vertical: context.smallPadding / 2,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                color: Colors.green,
                size: context.iconSize('small'),
              ),
              SizedBox(width: 4),
              Text(
                '+12.5%',
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: context.chartHeight,
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryMaroon,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: context.chartHeight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No sales data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sales will appear here once transactions are made',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    // Use our fetched daily sales data
    final chartData = dailySalesData;
    
    print('🔍 Chart data: $chartData');
    print('🔍 Chart data length: ${chartData.length}');
    
    // Debug the spots being created
    final spots = chartData.asMap().entries.map((entry) {
      final spot = FlSpot(
        entry.key.toDouble(),
        // Use order_count for our daily sales data
        (entry.value['order_count'] as num?)?.toDouble() ?? 0.0,
      );
      print('🔍 Spot ${entry.key}: x=${spot.x}, y=${spot.y}, order_count=${entry.value['order_count']}');
      return spot;
    }).toList();
    print('🔍 Total spots: ${spots.length}');
    
    return SizedBox(
      height: context.chartHeight,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateGridInterval(chartData),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        chartData[value.toInt()]['day_name'] ?? '',
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: spots.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.y,
                  color: AppTheme.primaryMaroon,
                  width: 30, // Increased from 20 to 30
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryMaroon.withOpacity(0.8),
                      AppTheme.primaryMaroon,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppTheme.primaryMaroon,
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dayName = chartData[group.x.toInt()]['day_name'] ?? '';
                final orderCount = rod.toY.toInt();
                return BarTooltipItem(
                  '$dayName\n$orderCount orders',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateGridInterval(List<dynamic> salesData) {
    if (salesData.isEmpty) return 5;
    
    final maxValue = salesData.fold<double>(
      0,
      (sum, item) => math.max(sum, (item['order_count'] as num?)?.toDouble() ?? 0.0),
    );
    
    if (maxValue <= 10) return 2;
    if (maxValue <= 20) return 5;
    if (maxValue <= 50) return 10;
    return 20;
  }
}
