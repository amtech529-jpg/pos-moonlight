import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payable/payable_model.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class PayablesTable extends StatefulWidget {
  final Function(Payable) onEdit;
  final Function(Payable) onDelete;
  final Function(Payable) onViewDetails;

  const PayablesTable({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  State<PayablesTable> createState() => _PayablesTableState();
}

class _PayablesTableState extends State<PayablesTable> {
  // Separate controllers for synchronized scrolling
  late ScrollController _headerHorizontalController;
  late ScrollController _contentHorizontalController;
  late ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    // 1. Initialize controllers
    _headerHorizontalController = ScrollController();
    _contentHorizontalController = ScrollController();
    _verticalController = ScrollController();

    // 2. Link Header -> Content
    _headerHorizontalController.addListener(() {
      if (_contentHorizontalController.hasClients &&
          _headerHorizontalController.offset != _contentHorizontalController.offset) {
        _contentHorizontalController.jumpTo(_headerHorizontalController.offset);
      }
    });

    // 3. Link Content -> Header
    _contentHorizontalController.addListener(() {
      if (_headerHorizontalController.hasClients &&
          _contentHorizontalController.offset != _headerHorizontalController.offset) {
        _headerHorizontalController.jumpTo(_contentHorizontalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _contentHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Consumer<PayablesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (provider.payables.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // --- Table Header (Horizontal Scroll Only) ---
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightGray.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(context.borderRadius('large')),
                    topRight: Radius.circular(context.borderRadius('large')),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: _headerHorizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Container(
                    width: _getTableWidth(context),
                    padding: EdgeInsets.symmetric(vertical: context.cardPadding * 0.85),
                    child: _buildTableHeader(context),
                  ),
                ),
              ),

              // --- Table Content (Vertical + Horizontal Scroll) ---
              Expanded(
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      controller: _contentHorizontalController,
                      thumbVisibility: true,
                      // Removed specific notification predicate to ensure default behavior works
                      child: SingleChildScrollView(
                        controller: _contentHorizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Container(
                          width: _getTableWidth(context),
                          // Use Column instead of ListView for stable layout inside nested scrolls
                          child: Column(
                            children: provider.payables.asMap().entries.map((entry) {
                              return _buildTableRow(context, entry.value, entry.key);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: SizedBox(
        width: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
        height: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
        child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
      ),
    );
  }

  double _getTableWidth(BuildContext context) {
    return ResponsiveBreakpoints.responsive(context, tablet: 1600.0, small: 1700.0, medium: 1800.0, large: 1900.0, ultrawide: 2000.0);
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        Container(width: columnWidths[0], child: _buildHeaderCell(context, l10n.id)),
        Container(width: columnWidths[1], child: _buildHeaderCell(context, context.isTablet ? l10n.creditor : l10n.creditorDetails)),
        Container(width: columnWidths[2], child: _buildHeaderCell(context, l10n.amounts)),
        Container(width: columnWidths[3], child: _buildHeaderCell(context, l10n.reasonItem)),
        Container(width: columnWidths[4], child: _buildHeaderCell(context, context.shouldShowFullLayout ? l10n.dates : l10n.repaymentDate)),
        Container(width: columnWidths[5], child: _buildHeaderCell(context, l10n.progress)),
        Container(width: columnWidths[6], child: _buildHeaderCell(context, l10n.status)),
        Container(width: columnWidths[7], child: _buildHeaderCell(context, l10n.actions)),
      ],
    );
  }

  List<double> _getColumnWidths(BuildContext context) {
    return [
      80.0, // ID
      180.0, // Creditor Details
      160.0, // Amounts
      160.0, // Reason/Item
      150.0, // Dates
      110.0, // Progress
      110.0, // Status
      200.0, // Actions
    ];
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray, letterSpacing: 0.2),
    );
  }

  Widget _buildTableRow(BuildContext context, Payable payable, int index) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(vertical: context.smallPadding / 4),
      child: Row(
        children: [
          // ID
          Container(
            width: columnWidths[0],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                payable.id,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Creditor Details
          Container(
            width: columnWidths[1],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payable.creditorName,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.smallPadding / 4),
                Text(
                  payable.creditorPhone ?? l10n.notAvailable,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.pkrRemaining(payable.balanceRemaining.toStringAsFixed(0)),
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w600,
                    color: payable.balanceRemaining > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Amounts
          Container(
            width: columnWidths[2],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_down_rounded, color: Colors.red, size: context.iconSize('small')),
                      SizedBox(width: context.smallPadding / 2),
                      Expanded(
                        child: Text(
                          'PKR ${payable.amountBorrowed.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  if (payable.amountPaid > 0) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Row(
                      children: [
                        Icon(Icons.trending_up_rounded, color: Colors.green, size: context.iconSize('small')),
                        SizedBox(width: context.smallPadding / 2),
                        Expanded(
                          child: Text(
                            'PKR ${payable.amountPaid.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Reason/Item
          Container(
            width: columnWidths[3],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payable.reasonOrItem,
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (payable.notes != null && payable.notes!.isNotEmpty) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    payable.notes!,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Dates
          Container(
            width: columnWidths[4],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payable.formattedExpectedRepaymentDate,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: payable.isOverdueComputed ? Colors.red : AppTheme.charcoalGray,
                  ),
                ),
                SizedBox(height: context.smallPadding / 4),
                Text(
                  '${l10n.borrowed}: ${payable.formattedDateBorrowed}',
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[500]),
                ),
                if (payable.isOverdueComputed) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    l10n.daysOverdueCount(payable.daysOverdue),
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),

          // Progress
          Container(
            width: columnWidths[5],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: payable.paymentPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(payable.isFullyPaid ? Colors.green : Colors.orange),
                  minHeight: 6,
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  '${payable.paymentPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w500,
                    color: payable.isFullyPaid ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Status
          Container(
            width: columnWidths[6],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 6),
              decoration: BoxDecoration(
                color: payable.statusColorValue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: payable.statusColorValue.withOpacity(0.2), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: payable.statusColorValue, shape: BoxShape.circle),
                  ),
                  SizedBox(width: context.smallPadding / 3),
                  Expanded(
                    child: Text(
                      payable.statusText,
                      style: TextStyle(
                        fontSize: context.captionFontSize * 0.75,
                        fontWeight: FontWeight.w600,
                        color: payable.statusColorValue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            width: columnWidths[7],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: _buildActions(context, payable),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Payable payable) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onEdit(payable),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
              child: Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // View Details Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onViewDetails(payable),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
              child: Icon(Icons.visibility_outlined, color: Colors.green, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Delete Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onDelete(payable),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
              child: Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 5.w, small: 5.w, medium: 5.w, large: 5.w, ultrawide: 5.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 5.w, small: 5.w, medium: 5.w, large: 5.w, ultrawide: 5.w),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.credit_card_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noPayablesFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              l10n.startByAddingYourFirstPayableRecord,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}