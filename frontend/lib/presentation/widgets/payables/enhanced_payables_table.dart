import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payable/payable_model.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/theme/app_theme.dart';
import 'payables_table_helpers.dart';
import '../../../l10n/app_localizations.dart';

class EnhancedPayablesTable extends StatefulWidget {
  final Function(Payable) onEdit;
  final Function(Payable) onDelete;
  final Function(Payable) onView;

  const EnhancedPayablesTable({super.key, required this.onEdit, required this.onDelete, required this.onView});

  @override
  State<EnhancedPayablesTable> createState() => _EnhancedPayablesTableState();
}

class _EnhancedPayablesTableState extends State<EnhancedPayablesTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _contentHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  late PayablesTableHelpers _helpers;

  @override
  void initState() {
    super.initState();
    _helpers = PayablesTableHelpers(onEdit: widget.onEdit, onDelete: widget.onDelete, onView: widget.onView);

    // Synchronize horizontal scrolling between header and content
    _headerHorizontalController.addListener(() {
      if (_headerHorizontalController.hasClients && _contentHorizontalController.hasClients) {
        _contentHorizontalController.jumpTo(_headerHorizontalController.offset);
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Consumer<PayablesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (provider.hasError) {
            return _helpers.buildErrorState(context, provider);
          }

          if (provider.payables.isEmpty) {
            return _helpers.buildEmptyState(context);
          }

          return Scrollbar(
            controller: _headerHorizontalController,
            thumbVisibility: true,
            child: Column(
              children: [
                // Table Header with Horizontal Scroll
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
                      padding: EdgeInsets.symmetric(vertical: context.cardPadding * 0.85, horizontal: context.cardPadding / 2),
                      child: _buildTableHeader(context),
                    ),
                  ),
                ),

                // Table Content with Synchronized Scroll
                Expanded(
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _contentHorizontalController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Container(
                        width: _getTableWidth(context),
                        child: ListView.builder(
                          controller: _verticalController,
                          itemCount: provider.payables.length,
                          itemBuilder: (context, index) {
                            final payable = provider.payables[index];
                            return _buildTableRow(context, payable, index);
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Pagination Controls
                if (provider.paginationInfo != null && provider.paginationInfo!.totalPages > 1) _buildPaginationControls(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: SizedBox(
        width: ResponsiveBreakpoints.responsive(context, tablet: 3.w, small: 6.w, medium: 3.w, large: 4.w, ultrawide: 3.w),
        height: ResponsiveBreakpoints.responsive(context, tablet: 3.w, small: 6.w, medium: 3.w, large: 4.w, ultrawide: 3.w),
        child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
      ),
    );
  }

  double _getTableWidth(BuildContext context) {
    return ResponsiveBreakpoints.responsive(context, tablet: 1580.0, small: 1680.0, medium: 1780.0, large: 1880.0, ultrawide: 1980.0);
  }

  List<double> _getColumnWidths(BuildContext context) {
    if (context.shouldShowCompactLayout) {
      return [
        120.0, // Payable ID
        220.0, // Creditor & Reason/Qty
        160.0, // Amount
        140.0, // Date
        320.0, // Actions
      ];
    } else {
      return [
        120.0, // Payable ID
        180.0, // Creditor
        250.0, // Reason/Item
        200.0, // Vendor
        250.0, // Notes
        140.0, // Amount
        130.0, // Date
        120.0, // Priority
        320.0, // Actions
      ];
    }
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        // Payable ID
        Container(width: columnWidths[0], child: _buildSortableHeaderCell(context, l10n.payableId, 'id')),

        // Creditor
        Container(width: columnWidths[1], child: _buildSortableHeaderCell(context, l10n.creditor, 'creditor_name')),

        // Reason/Item (responsive)
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[2], child: _buildHeaderCell(context, l10n.reasonItem)),

        // Vendor (responsive)
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[3], child: _buildHeaderCell(context, l10n.vendor)),

        // Notes (responsive)
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[4], child: _buildHeaderCell(context, l10n.notes)),

        // Amount
        Container(
          width: columnWidths[context.shouldShowCompactLayout ? 2 : 5],
          child: _buildSortableHeaderCell(context, l10n.amount, 'amount_borrowed'),
        ),

        // Date
        Container(
          width: columnWidths[context.shouldShowCompactLayout ? 3 : 6],
          child: _buildSortableHeaderCell(context, l10n.dueDate, 'expected_repayment_date'),
        ),

        // Priority (hidden on compact layouts)
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[7], child: _buildSortableHeaderCell(context, l10n.priority, 'priority')),

        // Actions
        Container(width: columnWidths[context.shouldShowCompactLayout ? 4 : 8], child: _buildHeaderCell(context, l10n.actions)),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray, letterSpacing: 0.2),
    );
  }

  Widget _buildSortableHeaderCell(BuildContext context, String title, String sortKey) {
    return Consumer<PayablesProvider>(
      builder: (context, provider, child) {
        final isCurrentSort = provider.sortBy == sortKey;

        return InkWell(
          onTap: () => provider.setSortBy(sortKey),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: isCurrentSort ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  isCurrentSort ? (provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.sort,
                  size: 16,
                  color: isCurrentSort ? AppTheme.primaryMaroon : Colors.grey[500],
                ),
              ],
            ),
          ),
        );
      },
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
      padding: EdgeInsets.symmetric(vertical: context.cardPadding / 2),
      child: Row(
        children: [
          // Payable ID Column
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
                payable.id.substring(0, 8),
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Creditor Column
          Container(
            width: columnWidths[1],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        payable.creditorName,
                        style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Show reason on compact layouts
                if (context.shouldShowCompactLayout) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    payable.reasonOrItem,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Show notes on compact layouts if available
                  if (payable.notes != null && payable.notes!.isNotEmpty) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Text(
                      '${l10n.notes}: ${payable.notes}',
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Reason/Item Column (hidden on compact layouts)
          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[2],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                payable.reasonOrItem,
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Vendor Column (hidden on compact layouts)
          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[3],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: _helpers.buildVendorBadge(context, payable),
            ),

          // Notes Column (hidden on compact layouts)
          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[4],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                payable.notes ?? l10n.noNotes,
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Amount Column
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 2 : 5],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    payable.formattedAmountBorrowed,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (payable.amountPaid > 0) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    '${l10n.paid}: ${payable.formattedAmountPaid}',
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.green[600]),
                  ),
                ],
              ],
            ),
          ),

          // Date Column
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 3 : 6],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payable.formattedExpectedRepaymentDate,
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                Text(
                  context.shouldShowCompactLayout ? payable.relativeExpectedRepaymentDate : (payable.repaymentStatus ?? l10n.due),
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Priority Column (hidden on compact layouts)
          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[7],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _helpers.buildPriorityChip(context, payable),
                  SizedBox(height: context.smallPadding / 4),
                  _helpers.buildStatusChip(context, payable),
                ],
              ),
            ),

          // Actions Column
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 4 : 8],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: _helpers.buildActionsRow(context, payable),
          ),
        ],
      ),
    );
  }


  Widget _buildPaginationControls(BuildContext context, PayablesProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final pagination = provider.paginationInfo!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(context.borderRadius('large')),
          bottomRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          // Results info
          Text(
            l10n.showingPayableRecords(
              ((pagination.currentPage - 1) * pagination.pageSize) + 1,
              pagination.currentPage * pagination.pageSize > pagination.totalCount ? pagination.totalCount : pagination.currentPage * pagination.pageSize,
              pagination.totalCount,
            ),
            style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[600]),
          ),

          const Spacer(),

          // Pagination controls
          Row(
            children: [
              // Previous button
              IconButton(
                onPressed: pagination.hasPrevious ? provider.loadPreviousPage : null,
                icon: Icon(Icons.chevron_left, color: pagination.hasPrevious ? AppTheme.primaryMaroon : Colors.grey[400]),
              ),

              // Page info
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Text(
                  l10n.pageOfPages(pagination.currentPage, pagination.totalPages),
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                ),
              ),

              // Next button
              IconButton(
                onPressed: pagination.hasNext ? provider.loadNextPage : null,
                icon: Icon(Icons.chevron_right, color: pagination.hasNext ? AppTheme.primaryMaroon : Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
