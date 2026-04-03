import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/profit_loss/profit_loss_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ProfitLossProductAnalysis extends StatefulWidget {
  const ProfitLossProductAnalysis({super.key});

  @override
  State<ProfitLossProductAnalysis> createState() => _ProfitLossProductAnalysisState();
}

class _ProfitLossProductAnalysisState extends State<ProfitLossProductAnalysis> {
  String _sortBy = 'profitability_rank';
  bool _sortAscending = false;
  String _filterCategory = 'All';

  @override
  void initState() {
    super.initState();
  }

  // Helper to ensure the selected category still exists in the new list
  String _getValidFilterCategory(List<String> availableCategories) {
    if (availableCategories.contains(_filterCategory)) {
      return _filterCategory;
    }
    return 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfitLossProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingState(context);
        }

        if (provider.hasError) {
          return _buildErrorState(context, provider);
        }

        if (provider.productProfitability.isEmpty) {
          if (provider.isLoading) {
            return _buildLoadingState(context);
          }
          return _buildEmptyState(context);
        }

        // Calculate categories dynamically from the data
        final Set<String> categorySet = {'All'};
        if (provider.productProfitability.isNotEmpty) {
          categorySet.addAll(
              provider.productProfitability.map((p) => p.productCategory.toString()).toSet()
          );
        }
        final List<String> availableCategories = categorySet.toList();

        // Ensure we don't crash if the selected filter is no longer valid
        // We use a local variable for filtering logic, but we don't setState here to avoid the error.
        final effectiveFilterCategory = _getValidFilterCategory(availableCategories);

