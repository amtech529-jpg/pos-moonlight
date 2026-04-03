import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import '../../../src/data/profit_loss_data.dart';
import '../../../src/providers/profit_loss/profit_loss_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ProfitLossMetricsSection extends StatelessWidget {
  const ProfitLossMetricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfitLossProvider>(
      builder: (context, provider, child) {
        if (provider.currentProfitLossData == null) return SizedBox.shrink();

        final data = provider.currentProfitLossData!;
        final comparison = provider.getPeriodComparison();

        return ResponsiveBreakpoints.responsive(
          context,
          tablet: _buildMobileMetrics(context, data, comparison),
          small: _buildMobileMetrics(context, data, comparison),
          medium: _buildDesktopMetrics(context, data, comparison),
          large: _buildDesktopMetrics(context, data, comparison),
          ultrawide: _buildDesktopMetrics(context, data, comparison),
        );
      },
    );
  }

  Widget _buildDesktopMetrics(BuildContext context, ProfitLossData data, Map<String, dynamic> comparison) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            l10n.totalIncome,
            data.formattedTotalIncome,
            Icons.trending_up_rounded,
            Colors.green,
            comparison.isNotEmpty ? comparison['incomeChangePercent'] : null,
            comparison.isNotEmpty ? comparison['isIncomeUp'] : null,
          ),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: _buildMetricCard(
            context,
            l10n.totalExpenses,
            data.formattedTotalExpenses,
            Icons.trending_down_rounded,
            Colors.red,
            comparison.isNotEmpty ? comparison['expenseChangePercent'] : null,
            comparison.isNotEmpty ? comparison['isExpenseUp'] : null,
          ),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: _buildProfitCard(
            context,
            data,
            comparison.isNotEmpty ? comparison['profitChangePercent'] : null,
            comparison.isNotEmpty ? comparison['isProfitUp'] : null,
          ),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: _buildMetricCard(
            context,
            l10n.profitMargin,
            data.formattedProfitMargin,
            Icons.percent_rounded,
            data.isProfitable ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMetrics(BuildContext context, ProfitLossData data, Map<String, dynamic> comparison) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildProfitCard(
          context,
          data,
          comparison.isNotEmpty ? comparison['profitChangePercent'] : null,
          comparison.isNotEmpty ? comparison['isProfitUp'] : null,
          true,
        ),

        SizedBox(height: context.smallPadding),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                l10n.income,
                data.formattedTotalIncome,
                Icons.trending_up_rounded,
                Colors.green,
                comparison.isNotEmpty ? comparison['incomeChangePercent'] : null,
                comparison.isNotEmpty ? comparison['isIncomeUp'] : null,
              ),
            ),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: _buildMetricCard(
                context,
                l10n.expenses,
                data.formattedTotalExpenses,
                Icons.trending_down_rounded,
                Colors.red,
                comparison.isNotEmpty ? comparison['expenseChangePercent'] : null,
                comparison.isNotEmpty ? comparison['isExpenseUp'] : null,
              ),
            ),
          ],
        ),

        SizedBox(height: context.smallPadding),

        _buildMetricCard(
          context,
          l10n.profitMargin,
          data.formattedProfitMargin,
          Icons.percent_rounded,
          data.isProfitable ? Colors.green : Colors.red,
          null,
          null,
          true,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color, [
        double? changePercent,
        bool? isPositive,
        bool isFullWidth = false,
      ]) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding / 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.smallPadding / 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                child: Icon(icon, color: color, size: context.iconSize('small')),
              ),
              if (changePercent != null && isPositive != null) ...[
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: context.iconSize('small'),
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      Text(
                        '${changePercent.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: context.smallPadding),
          Text(
            value,
            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding / 2),
          Text(
            title,
            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(BuildContext context, ProfitLossData data, [double? changePercent, bool? isPositive, bool isFullWidth = false]) {
    final l10n = AppLocalizations.of(context)!;
    final color = data.isProfitable ? Colors.green : Colors.red;

    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding / 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.smallPadding),
                decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
                child: Icon(
                  data.isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: AppTheme.pureWhite,
                  size: context.iconSize('medium'),
                ),
              ),
              if (changePercent != null && isPositive != null) ...[
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, size: context.iconSize('small'), color: AppTheme.pureWhite),
                      SizedBox(width: context.smallPadding / 2),
                      Text(
                        '${changePercent.abs().toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: context.smallPadding),
          Text(
            data.formattedNetProfit,
            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w800, color: AppTheme.pureWhite),
          ),
          SizedBox(height: context.smallPadding / 2),
          Text(
            data.isProfitable ? l10n.netProfit : l10n.netLoss,
            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}
