import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../src/models/advance_payment/advance_payment_model.dart';
import '../../../src/providers/advance_payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/advance payment/add_advance_payment_dialog.dart';
import '../../widgets/advance payment/advance_payment_filter_dialog.dart';
import '../../widgets/advance payment/advance_payment_table.dart';
import '../../widgets/advance payment/delete_advance_payment_dialog.dart';
import '../../widgets/advance payment/edit_advance_payment_dialog.dart';
import '../../widgets/advance payment/view_receipt_dialog.dart';

class AdvancePaymentPage extends StatefulWidget {
  const AdvancePaymentPage({super.key});

  @override
  State<AdvancePaymentPage> createState() => _AdvancePaymentPageState();
}

class _AdvancePaymentPageState extends State<AdvancePaymentPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdvancePaymentProvider>();
      provider.loadAdvancePayments();
      provider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final provider = context.read<AdvancePaymentProvider>();
    await provider.refreshAdvancePayments();
  }

  void _handleFilterTap() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdvancePaymentFilterDialog(),
    );
  }

  void _showAddAdvancePaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddAdvancePaymentDialog(),
    );
  }

  void _showEditAdvancePaymentDialog(AdvancePayment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditAdvancePaymentDialog(payment: payment),
    );
  }

  void _showDeleteAdvancePaymentDialog(AdvancePayment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteAdvancePaymentDialog(payment: payment),
    );
  }

  void _showViewAdvancePaymentDialog(AdvancePayment payment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewReceiptDialog(payment: payment),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryMaroon,
        child: Padding(
          padding: EdgeInsets.all(context.mainPadding / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveBreakpoints.responsive(
                context,
                tablet: _buildTabletHeader(),
                small: _buildMobileHeader(),
                medium: _buildDesktopHeader(),
                large: _buildDesktopHeader(),
                ultrawide: _buildDesktopHeader(),
              ),
              SizedBox(height: context.mainPadding),
              Consumer<AdvancePaymentProvider>(
                builder: (context, provider, child) {
                  final l10n = AppLocalizations.of(context)!;

                  if (provider.hasError) {
                    return Container(
                      padding: EdgeInsets.all(context.cardPadding),
                      margin: EdgeInsets.only(bottom: context.cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius()),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: context.smallPadding),
                          Expanded(
                            child: Text(
                              provider.errorMessage ?? l10n.unexpectedError,
                              style: TextStyle(
                                fontSize: context.bodyFontSize,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.clearError();
                              provider.loadAdvancePayments();
                            },
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  return context.statsCardColumns == 2
                      ? _buildMobileStatsGrid(provider)
                      : _buildDesktopStatsRow(provider);
                },
              ),
              SizedBox(height: context.cardPadding * 0.5),
              _buildSearchSection(),
              SizedBox(height: context.cardPadding * 0.5),
              Expanded(
                child: AdvancePaymentTable(
                  onEdit: _showEditAdvancePaymentDialog,
                  onDelete: _showDeleteAdvancePaymentDialog,
                  onView: _showViewAdvancePaymentDialog,
                ),
              ),
            ],
          ),
        ),
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
                style: TextStyle(
                  fontSize: 6.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.screenTooSmallMessage,
                style: TextStyle(
                  fontSize: 3.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.advancePaymentManagement,
                style: TextStyle(
                  fontSize: context.headingFontSize / 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                l10n.advancePaymentManagementDescription,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.advancePayments,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.manageLaborPayments,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.payments,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.advancePayments,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildAddButton() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddAdvancePaymentDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.cardPadding * 0.5,
              vertical: context.cardPadding / 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? l10n.add : '${l10n.add} ${l10n.payment}',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.pureWhite,
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

  Widget _buildDesktopStatsRow(AdvancePaymentProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.advancePaymentStats;

    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            l10n.totalPayments,
            stats['total'].toString(),
            Icons.payment_rounded,
            Colors.blue,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            l10n.totalAmount,
            'PKR ${stats['totalAmount']}',
            Icons.attach_money_rounded,
            Colors.green,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            l10n.withReceipts,
            stats['withReceipts'].toString(),
            Icons.receipt_rounded,
            Colors.purple,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            l10n.thisMonth,
            stats['thisMonth'].toString(),
            Icons.calendar_month_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsGrid(AdvancePaymentProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.advancePaymentStats;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(l10n.total, stats['total'].toString(), Icons.payment_rounded, Colors.blue),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                l10n.amount,
                'PKR ${stats['totalAmount']}',
                Icons.attach_money_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                l10n.receipts,
                stats['withReceipts'].toString(),
                Icons.receipt_rounded,
                Colors.purple,
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                l10n.thisMonth,
                stats['thisMonth'].toString(),
                Icons.calendar_month_rounded,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
      ),
      child: Consumer<AdvancePaymentProvider>(
        builder: (context, provider, child) {
          final l10n = AppLocalizations.of(context)!;

          if (provider.isLoading && provider.advancePayments.isEmpty) {
            return Container(
              height: ResponsiveBreakpoints.responsive(
                context,
                tablet: 80,
                small: 100,
                medium: 120,
                large: 140,
                ultrawide: 160,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 24,
                        small: 28,
                        medium: 32,
                        large: 36,
                        ultrawide: 40,
                      ),
                      height: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 24,
                        small: 28,
                        medium: 32,
                        large: 36,
                        ultrawide: 40,
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                      ),
                    ),
                    SizedBox(height: context.smallPadding),
                    Text(
                      l10n.loadingAdvancePayments,
                      style: TextStyle(
                        fontSize: ResponsiveBreakpoints.responsive(
                          context,
                          tablet: context.bodyFontSize * 0.9,
                          small: context.bodyFontSize,
                          medium: context.bodyFontSize * 1.1,
                          large: context.bodyFontSize * 1.2,
                          ultrawide: context.bodyFontSize * 1.3,
                        ),
                        fontWeight: FontWeight.w500,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildTabletSearchLayout(),
            small: _buildMobileSearchLayout(),
            medium: _buildDesktopSearchLayout(),
            large: _buildDesktopSearchLayout(),
            ultrawide: _buildDesktopSearchLayout(),
          );
        },
      ),
    );
  }

  Widget _buildDesktopSearchLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchBar()),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 1, child: _buildFilterButton()),
        SizedBox(width: context.smallPadding),
        Expanded(flex: 1, child: _buildRefreshButton()),
      ],
    );
  }

  Widget _buildTabletSearchLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildFilterButton()),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildRefreshButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileSearchLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        SizedBox(height: context.smallPadding),
        Row(
          children: [
            Expanded(child: _buildFilterButton()),
            SizedBox(width: context.smallPadding),
            Expanded(child: _buildRefreshButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: Consumer<AdvancePaymentProvider>(
        builder: (context, provider, child) {
          return TextField(
            controller: _searchController,
            onChanged: provider.searchAdvancePayments,
            enabled: !provider.isLoading,
            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
            decoration: InputDecoration(
              hintText: context.isTablet
                  ? '${l10n.search} ${l10n.payments}...'
                  : l10n.searchAdvancePaymentsHint,
              hintStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[500]),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey[500],
                size: context.iconSize('medium'),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  provider.searchAdvancePayments('');
                },
                icon: Icon(
                  Icons.clear_rounded,
                  color: Colors.grey[500],
                  size: context.iconSize('small'),
                ),
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.cardPadding / 2,
                vertical: context.cardPadding / 2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _handleFilterTap,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            child: Container(
              height: context.buttonHeight / 1.5,
              padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(context.borderRadius()),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: AppTheme.primaryMaroon,
                    size: context.iconSize('medium'),
                  ),
                  if (!context.isTablet) ...[
                    SizedBox(width: context.smallPadding),
                    Text(
                      l10n.filter,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryMaroon,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AdvancePaymentProvider>(
      builder: (context, provider, child) {
        return Container(
          height: context.buttonHeight / 1.5,
          padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: InkWell(
            onTap: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await _handleRefresh();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(l10n.dataRefreshedSuccessfully),
                  backgroundColor: AppTheme.primaryMaroon,
                ),
              );
            },
            borderRadius: BorderRadius.circular(context.borderRadius()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
                if (!context.isTablet) ...[
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.refresh,
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: context.statsCardHeight / 1.5,
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(icon, color: color, size: context.dashboardIconSize('medium')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveBreakpoints.responsive(
                      context,
                      tablet: 10.8.sp, // Original size
                      small: 11.2.sp, // Original size
                      medium: 11.5.sp, // Original size
                      large: 11.8.sp, // Original size
                      ultrawide: 12.2.sp, // Original size
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context),
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
