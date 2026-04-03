import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class ProfitLossPieChart extends StatelessWidget {
  final Map<String, dynamic> analytics;
  
  const ProfitLossPieChart({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate profit/loss values
    final totalRevenue = analytics['totalRevenue'] ?? 0.0;
    final totalExpenses = analytics['totalExpenses'] ?? 0.0;
    final netProfit = totalRevenue - totalExpenses;
    
    final data = [
      {'label': 'Revenue', 'value': totalRevenue, 'color': Colors.green},
      {'label': 'Expenses', 'value': totalExpenses, 'color': Colors.red},
      if (netProfit > 0) {'label': 'Profit', 'value': netProfit, 'color': AppTheme.primaryMaroon},
    ];

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: context.shadowBlur('light'),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, netProfit),
          SizedBox(height: context.formFieldSpacing),
          _buildPieChart(context, data),
          SizedBox(height: context.formFieldSpacing),
          _buildDetails(context, data, netProfit),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double netProfit) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: netProfit >= 0 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Icon(
            netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: netProfit >= 0 ? Colors.green : Colors.red,
            size: context.iconSize('medium'),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profit & Loss Analysis',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
              ),
              Text(
                'Current month overview',
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
            color: netProfit >= 0 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.borderRadius()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                netProfit >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: netProfit >= 0 ? Colors.green : Colors.red,
                size: context.iconSize('small'),
              ),
              SizedBox(width: 4),
              Text(
                '${netProfit >= 0 ? '+' : ''}PKR ${netProfit.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w600,
                  color: netProfit >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(BuildContext context, List<Map<String, dynamic>> data) {
    return SizedBox(
      height: context.chartHeight * 0.8,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Handle touch events if needed
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: context.isTablet ? 80 : 60,
          sections: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final value = (item['value'] as double);
            final total = data.fold(0.0, (sum, d) => sum + (d['value'] as double));
            final percentage = total > 0 ? (value / total) * 100 : 0.0;
            
            return PieChartSectionData(
              color: item['color'] as Color,
              value: value,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: context.isTablet ? 50 : 40,
              titleStyle: TextStyle(
                fontSize: context.isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.pureWhite,
              ),
              titlePositionPercentageOffset: 0.6,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, List<Map<String, dynamic>> data, double netProfit) {
    return Column(
      children: data.map((item) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.smallPadding / 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Text(
                'PKR ${(item['value'] as double).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
