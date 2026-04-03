import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/profit_loss/profit_loss_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ProfitLossDashboardSection extends StatelessWidget {
  const ProfitLossDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfitLossProvider>(
      builder: (context, provider, child) {
        if (provider.dashboardData == null) {
          return _buildLoadingState(context);
        }

        final dashboard = provider.dashboardData!;

        return ResponsiveBreakpoints.responsive(
          context,
          tablet: _buildTabletDashboard(context, dashboard),
          small: _buildMobileDashboard(context, dashboard),
          medium: _buildDesktopDashboard(context, dashboard),
          large: _buildDesktopDashboard(context, dashboard),
          ultrawide: _buildDesktopDashboard(context, dashboard),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryMaroon),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.loadingDashboardData,
            style: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDashboard(BuildContext context, dynamic dashboard) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGrowthMetricCard(context, 'salesGrowth', dashboard.growthMetrics.salesGrowth, Icons.trending_up_rounded, Colors.green),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildGrowthMetricCard(
                context,
                'expenseGrowth',
                dashboard.growthMetrics.expenseGrowth,
                Icons.trending_down_rounded,
                Colors.red,
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildGrowthMetricCard(
                context,
                'profitGrowth',
                dashboard.growthMetrics.profitGrowth,
                Icons.analytics_rounded,
                AppTheme.primaryMaroon,
              ),
            ),
          ],
        ),

        SizedBox(height: context.cardPadding),

        Row(
          children: [
            Expanded(child: _buildPeriodComparisonCard(context, 'currentMonth', dashboard.currentMonth, true)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildPeriodComparisonCard(context, 'previousMonth', dashboard.previousMonth, false)),
          ],
        ),

        SizedBox(height: context.cardPadding),

        Row(
          children: [
            Expanded(flex: 2, child: _buildTrendsCard(context, dashboard.trends)),
            SizedBox(width: context.cardPadding),
            Expanded(flex: 3, child: _buildExpenseBreakdownCard(context, dashboard.expenseBreakdown)),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletDashboard(BuildContext context, dynamic dashboard) {
    return Column(
      children: [
        _buildGrowthMetricsRow(context, dashboard.growthMetrics),
        SizedBox(height: context.cardPadding),
        _buildPeriodComparisonRow(context, dashboard.currentMonth, dashboard.previousMonth),
        SizedBox(height: context.cardPadding),
        _buildTrendsCard(context, dashboard.trends),
        SizedBox(height: context.cardPadding),
        _buildExpenseBreakdownCard(context, dashboard.expenseBreakdown),
      ],
    );
  }

  Widget _buildMobileDashboard(BuildContext context, dynamic dashboard) {
    return Column(
      children: [
        _buildGrowthMetricsRow(context, dashboard.growthMetrics),
        SizedBox(height: context.cardPadding),
        _buildPeriodComparisonRow(context, dashboard.currentMonth, dashboard.previousMonth),
        SizedBox(height: context.cardPadding),
        _buildTrendsCard(context, dashboard.trends),
        SizedBox(height: context.cardPadding),
        _buildExpenseBreakdownCard(context, dashboard.expenseBreakdown),
      ],
    );
  }

  Widget _buildGrowthMetricsRow(BuildContext context, dynamic growthMetrics) {
    return Row(
      children: [
        Expanded(child: _buildGrowthMetricCard(context, 'sales', growthMetrics.salesGrowth, Icons.trending_up_rounded, Colors.green)),
        SizedBox(width: context.smallPadding),
        Expanded(child: _buildGrowthMetricCard(context, 'expenses', growthMetrics.expenseGrowth, Icons.trending_down_rounded, Colors.red)),
        SizedBox(width: context.smallPadding),
        Expanded(child: _buildGrowthMetricCard(context, 'profit', growthMetrics.profitGrowth, Icons.analytics_rounded, AppTheme.primaryMaroon)),
      ],
    );
  }

  Widget _buildPeriodComparisonRow(BuildContext context, dynamic currentMonth, dynamic previousMonth) {
    return Row(
      children: [
        Expanded(child: _buildPeriodComparisonCard(context, 'current', currentMonth, true)),
        SizedBox(width: context.smallPadding),
        Expanded(child: _buildPeriodComparisonCard(context, 'previous', previousMonth, false)),
      ],
    );
  }

  Widget _buildGrowthMetricCard(BuildContext context, String titleKey, double growth, IconData icon, Color color) {
    final l10n = AppLocalizations.of(context)!;
    final isPositive = growth > 0;
    final isNegative = growth < 0;

    String title;
    switch (titleKey) {
      case 'salesGrowth':
        title = l10n.salesGrowth;
        break;
      case 'expenseGrowth':
        title = l10n.expenseGrowth;
        break;
      case 'profitGrowth':
        title = l10n.profitGrowth;
        break;
      case 'sales':
        title = l10n.sales;
        break;
      case 'expenses':
        title = l10n.expenses;
        break;
      case 'profit':
        title = l10n.profit;
        break;
      default:
        title = titleKey;
    }

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                title,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Text(
            '${growth.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: context.headerFontSize * 0.8,
              fontWeight: FontWeight.w700,
              color: isPositive
                  ? Colors.green
                  : isNegative
                  ? Colors.red
                  : Colors.grey[600],
            ),
          ),
          SizedBox(height: context.smallPadding / 2),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward
                    : isNegative
                    ? Icons.arrow_downward
                    : Icons.remove,
                color: isPositive
                    ? Colors.green
                    : isNegative
                    ? Colors.red
                    : Colors.grey[400],
                size: context.iconSize('small'),
              ),
              SizedBox(width: context.smallPadding / 2),
              Text(
                isPositive
                    ? l10n.increased
                    : isNegative
                    ? l10n.decreased
                    : l10n.noChange,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: isPositive
                      ? Colors.green
                      : isNegative
                      ? Colors.red
                      : Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodComparisonCard(BuildContext context, String titleKey, dynamic periodData, bool isCurrent) {
    final l10n = AppLocalizations.of(context)!;

    String title;
    switch (titleKey) {
      case 'currentMonth':
        title = l10n.currentMonth;
        break;
      case 'previousMonth':
        title = l10n.previousMonth;
        break;
      case 'current':
        title = l10n.current;
        break;
      case 'previous':
        title = l10n.previous;
        break;
      default:
        title = titleKey;
    }

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.primaryMaroon.withOpacity(0.05) : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: isCurrent ? AppTheme.primaryMaroon.withOpacity(0.3) : Colors.grey[200]!, width: isCurrent ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.subtitleFontSize,
              fontWeight: FontWeight.w600,
              color: isCurrent ? AppTheme.primaryMaroon : Colors.grey[600],
            ),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            periodData.period,
            style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[500]),
          ),
          SizedBox(height: context.cardPadding),

          _buildMetricRow(context, l10n.sales, 'PKR ${periodData.salesIncome.toStringAsFixed(0)}', Icons.trending_up_rounded, Colors.green),
          SizedBox(height: context.smallPadding),

          _buildMetricRow(context, l10n.expenses, 'PKR ${periodData.totalExpenses.toStringAsFixed(0)}', Icons.trending_down_rounded, Colors.red),
          SizedBox(height: context.smallPadding),

          _buildMetricRow(
            context,
            l10n.netProfit,
            'PKR ${periodData.netProfit.toStringAsFixed(0)}',
            Icons.analytics_rounded,
            periodData.netProfit > 0 ? Colors.green : Colors.red,
          ),
          SizedBox(height: context.smallPadding),

          _buildMetricRow(context, l10n.products, periodData.productsSold.toString(), Icons.inventory_2_rounded, AppTheme.primaryMaroon),
        ],
      ),
    );
  }

  Widget _buildTrendsCard(BuildContext context, dynamic trends) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.businessTrends,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          _buildTrendIndicator(context, l10n.salesTrend, trends.salesTrend, Icons.trending_up_rounded),
          SizedBox(height: context.smallPadding),
          _buildTrendIndicator(context, l10n.profitTrend, trends.profitTrend, Icons.analytics_rounded),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, String label, String trend, IconData icon) {
    final l10n = AppLocalizations.of(context)!;

    Color color;
    IconData trendIcon;
    String status;

    switch (trend.toLowerCase()) {
      case 'increasing':
        color = Colors.green;
        trendIcon = Icons.arrow_upward;
        status = l10n.increasing;
        break;
      case 'decreasing':
        color = Colors.red;
        trendIcon = Icons.arrow_downward;
        status = l10n.decreasing;
        break;
      default:
        color = Colors.orange;
        trendIcon = Icons.remove;
        status = l10n.stable;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: context.iconSize('small')),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
          ),
        ),
        Icon(trendIcon, color: color, size: context.iconSize('small')),
        SizedBox(width: context.smallPadding / 2),
        Text(
          status,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildExpenseBreakdownCard(BuildContext context, dynamic expenseBreakdown) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.expenseBreakdown,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          _buildExpenseItem(context, l10n.laborPayments, expenseBreakdown.laborPayments, Icons.people_rounded, Colors.blue),
          SizedBox(height: context.smallPadding),
          _buildExpenseItem(context, l10n.vendorPayments, expenseBreakdown.vendorPayments, Icons.store_rounded, Colors.orange),
          SizedBox(height: context.smallPadding),
          _buildExpenseItem(context, l10n.otherExpenses, expenseBreakdown.otherExpenses, Icons.receipt_long_rounded, Colors.red),
          SizedBox(height: context.smallPadding),
          _buildExpenseItem(context, l10n.zakat, expenseBreakdown.zakat, Icons.volunteer_activism_rounded, Colors.green),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, String label, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.smallPadding / 2),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
          child: Icon(icon, color: color, size: context.iconSize('small')),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
          ),
        ),
        Text(
          'PKR ${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: context.iconSize('small')),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
      ],
    );
  }
}
