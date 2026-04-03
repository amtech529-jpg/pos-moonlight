import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/report_provider.dart';
import 'package:intl/intl.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).fetchAllReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<ReportProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFBD0D1D)));
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 32),
            _buildBusinessSummaryCards(l10n, provider.businessSummary),
            const SizedBox(height: 32),
            _buildRevenueSection(l10n, provider.monthlyRevenue),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildTopProductsTable(l10n, provider.topProducts)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildTopCustomersTable(l10n, provider.topCustomers)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportsAnalytics,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Comprehensive overview of your business performance",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Provider.of<ReportProvider>(context, listen: false).fetchAllReports(),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text("Refresh Data"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBD0D1D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessSummaryCards(AppLocalizations l10n, Map<String, dynamic> summary) {
    final f = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;
        
        if (constraints.maxWidth < 650) {
          crossAxisCount = 1;
          childAspectRatio = 2.5;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
          childAspectRatio = 2.2;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 2.2;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildSummaryCard(
              "Total Revenue",
              f.format(summary['total_revenue'] ?? 0),
              Icons.payments_rounded,
              const Color(0xFFE3F2FD),
              const Color(0xFF1976D2),
            ),
            _buildSummaryCard(
              "Net Cash Flow",
              f.format(summary['net_cash_flow'] ?? 0),
              Icons.account_balance_wallet_rounded,
              const Color(0xFFE8F5E9),
              const Color(0xFF388E3C),
            ),
            _buildSummaryCard(
              "Damage Loss",
              f.format(summary['damage_loss'] ?? 0),
              Icons.gpp_bad_rounded,
              const Color(0xFFFFF3E0),
              const Color(0xFFF57C00),
            ),
            _buildSummaryCard(
              "Recovery Rate",
              "${summary['recovery_rate'] ?? 0}%",
              Icons.trending_up_rounded,
              const Color(0xFFF3E5F5),
              const Color(0xFF7B1FA2),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title, 
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(AppLocalizations l10n, List<dynamic> data) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Revenue Performance (Monthly)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              Row(
                children: [
                  _buildLegendItem("Sales", const Color(0xFFBD0D1D)),
                  const SizedBox(width: 16),
                  _buildLegendItem("Rentals", const Color(0xFF2C3E50)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: data.isEmpty 
              ? const Center(child: Text("No revenue data available for the selected period"))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(data),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF2C3E50),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            "${data[group.x.toInt()]['month']}\n",
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: [
                               TextSpan(
                                text: NumberFormat.compact().format(rod.toY),
                                style: TextStyle(color: rod.color, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= data.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data[value.toInt()]['month'].toString().split(' ')[0], 
                                style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (v, m) => Text(NumberFormat.compact().format(v), style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _getInterval(data)),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(data.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (data[i]['sales'] ?? 0).toDouble(),
                            color: const Color(0xFFBD0D1D),
                            width: 12,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: (data[i]['rentals'] ?? 0).toDouble(),
                            color: const Color(0xFF2C3E50),
                            width: 12,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<dynamic> data) {
    double max = 0;
    for (var item in data) {
      double sales = (item['sales'] ?? 0).toDouble();
      double rentals = (item['rentals'] ?? 0).toDouble();
      if (sales > max) max = sales;
      if (rentals > max) max = rentals;
    }
    return max * 1.2;
  }

  double _getInterval(List<dynamic> data) {
    double max = _getMaxY(data);
    return max > 0 ? max / 5 : 1000;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTopProductsTable(AppLocalizations l10n, List<dynamic> products) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Most Rented Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 20),
          _buildTableHeader([l10n.itemName, "Category", "Rents", "Revenue"]),
          if (products.isEmpty)
             Padding(padding: const EdgeInsets.all(32), child: Center(child: Text("No product data available", style: TextStyle(color: Colors.grey[400])))),
          ...products.take(6).map((item) => _buildTableRow([
            item['name'] ?? '',
            item['category'] ?? '',
            item['quantity'].toString(),
            NumberFormat.compactCurrency(symbol: 'Rs. ').format(item['revenue'] ?? 0),
          ])),
        ],
      ),
    );
  }

  Widget _buildTopCustomersTable(AppLocalizations l10n, List<dynamic> customers) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Regular Customers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 20),
          _buildTableHeader([l10n.clientName, "Orders", "Spent"]),
          if (customers.isEmpty)
             Padding(padding: const EdgeInsets.all(32), child: Center(child: Text("No customer data available", style: TextStyle(color: Colors.grey[400])))),
          ...customers.take(6).map((c) => _buildTableRow([
            c['name'] ?? '',
            c['total_orders'].toString(),
            NumberFormat.compactCurrency(symbol: 'Rs. ').format(c['total_spent'] ?? 0),
          ])),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<String> columns) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: columns.map((c) => Expanded(child: Text(c, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[700])))).toList(),
      ),
    );
  }

  Widget _buildTableRow(List<String> cells) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[50]!))),
      child: Row(
        children: cells.map((c) => Expanded(child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))))).toList(),
      ),
    );
  }
}
