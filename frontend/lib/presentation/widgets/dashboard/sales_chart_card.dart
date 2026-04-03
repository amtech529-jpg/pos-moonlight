// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:sizer/sizer.dart';
//
// import '../../../src/providers/dashboard_provider.dart';
// import '../../../src/theme/app_theme.dart';
// import '../../../l10n/app_localizations.dart';
//
// class SalesChartCard extends StatelessWidget {
//   const SalesChartCard({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//
//     return Container(
//       height: 45.h,
//       padding: EdgeInsets.all(2.w),
//       decoration: BoxDecoration(
//         color: AppTheme.pureWhite,
//         borderRadius: BorderRadius.circular(2.w),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 1.w,
//             offset: Offset(0, 0.5.w),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // --- Header ---
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(1.w),
//                     decoration: BoxDecoration(
//                       color: AppTheme.primaryMaroon.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(1.w),
//                     ),
//                     child: Icon(
//                       Icons.show_chart_rounded,
//                       color: AppTheme.primaryMaroon,
//                       size: 2.5.sp,
//                     ),
//                   ),
//                   SizedBox(width: 2.w),
//                   Text(
//                     l10n.salesOverview,
//                     style: TextStyle(
//                       fontSize: 2.2.sp,
//                       fontWeight: FontWeight.w600,
//                       color: AppTheme.charcoalGray,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//
//           SizedBox(height: 3.h),
//
//           // --- Chart Area ---
//           Expanded(
//             child: Consumer<DashboardProvider>(
//               builder: (context, provider, child) {
//                 if (provider.isLoading && provider.salesChart.isEmpty) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (provider.salesChart.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.bar_chart_rounded, size: 8.sp, color: Colors.grey[300]),
//                         SizedBox(height: 1.h),
//                         Text(
//                           "No sales data available yet",
//                           style: TextStyle(color: Colors.grey[500], fontSize: 1.5.sp),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 // Prepare Data
//                 List<FlSpot> spots = [];
//                 List<String> bottomTitles = [];
//                 double maxSales = 0;
//
//                 for (int i = 0; i < provider.salesChart.length; i++) {
//                   final item = provider.salesChart[i];
//
//                   // Improved Safe Parsing: Handles int, double, and String
//                   double salesValue = 0.0;
//                   if (item['sales'] is num) {
//                     salesValue = (item['sales'] as num).toDouble();
//                   } else if (item['sales'] is String) {
//                     salesValue = double.tryParse(item['sales']) ?? 0.0;
//                   }
//
//                   final month = item['month'] as String? ?? '';
//
//                   spots.add(FlSpot(i.toDouble(), salesValue));
//                   bottomTitles.add(month);
//
//                   if (salesValue > maxSales) {
//                     maxSales = salesValue;
//                   }
//                 }
//
//                 // Dynamic Y-Axis Max
//                 double maxY = maxSales * 1.2;
//                 if (maxY == 0) maxY = 100;
//
//                 // Dynamic X-Axis Interval
//                 double interval = 1.0;
//                 if (bottomTitles.length > 6) {
//                   interval = (bottomTitles.length / 6).ceilToDouble();
//                 }
//
//                 return LineChart(
//                   LineChartData(
//                     gridData: FlGridData(
//                       show: true,
//                       drawVerticalLine: false,
//                       horizontalInterval: maxY / 5, // Creates about 5 grid lines
//                       getDrawingHorizontalLine: (value) {
//                         return FlLine(
//                           color: Colors.grey[200],
//                           strokeWidth: 1,
//                         );
//                       },
//                     ),
//                     titlesData: FlTitlesData(
//                       show: true,
//                       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 4.h,
//                           interval: interval,
//                           getTitlesWidget: (value, meta) {
//                             int index = value.toInt();
//                             if (index >= 0 && index < bottomTitles.length) {
//                               return Padding(
//                                 padding: EdgeInsets.only(top: 1.h),
//                                 child: Text(
//                                   bottomTitles[index],
//                                   style: TextStyle(
//                                     color: Colors.grey[600],
//                                     fontSize: 1.1.sp,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               );
//                             }
//                             return const SizedBox.shrink();
//                           },
//                         ),
//                       ),
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           interval: maxY / 5,
//                           reservedSize: 10.w, // Ensure space for labels like '1.5k'
//                           getTitlesWidget: (value, meta) {
//                             if (value == 0) return const SizedBox.shrink();
//
//                             String text;
//                             if (value >= 1000000) {
//                               text = '${(value / 1000000).toStringAsFixed(1)}M';
//                             } else if (value >= 1000) {
//                               text = '${(value / 1000).toStringAsFixed(0)}k';
//                             } else {
//                               text = value.toInt().toString();
//                             }
//
//                             return Text(
//                               text,
//                               style: TextStyle(
//                                 color: Colors.grey[500],
//                                 fontSize: 1.1.sp,
//                               ),
//                               textAlign: TextAlign.left,
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                     borderData: FlBorderData(show: false),
//                     minX: 0,
//                     maxX: (spots.length - 1).toDouble(),
//                     minY: 0,
//                     maxY: maxY,
//                     lineBarsData: [
//                       LineChartBarData(
//                         spots: spots,
//                         isCurved: true,
//                         curveSmoothness: 0.35,
//                         color: AppTheme.primaryMaroon,
//                         barWidth: 0.3.w,
//                         isStrokeCapRound: true,
//                         dotData: FlDotData(
//                           show: true, // Always show dots for visibility
//                           getDotPainter: (spot, percent, barData, index) {
//                             return FlDotCirclePainter(
//                               radius: 1.2.w, // Slightly larger dots
//                               color: Colors.white,
//                               strokeWidth: 0.3.w,
//                               strokeColor: AppTheme.primaryMaroon,
//                             );
//                           },
//                         ),
//                         belowBarData: BarAreaData(
//                           show: true,
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: [
//                               AppTheme.primaryMaroon.withOpacity(0.25),
//                               AppTheme.primaryMaroon.withOpacity(0.01),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                     lineTouchData: LineTouchData(
//                       enabled: true,
//                       touchTooltipData: LineTouchTooltipData(
//                         getTooltipColor: (touchedSpot) => AppTheme.primaryMaroon,
//                         tooltipBorderRadius:BorderRadius.all(Radius.circular(2.w)) ,
//                         tooltipPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
//                         tooltipMargin: 2.h,
//                         getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
//                           return touchedBarSpots.map((barSpot) {
//                             return LineTooltipItem(
//                               '${barSpot.y.toStringAsFixed(0)} PKR',
//                               TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 1.4.sp,
//                               ),
//                             );
//                           }).toList();
//                         },
//                       ),
//                       handleBuiltInTouches: true,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }