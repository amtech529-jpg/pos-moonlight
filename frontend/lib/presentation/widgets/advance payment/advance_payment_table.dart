import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/advance_payment/advance_payment_model.dart';
import '../../../src/providers/advance_payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import 'advance_payment_table_helpers.dart';

class AdvancePaymentTable extends StatefulWidget {
  final Function(AdvancePayment) onEdit;
  final Function(AdvancePayment) onDelete;
  final Function(AdvancePayment) onView;

  const AdvancePaymentTable({super.key, required this.onEdit, required this.onDelete, required this.onView});

  @override
  State<AdvancePaymentTable> createState() => _AdvancePaymentTableState();
}

class _AdvancePaymentTableState extends State<AdvancePaymentTable> {
  // Separate controllers for synchronized scrolling
  late ScrollController _headerHorizontalController;
  late ScrollController _contentHorizontalController;
  late ScrollController _verticalController;
  late AdvancePaymentTableHelpers _helpers;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController = ScrollController();
    _contentHorizontalController = ScrollController();
    _verticalController = ScrollController();

    _helpers = AdvancePaymentTableHelpers(onEdit: widget.onEdit, onDelete: widget.onDelete, onView: widget.onView);

    // Link the header and content horizontal scrolling (Two-way sync)
    _headerHorizontalController.addListener(() {
      if (_contentHorizontalController.hasClients &&
          _headerHorizontalController.offset != _contentHorizontalController.offset) {
        _contentHorizontalController.jumpTo(_headerHorizontalController.offset);
      }
    });

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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Consumer<AdvancePaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (provider.hasError) {
            return _helpers.buildErrorState(context, provider);
          }

          if (provider.advancePayments.isEmpty) {
            return _helpers.buildEmptyState(context);
          }

          return Column(
            children: [
              // 1. Table Header (Horizontal Scroll)
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

              // 2. Table Content (Vertical + Horizontal Scroll)
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
                      notificationPredicate: (notification) => notification.depth == 1,
                      child: SingleChildScrollView(
                        controller: _contentHorizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Container(
                          width: _getTableWidth(context),
                          // Use Column instead of ListView for better sync in nested scrolls
                          child: Column(
                            children: provider.advancePayments.asMap().entries.map((entry) {
                              return _buildTableRow(context, entry.value, entry.key);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (provider.paginationInfo != null && provider.paginationInfo!.totalPages > 1) _buildPaginationControls(context, provider),
            ],
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
        120.0, // Payment ID
        200.0, // Labor & Details
        160.0, // Amount
        140.0, // Date
        320.0, // Actions
      ];
    } else {
      return [
        120.0, // Payment ID
        180.0, // Labor Name
        200.0, // Labor Details
        200.0, // Description
        140.0, // Amount
        130.0, // Date
        120.0, // Receipt
        320.0, // Actions
      ];
    }
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        Container(width: columnWidths[0], child: _buildSortableHeaderCell(context, l10n.paymentId, 'id')),
        Container(width: columnWidths[1], child: _buildSortableHeaderCell(context, l10n.laborName, 'labor_name')),
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[2], child: _buildHeaderCell(context, l10n.laborDetails)),
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[3], child: _buildHeaderCell(context, l10n.description)),
        Container(width: columnWidths[context.shouldShowCompactLayout ? 2 : 4], child: _buildSortableHeaderCell(context, l10n.amount, 'amount')),
        Container(width: columnWidths[context.shouldShowCompactLayout ? 3 : 5], child: _buildSortableHeaderCell(context, l10n.date, 'date')),
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[6], child: _buildHeaderCell(context, l10n.receipt)),
        Container(width: columnWidths[context.shouldShowCompactLayout ? 4 : 7], child: _buildHeaderCell(context, l10n.actions)),
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
    return Consumer<AdvancePaymentProvider>(
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
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      fontWeight: FontWeight.w600,
                      color: isCurrentSort ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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

  Widget _buildTableRow(BuildContext context, AdvancePayment payment, int index) {
    final columnWidths = _getColumnWidths(context);

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(vertical: context.cardPadding / 2),
      child: Row(
        children: [
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
                payment.id.substring(0, 8),
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          Container(
            width: columnWidths[1],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.laborName,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (context.shouldShowCompactLayout) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Row(
                    children: [
                      _helpers.buildLaborAvatar(context, payment),
                      SizedBox(width: context.smallPadding / 2),
                      Expanded(
                        child: Text(
                          payment.laborRole,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (payment.description.isNotEmpty) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Text(
                      payment.description,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),

          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[2],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _helpers.buildLaborAvatar(context, payment),
                      SizedBox(width: context.smallPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.laborRole,
                              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (payment.laborPhone.isNotEmpty)
                              Text(
                                payment.laborPhone,
                                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[3],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                payment.description,
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 2 : 4],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 3),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                'PKR ${payment.amount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: Colors.orange[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 3 : 5],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.date.day}/${payment.date.month}/${payment.date.year}',
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                Text(
                  context.shouldShowCompactLayout ? payment.time : _getRelativeDate(context, payment.date),
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[6],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: _helpers.buildReceiptBadge(context, payment),
            ),

          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 4 : 7],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: _helpers.buildActionsRow(context, payment),
          ),
        ],
      ),
    );
  }

  String _getRelativeDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return l10n.today;
    if (difference == 1) return l10n.yesterday;
    if (difference < 7) return l10n.daysAgo(difference);
    if (difference < 30) return l10n.weeksAgo((difference / 7).floor());
    if (difference < 365) return l10n.monthsAgo((difference / 30).floor());
    return l10n.yearsAgo((difference / 365).floor());
  }

  Widget _buildPaginationControls(BuildContext context, AdvancePaymentProvider provider) {
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
          Text(
            l10n.showingAdvancePayments(
              ((pagination.currentPage - 1) * pagination.pageSize) + 1,
              pagination.currentPage * pagination.pageSize > pagination.totalCount ? pagination.totalCount : pagination.currentPage * pagination.pageSize,
              pagination.totalCount,
            ),
            style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[600]),
          ),

          const Spacer(),

          Row(
            children: [
              IconButton(
                onPressed: pagination.hasPrevious ? provider.loadPreviousPage : null,
                icon: Icon(Icons.chevron_left, color: pagination.hasPrevious ? AppTheme.primaryMaroon : Colors.grey[400]),
              ),

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