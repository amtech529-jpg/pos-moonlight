import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/profit_loss/profit_loss_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/profit loss/profit_loss_metrics_section.dart';
import '../../widgets/profit loss/profit_loss_period_selector.dart';
import '../../widgets/profit loss/profit_loss_dashboard_section.dart';
import '../../widgets/profit loss/profit_loss_product_analysis.dart';
import '../../widgets/profit loss/profit_loss_calculation_details.dart';
import '../../widgets/profit loss/profit_loss_export_dialog.dart';

class ProfitLossPage extends StatefulWidget {
  const ProfitLossPage({super.key});

  @override
  State<ProfitLossPage> createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfitLossProvider>(context, listen: false);
      await provider.initialize();
      await provider.setPeriodType('monthly');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<ProfitLossProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: EdgeInsets.all(context.mainPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildTabletHeader(provider),
                  small: _buildMobileHeader(provider),
                  medium: _buildDesktopHeader(provider),
                  large: _buildDesktopHeader(provider),
                  ultrawide: _buildDesktopHeader(provider),
                ),
                SizedBox(height: context.mainPadding),
                ProfitLossPeriodSelector(),
                SizedBox(height: context.cardPadding),
                _buildActionButtons(provider),
                SizedBox(height: context.cardPadding),
                if (provider.hasError) _buildErrorDisplay(provider),
                if (provider.hasSuccess) _buildSuccessDisplay(provider),
                _buildTabBar(),
                SizedBox(height: 5),
                Expanded(
                  child: provider.isLoading
                      ? _buildLoadingState()
                      : provider.currentProfitLoss == null
                      ? _buildEmptyState()
                      : _buildTabbedContent(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnsupportedScreen() {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.screen_rotation_outlined, size: 15.w, color: Colors.grey[400]),
              SizedBox(height: 3.h),
              Text(
                l10n.screenTooSmall,
                style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.screenTooSmallMessage,
                style: TextStyle(fontSize: 3.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('large')),
                  SizedBox(width: context.cardPadding),
                  Text(
                    l10n.profitLossStatement,
                    style: TextStyle(
                      fontSize: context.headerFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoalGray,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                l10n.profitLossStatementDescription,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              ),
              if (provider.currentProfitLoss != null) ...[
                SizedBox(height: context.smallPadding),
                Text(
                  '${l10n.period}: ${provider.currentProfitLoss!.formattedPeriod}',
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                ),
              ],
            ],
          ),
        ),
        _buildExportButton(),
      ],
    );
  }

  Widget _buildTabletHeader(ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('large')),
            SizedBox(width: context.cardPadding),
            Text(
              l10n.profitLoss,
              style: TextStyle(
                fontSize: context.headerFontSize,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoalGray,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.financialPerformanceAnalysis,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        if (provider.currentProfitLoss != null) ...[
          SizedBox(height: context.smallPadding),
          Text(
            '${l10n.period}: ${provider.currentProfitLoss!.formattedPeriod}',
            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
          ),
        ],
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildExportButton()),
      ],
    );
  }

  Widget _buildMobileHeader(ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.profitLossShort,
              style: TextStyle(
                fontSize: context.headerFontSize,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoalGray,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.financialAnalysis,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        if (provider.currentProfitLoss != null) ...[
          SizedBox(height: context.smallPadding),
          Text(
            provider.currentProfitLoss!.formattedPeriod,
            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
          ),
        ],
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildExportButton()),
      ],
    );
  }

  Widget _buildExportButton() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final provider = Provider.of<ProfitLossProvider>(context, listen: false);
            final format = await showDialog<String>(context: context, builder: (context) => const ProfitLossExportDialog());

            if (format == null) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    ),
                    SizedBox(width: context.smallPadding),
                    Text(
                      '${l10n.preparing} ${format.toUpperCase()} ${l10n.export.toLowerCase()}...',
                      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
              ),
            );

            await provider.exportProfitLossReport(format: format);

            if (provider.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage ?? l10n.exportFailed),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
                ),
              );
            } else if (provider.hasSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.successMessage ?? l10n.exportCompleted),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.5, vertical: context.cardPadding / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, color: AppTheme.accentGold, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? l10n.export : '${l10n.export} ${l10n.report}',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentGold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
            child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.calculatingProfitLoss,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.only(bottom: context.cardPadding),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              provider.errorMessage ?? l10n.unexpectedError,
              style: TextStyle(fontSize: context.bodyFontSize, color: Colors.red.shade700),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearError();
              provider.refreshData();
            },
            child: Text(
              l10n.retry,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.red.shade600),
            ),
          ),
          IconButton(
            onPressed: () => provider.clearError(),
            icon: Icon(Icons.close_rounded, color: Colors.red.shade600, size: context.iconSize('small')),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: context.iconSize('medium'), minHeight: context.iconSize('medium')),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDisplay(ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.only(bottom: context.cardPadding),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              provider.successMessage ?? l10n.operationCompletedSuccessfully,
              style: TextStyle(fontSize: context.bodyFontSize, color: Colors.green.shade700),
            ),
          ),
          IconButton(
            onPressed: () => provider.clearSuccess(),
            icon: Icon(Icons.close, color: Colors.green.shade600, size: context.iconSize('small')),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: context.iconSize('medium'), minHeight: context.iconSize('medium')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.trending_up_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.noFinancialDataAvailable,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            l10n.selectPeriodToViewAnalysis,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryMaroon,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.transparent,
        indicatorWeight: 1,
        labelStyle: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500),
        tabs: [
          Tab(icon: Icon(Icons.trending_up_rounded), text: l10n.dashboard),
          Tab(icon: Icon(Icons.inventory_2_rounded), text: l10n.products),
        ],
      ),
    );
  }

  Widget _buildTabbedContent(ProfitLossProvider provider) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDashboardTab(provider),
        _buildProductsTab(provider),
      ],
    );
  }

  Widget _buildOverviewTab(ProfitLossProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfitLossMetricsSection(),
          SizedBox(height: context.cardPadding),
          _buildExpenseAnalysis(provider),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(ProfitLossProvider provider) {
    return SingleChildScrollView(child: Column(children: [ProfitLossDashboardSection()]));
  }

  Widget _buildProductsTab(ProfitLossProvider provider) {
    return SingleChildScrollView(child: Column(children: [ProfitLossProductAnalysis()]));
  }

  Widget _buildDetailsTab(ProfitLossProvider provider) {
    return SingleChildScrollView(child: Column(children: [ProfitLossCalculationDetails()]));
  }

  Widget _buildExpenseAnalysis(ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final data = provider.currentProfitLoss!;
    final breakdown = provider.getExpenseBreakdown();

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
              Icon(Icons.analytics_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.expenseBreakdown,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ...breakdown
              .map(
                (item) => Padding(
              padding: EdgeInsets.only(bottom: context.smallPadding),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.smallPadding / 2),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    ),
                    child: Icon(_getExpenseIcon(item['category']), color: item['color'], size: context.iconSize('small')),
                  ),
                  SizedBox(width: context.cardPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['category'],
                          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                        ),
                        Text(
                          '${(item['percentage'] as double).toStringAsFixed(1)}% ${l10n.ofExpenses}',
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'PKR ${(item['amount'] as double).toStringAsFixed(0)}',
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: item['color']),
                  ),
                ],
              ),
            ),
          )
              .toList(),
          Divider(height: context.cardPadding * 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalExpenses,
                    style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                  ),
                  Text(
                    data.formattedTotalExpenses,
                    style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: Colors.red),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
                decoration: BoxDecoration(
                  color: (data.isProfitable ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Column(
                  children: [
                    Text(
                      data.isProfitable ? l10n.profitable : l10n.loss,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w700,
                        color: data.isProfitable ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      data.formattedNetProfit,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w700,
                        color: data.isProfitable ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getExpenseIcon(String category) {
    switch (category.toLowerCase()) {
      case 'labor payments':
        return Icons.people_rounded;
      case 'vendor payments':
        return Icons.store_rounded;
      case 'other expenses':
        return Icons.receipt_long_rounded;
      case 'zakat':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildActionButtons(ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: context.buttonHeight / 2,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : () => provider.refreshData(),
                icon: provider.isLoading
                    ? SizedBox(
                  width: context.iconSize('small'),
                  height: context.iconSize('small'),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Icon(Icons.refresh_rounded, size: context.iconSize('small')),
                label: Text(
                  provider.isLoading ? l10n.refreshing : l10n.refresh,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
                  disabledBackgroundColor: AppTheme.primaryMaroon.withOpacity(0.6),
                ),
              ),
            ),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Container(
              height: context.buttonHeight / 2,
              child: OutlinedButton.icon(
                onPressed: () => provider.clearError(),
                icon: Icon(Icons.clear_rounded, size: context.iconSize('small')),
                label: Text(
                  l10n.clearErrors,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryMaroon,
                  side: BorderSide(color: AppTheme.primaryMaroon),
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