        final filteredProducts = _getFilteredAndSortedProducts(
            provider.productProfitability,
            effectiveFilterCategory
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, provider, availableCategories, effectiveFilterCategory),
            SizedBox(height: context.cardPadding),
            _buildSummaryStats(context, filteredProducts),
            SizedBox(height: context.cardPadding),
            _buildProductTable(context, filteredProducts),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ProfitLossProvider provider, List<String> availableCategories, String currentCategory) {
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
              Icon(Icons.inventory_2_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.productProfitabilityAnalysis,
                      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                    ),
                    if (provider.productProfitability.isNotEmpty)
                      Text(
                        l10n.analyzingProductsAcrossDifferentCategories(provider.productProfitability.length),
                        style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
                ),
                child: Text(
                  l10n.productsCount(provider.productProfitability.length),
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                ),
              ),
            ],
          ),

          SizedBox(height: context.cardPadding),

          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildMobileFilters(context, availableCategories, currentCategory),
            small: _buildMobileFilters(context, availableCategories, currentCategory),
            medium: _buildDesktopFilters(context, availableCategories, currentCategory),
            large: _buildDesktopFilters(context, availableCategories, currentCategory),
            ultrawide: _buildDesktopFilters(context, availableCategories, currentCategory),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilters(BuildContext context, List<String> availableCategories, String currentCategory) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildCategoryFilter(context, availableCategories, currentCategory)),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 3, child: _buildSortOptions(context)),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 1, child: _buildRefreshButton(context)),
      ],
    );
  }

  Widget _buildMobileFilters(BuildContext context, List<String> availableCategories, String currentCategory) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCategoryFilter(context, availableCategories, currentCategory)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildRefreshButton(context)),
          ],
        ),
        SizedBox(height: context.smallPadding),
        _buildSortOptions(context),
      ],
    );
  }

  Widget _buildCategoryFilter(BuildContext context, List<String> availableCategories, String currentCategory) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.category,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        SizedBox(height: context.smallPadding / 2),
        DropdownButtonFormField<String>(
          value: currentCategory,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          items: availableCategories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(
                category == 'All' ? l10n.all : category,
                style: TextStyle(fontSize: context.captionFontSize),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _filterCategory = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSortOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sortBy,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        SizedBox(height: context.smallPadding / 2),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'profitability_rank',
                    child: Text(l10n.rank, style: TextStyle(fontSize: context.captionFontSize)),
                  ),
                  DropdownMenuItem(
                    value: 'gross_profit',
                    child: Text(l10n.profit, style: TextStyle(fontSize: context.captionFontSize)),
                  ),
                  DropdownMenuItem(
                    value: 'units_sold',
                    child: Text(l10n.unitsSold, style: TextStyle(fontSize: context.captionFontSize)),
                  ),
                  DropdownMenuItem(
                    value: 'product_name',
                    child: Text(l10n.name, style: TextStyle(fontSize: context.captionFontSize)),
                  ),
                  DropdownMenuItem(
                    value: 'profit_margin',
                    child: Text(l10n.marginPercent, style: TextStyle(fontSize: context.captionFontSize)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),
            SizedBox(width: context.smallPadding),
            IconButton(
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
              },
              icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: AppTheme.primaryMaroon),
              tooltip: _sortAscending ? l10n.sortDescending : l10n.sortAscending,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.actions,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        SizedBox(height: context.smallPadding / 2),
        Container(
          height: context.buttonHeight / 1.5,
          width: double.infinity,
          child: Consumer<ProfitLossProvider>(
            builder: (context, provider, child) {
              return ElevatedButton.icon(
                onPressed: provider.isLoading ? null : () => provider.loadProductProfitability(),
                icon: provider.isLoading
                    ? SizedBox(
                  width: context.iconSize('small'),
                  height: context.iconSize('small'),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Icon(Icons.refresh_rounded, size: context.iconSize('small')),
                label: Text(provider.isLoading ? l10n.refreshing : l10n.refresh, style: TextStyle(fontSize: context.captionFontSize)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
                  disabledBackgroundColor: AppTheme.primaryMaroon.withOpacity(0.6),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(BuildContext context, List<dynamic> products) {
    final l10n = AppLocalizations.of(context)!;

    if (products.isEmpty) return SizedBox.shrink();

    final totalRevenue = products.fold<double>(0.0, (sum, p) => sum + p.totalRevenue);
    final totalProfit = products.fold<double>(0.0, (sum, p) => sum + p.grossProfit);
    final totalCost = products.fold<double>(0.0, (sum, p) => sum + p.totalCost);
    final avgProfitMargin = products.isNotEmpty
        ? products.fold<double>(0.0, (sum, p) => sum + p.profitMargin) / products.length
        : 0.0;
    final profitableProducts = products.where((p) => p.isProfitable).length;

    return Container(
      padding: EdgeInsets.all(context.smallPadding),
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
              Icon(Icons.analytics_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding / 2),
              Text(
                l10n.summaryStatistics,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildMobileSummaryStats(context, totalRevenue, totalProfit, totalCost, avgProfitMargin, profitableProducts, products.length),
            small: _buildMobileSummaryStats(context, totalRevenue, totalProfit, totalCost, avgProfitMargin, profitableProducts, products.length),
            medium: _buildDesktopSummaryStats(context, totalRevenue, totalProfit, totalCost, avgProfitMargin, profitableProducts, products.length),
            large: _buildDesktopSummaryStats(context, totalRevenue, totalProfit, totalCost, avgProfitMargin, profitableProducts, products.length),
            ultrawide: _buildDesktopSummaryStats(context, totalRevenue, totalProfit, totalCost, avgProfitMargin, profitableProducts, products.length),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSummaryStats(
      BuildContext context,
      double totalRevenue,
      double totalProfit,
      double totalCost,
      double avgProfitMargin,
      int profitableProducts,
      int totalProducts,
      ) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(context, l10n.totalRevenue, 'PKR ${totalRevenue.toStringAsFixed(0)}', Icons.trending_up_rounded, Colors.green),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: _buildSummaryCard(
            context,
            l10n.totalProfit,
            'PKR ${totalProfit.toStringAsFixed(0)}',
            Icons.analytics_rounded,
            totalProfit > 0 ? Colors.green : Colors.red,
          ),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: _buildSummaryCard(context, l10n.totalCost, 'PKR ${totalCost.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, Colors.orange),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: _buildSummaryCard(
            context,
            l10n.avgProfitMargin,
            '${avgProfitMargin.toStringAsFixed(1)}%',
            Icons.pie_chart_rounded,
            AppTheme.primaryMaroon,
          ),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: _buildSummaryCard(context, l10n.profitableProducts, '$profitableProducts/$totalProducts', Icons.check_circle_rounded, Colors.green),
        ),
      ],
    );
  }

  Widget _buildMobileSummaryStats(
      BuildContext context,
      double totalRevenue,
      double totalProfit,
      double totalCost,
      double avgProfitMargin,
      int profitableProducts,
      int totalProducts,
      ) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(context, l10n.totalRevenue, 'PKR ${totalRevenue.toStringAsFixed(0)}', Icons.trending_up_rounded, Colors.green),
            ),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: _buildSummaryCard(
                context,
                l10n.totalProfit,
                'PKR ${totalProfit.toStringAsFixed(0)}',
                Icons.analytics_rounded,
                totalProfit > 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: context.smallPadding),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                l10n.totalCost,
                'PKR ${totalCost.toStringAsFixed(0)}',
                Icons.account_balance_wallet_rounded,
                Colors.orange,
              ),
            ),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: _buildSummaryCard(
                context,
                l10n.avgProfitMargin,
                '${avgProfitMargin.toStringAsFixed(1)}%',
                Icons.pie_chart_rounded,
                AppTheme.primaryMaroon,
              ),
            ),
          ],
        ),
        SizedBox(height: context.smallPadding),
        _buildSummaryCard(context, l10n.profitableProducts, '$profitableProducts/$totalProducts', Icons.check_circle_rounded, Colors.green),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: context.iconSize('small')),
          SizedBox(height: context.smallPadding / 2),
          Text(
            title,
            style: TextStyle(fontSize: context.captionFontSize * 0.9, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.smallPadding / 4),
          Text(
            value,
            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable(BuildContext context, List<dynamic> products) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: ResponsiveBreakpoints.responsive(
        context,
        tablet: _buildMobileProductList(context, products),
        small: _buildMobileProductList(context, products),
        medium: _buildDesktopProductTable(context, products),
        large: _buildDesktopProductTable(context, products),
        ultrawide: _buildDesktopProductTable(context, products),
      ),
    );
  }

  Widget _buildDesktopProductTable(BuildContext context, List<dynamic> products) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: context.cardPadding,
        headingTextStyle: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        dataTextStyle: TextStyle(fontSize: context.captionFontSize),
        columns: [
          DataColumn(label: Text(l10n.rank)),
          DataColumn(label: Text(l10n.product)),
          DataColumn(label: Text(l10n.category)),
          DataColumn(label: Text(l10n.unitsSold)),
          DataColumn(label: Text(l10n.revenue)),
          DataColumn(label: Text(l10n.cost)),
          DataColumn(label: Text(l10n.profit)),
          DataColumn(label: Text(l10n.marginPercent)),
          DataColumn(label: Text(l10n.status)),
        ],
        rows: products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text('#${product.profitabilityRank}')),
              DataCell(Text(product.productName, style: TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(product.productCategory)),
              DataCell(Text(product.unitsSold.toString())),
              DataCell(Text(product.formattedTotalRevenue)),
              DataCell(Text('PKR ${product.totalCost.toStringAsFixed(0)}')),
              DataCell(
                Text(
                  product.formattedGrossProfit,
                  style: TextStyle(color: product.isProfitable ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  product.formattedProfitMargin,
                  style: TextStyle(color: product.isProfitable ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: (product.isProfitable ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Text(
                    product.isProfitable ? l10n.profitable : l10n.loss,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w600,
                      color: product.isProfitable ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileProductList(BuildContext context, List<dynamic> products) {
    final l10n = AppLocalizations.of(context)!;

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: EdgeInsets.only(bottom: context.smallPadding),
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                    decoration: BoxDecoration(color: AppTheme.primaryMaroon, borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                    child: Text(
                      '#${product.profitabilityRank}',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: context.smallPadding),
                  Expanded(
                    child: Text(
                      product.productName,
                      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                    decoration: BoxDecoration(
                      color: (product.isProfitable ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    ),
                    child: Text(
                      product.isProfitable ? l10n.profitable : l10n.loss,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w600,
                        color: product.isProfitable ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.smallPadding),

              Text(
                product.productCategory,
                style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
              ),

              SizedBox(height: context.smallPadding),

              Row(
                children: [
                  Expanded(child: _buildMetricItem(context, l10n.units, product.unitsSold.toString(), Icons.inventory_2_rounded)),
                  Expanded(child: _buildMetricItem(context, l10n.revenue, product.formattedTotalRevenue, Icons.trending_up_rounded)),
                  Expanded(child: _buildMetricItem(context, l10n.profit, product.formattedGrossProfit, Icons.analytics_rounded)),
                ],
              ),

              SizedBox(height: context.smallPadding),

              Row(
                children: [
                  Text(
                    '${l10n.profitMargin}: ',
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                  ),
                  Text(
                    product.formattedProfitMargin,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: product.isProfitable ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryMaroon, size: context.iconSize('small')),
        SizedBox(height: context.smallPadding / 2),
        Text(
          label,
          style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            child: CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.loadingProductData,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            l10n.pleaseWaitWhileWeFetchTheLatestProfitabilityInformation,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.error_outline_rounded, size: context.iconSize('xl'), color: Colors.red[400]),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.errorLoadingData,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: Colors.red[600]),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            provider.errorMessage ?? l10n.anUnexpectedErrorOccurredWhileLoadingProductData,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.cardPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => provider.recoverFromError(),
                icon: Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, foregroundColor: Colors.white),
              ),
              SizedBox(width: context.cardPadding),
              OutlinedButton.icon(
                onPressed: () => provider.clearError(),
                icon: Icon(Icons.close_rounded),
                label: Text(l10n.dismiss),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryMaroon,
                  side: BorderSide(color: AppTheme.primaryMaroon),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Consumer<ProfitLossProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon));
                }
                return Icon(Icons.inventory_2_outlined, size: context.iconSize('xl'), color: Colors.grey[400]);
              },
            ),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.loadingProductData,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            l10n.productProfitabilityDataIsBeingLoaded,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.cardPadding),
          Container(
            height: context.buttonHeight / 1.5,
            child: Consumer<ProfitLossProvider>(
              builder: (context, provider, child) {
                return ElevatedButton.icon(
                  onPressed: () => provider.loadProductProfitability(),
                  icon: Icon(Icons.refresh_rounded),
                  label: Text(l10n.refreshData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: context.cardPadding),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getFilteredAndSortedProducts(List<dynamic> products, String effectiveCategory) {
    List<dynamic> filtered = products;
    if (effectiveCategory != 'All') {
      filtered = products.where((p) => p.productCategory == effectiveCategory).toList();
    }

    filtered.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortBy) {
        case 'profitability_rank':
          aValue = a.profitabilityRank;
          bValue = b.profitabilityRank;
          break;
        case 'gross_profit':
          aValue = a.grossProfit;
          bValue = b.grossProfit;
          break;
        case 'units_sold':
          aValue = a.unitsSold;
          bValue = b.unitsSold;
          break;
        case 'product_name':
          aValue = a.productName.toLowerCase();
          bValue = b.productName.toLowerCase();
          break;
        case 'profit_margin':
          aValue = a.profitMargin;
          bValue = b.profitMargin;
          break;
        default:
          aValue = a.profitabilityRank;
          bValue = b.profitabilityRank;
      }

      if (_sortAscending) {
        return aValue.compareTo(bValue);
      } else {
        return bValue.compareTo(aValue);
      }
    });

    return filtered;
  }
}