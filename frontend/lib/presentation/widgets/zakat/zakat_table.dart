import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/zakat/zakat_model.dart';
import '../../../src/providers/zakat_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'zakat_table_helpers.dart';

class EnhancedZakatTable extends StatefulWidget {
  final Function(Zakat) onEdit;
  final Function(Zakat) onDelete;
  final Function(Zakat) onView;

  const EnhancedZakatTable({super.key, required this.onEdit, required this.onDelete, required this.onView});

  @override
  State<EnhancedZakatTable> createState() => _EnhancedZakatTableState();
}

class _EnhancedZakatTableState extends State<EnhancedZakatTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _contentHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  late ZakatTableHelpers _helpers;

  @override
  void initState() {
    super.initState();
    _helpers = ZakatTableHelpers(onEdit: widget.onEdit, onDelete: widget.onDelete, onView: widget.onView);

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
      child: Consumer<ZakatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (provider.hasError) {
            return _helpers.buildErrorState(context, provider);
          }

          if (provider.zakatRecords.isEmpty) {
            return _helpers.buildEmptyState(context);
          }

          return Scrollbar(
            controller: _headerHorizontalController,
            thumbVisibility: true,
            child: Column(
              children: [
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
                          itemCount: provider.zakatRecords.length,
                          itemBuilder: (context, index) {
                            final zakat = provider.zakatRecords[index];
                            return _buildTableRow(context, zakat, index);
                          },
                        ),
                      ),
                    ),
                  ),
                ),

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
        120.0, // Zakat ID
        200.0, // Title & Beneficiary
        160.0, // Amount
        140.0, // Date
        320.0, // Actions
      ];
    } else {
      return [
        120.0, // Zakat ID
        180.0, // Title
        200.0, // Beneficiary
        200.0, // Description
        200.0, // Notes
        140.0, // Amount
        130.0, // Date
        120.0, // Authority
        320.0, // Actions
      ];
    }
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        Container(width: columnWidths[0], child: _buildSortableHeaderCell(context, l10n.zakatId, 'id')),
        Container(width: columnWidths[1], child: _buildSortableHeaderCell(context, l10n.title, 'name')),
        if (!context.shouldShowCompactLayout)
          Container(width: columnWidths[2], child: _buildSortableHeaderCell(context, l10n.beneficiary, 'beneficiary_name')),
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[3], child: _buildHeaderCell(context, l10n.description)),
        if (!context.shouldShowCompactLayout) Container(width: columnWidths[4], child: _buildHeaderCell(context, l10n.notes)),
        Container(width: columnWidths[context.shouldShowCompactLayout ? 2 : 5], child: _buildSortableHeaderCell(context, l10n.amount, 'amount')),
        Container(width: columnWidths[context.shouldShowCompactLayout ? 3 : 6], child: _buildSortableHeaderCell(context, l10n.date, 'date')),
        if (!context.shouldShowCompactLayout)
          Container(width: columnWidths[7], child: _buildSortableHeaderCell(context, l10n.authority, 'authorized_by')),
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
    return Consumer<ZakatProvider>(
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

  Widget _buildTableRow(BuildContext context, Zakat zakat, int index) {
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
                zakat.id,
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
                  zakat.name,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (context.shouldShowCompactLayout) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Row(
                    children: [
                      _helpers.buildBeneficiaryAvatar(context, zakat),
                      SizedBox(width: context.smallPadding / 2),
                      Expanded(
                        child: Text(
                          zakat.beneficiaryName,
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (zakat.notes != null && zakat.notes!.isNotEmpty) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Text(
                      '${l10n.notes}: ${zakat.notes}',
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
                      _helpers.buildBeneficiaryAvatar(context, zakat),
                      SizedBox(width: context.smallPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zakat.beneficiaryName,
                              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (zakat.beneficiaryContact != null && zakat.beneficiaryContact!.isNotEmpty)
                              Text(
                                zakat.beneficiaryContact!,
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
                zakat.description,
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[4],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zakat.notes ?? l10n.noNotes,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 2 : 5],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                zakat.formattedAmount,
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w700, color: Colors.green[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 3 : 6],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zakat.formattedDate,
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                Text(
                  context.shouldShowCompactLayout ? zakat.formattedTime : zakat.relativeDate,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[7],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _helpers.buildAuthorityBadge(context, zakat),
                  SizedBox(height: context.smallPadding / 4),
                  _helpers.buildStatusChip(context, zakat),
                ],
              ),
            ),

          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 4 : 8],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: _helpers.buildActionsRow(context, zakat),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, ZakatProvider provider) {
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
            l10n.showingZakatRecords(
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
