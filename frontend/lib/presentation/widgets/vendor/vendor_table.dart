import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../../../src/models/vendor/vendor_model.dart';
import '../../../../../src/providers/vendor_provider.dart';
import '../../../../../src/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../screens/vendor_ledger_screen/vendor_ledger.dart';
import 'vendor_table_helpers.dart';

class EnhancedVendorTable extends StatefulWidget {
  final Function(VendorModel) onEdit;
  final Function(VendorModel) onDelete;
  final Function(VendorModel) onView;
  final bool canEdit;
  final bool canDelete;

  const EnhancedVendorTable({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    this.canEdit = true,
    this.canDelete = true,
  });

  @override
  State<EnhancedVendorTable> createState() => _EnhancedVendorTableState();
}

class _EnhancedVendorTableState extends State<EnhancedVendorTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  late VendorTableHelpers helpers;

  @override
  void initState() {
    super.initState();
    helpers = VendorTableHelpers(
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onView: widget.onView,
    );
  }

  @override
  void dispose() {
    _horizontalController.dispose();
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
      child: Consumer<VendorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (provider.hasError) {
            return helpers.buildErrorState(context, provider);
          }

          if (provider.vendors.isEmpty) {
            return helpers.buildEmptyState(context);
          }

          return Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Container(
                width: _getTableWidth(context),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray.withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(context.borderRadius('large')),
                          topRight: Radius.circular(context.borderRadius('large')),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: context.cardPadding * 0.7,
                        horizontal: context.cardPadding,
                      ),
                      child: _buildTableHeader(context),
                    ),

                    // Table Content
                    Expanded(
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        thickness: 8,
                        radius: const Radius.circular(8),
                        child: ListView.builder(
                          controller: _verticalController,
                          itemCount: provider.vendors.length,
                          itemBuilder: (context, index) {
                            final vendor = provider.vendors[index];
                            return _buildTableRow(context, vendor, index);
                          },
                        ),
                      ),
                    ),

                    // Pagination
                    if (provider.paginationInfo != null &&
                        provider.paginationInfo!.totalPages > 1)
                      _buildPaginationControls(context, provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: SizedBox(
        width: ResponsiveBreakpoints.responsive(
          context,
          tablet: 3.w,
          small: 6.w,
          medium: 3.w,
          large: 4.w,
          ultrawide: 3.w,
        ),
        height: ResponsiveBreakpoints.responsive(
          context,
          tablet: 3.w,
          small: 6.w,
          medium: 3.w,
          large: 4.w,
          ultrawide: 3.w,
        ),
        child: const CircularProgressIndicator(
          color: AppTheme.primaryMaroon,
          strokeWidth: 3,
        ),
      ),
    );
  }

  double _getTableWidth(BuildContext context) {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: 1200.0,
      small: 1300.0,
      medium: 1400.0,
      large: 1500.0,
      ultrawide: 1600.0,
    );
  }

  List<double> _getColumnWidths(BuildContext context) {
    if (context.shouldShowCompactLayout) {
      return [
        140.0, // 0 Name
        160.0, // 1 Business
        130.0, // 2 Phone
        100.0, // 3 Status
        120.0, // 4 Created
        250.0, // 5 Actions
      ];
    } else {
      return [
        140.0, // 0 Name
        160.0, // 1 Business
        130.0, // 2 Phone
        200.0, // 3 Address (Increase width for address)
        100.0, // 4 Status
        120.0, // 5 Created
        250.0, // 6 Actions
      ];
    }
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        Container(
          width: columnWidths[0],
          padding: const EdgeInsets.only(right: 8),
          child: _buildSortableHeaderCell(context, l10n.name, 'name'),
        ),
        Container(
          width: columnWidths[1],
          padding: const EdgeInsets.only(right: 8),
          child: _buildSortableHeaderCell(context, l10n.businessName, 'business_name'),
        ),
        Container(
          width: columnWidths[2],
          padding: const EdgeInsets.only(right: 8),
          child: _buildHeaderCell(context, l10n.phone),
        ),
        if (!context.shouldShowCompactLayout)
          Container(
            width: columnWidths[3],
            padding: const EdgeInsets.only(right: 8),
            child: _buildHeaderCell(context, "Address"),
          ),
        Container(
          width: columnWidths[context.shouldShowCompactLayout ? 3 : 4],
          padding: const EdgeInsets.only(right: 8),
          child: _buildHeaderCell(context, l10n.status),
        ),
        Container(
          width: columnWidths[context.shouldShowCompactLayout ? 4 : 5],
          padding: const EdgeInsets.only(right: 8),
          child: _buildSortableHeaderCell(context, l10n.created, 'created_at'),
        ),
        Container(
          width: columnWidths[context.shouldShowCompactLayout ? 5 : 6],
          child: _buildHeaderCell(context, l10n.actions),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.bodyFontSize,
        fontWeight: FontWeight.w600,
        color: AppTheme.charcoalGray,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildSortableHeaderCell(BuildContext context, String title, String sortKey) {
    return Consumer<VendorProvider>(
      builder: (context, provider, child) {
        final isCurrentSort = provider.sortBy == sortKey;
        return InkWell(
          onTap: () => provider.setSortBy(sortKey),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isCurrentSort
                      ? (provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                      : Icons.sort,
                  size: 14,
                  color: isCurrentSort ? AppTheme.primaryMaroon : Colors.grey[500],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableRow(BuildContext context, VendorModel vendor, int index) {
    final columnWidths = _getColumnWidths(context);

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(
        vertical: context.cardPadding * 1.2,
        horizontal: context.cardPadding,
      ),
      child: Row(
        children: [
          Container(
            width: columnWidths[0],
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: columnWidths[1],
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              vendor.businessName,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: columnWidths[2],
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              vendor.formattedPhone,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[3],
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                vendor.fullAddress,
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 3 : 4],
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: helpers.getStatusColor(vendor.statusDisplayName).withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: helpers.getStatusColor(vendor.statusDisplayName).withOpacity(0.3)),
              ),
              child: Text(
                vendor.statusDisplayName,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: helpers.getStatusColor(vendor.statusDisplayName)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 4 : 5],
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              vendor.formattedCreatedAt,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 5 : 6],
            child: helpers.buildActionsRow(
              context,
              vendor,
              canEdit: widget.canEdit,
              canDelete: widget.canDelete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, VendorProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final pagination = provider.paginationInfo!;
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(context.borderRadius('large')), bottomRight: Radius.circular(context.borderRadius('large'))),
      ),
      child: Row(
        children: [
          Text(
            '${l10n.showing} ${(pagination.currentPage - 1) * pagination.pageSize + 1}-${(pagination.currentPage * pagination.pageSize > pagination.totalCount ? pagination.totalCount : pagination.currentPage * pagination.pageSize)} ${l10n.outOf} ${pagination.totalCount} ${l10n.vendor}',
            style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[600]),
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(onPressed: pagination.hasPrevious ? provider.loadPreviousPage : null, icon: Icon(Icons.chevron_left, color: pagination.hasPrevious ? AppTheme.primaryMaroon : Colors.grey[400])),
              Container(padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding), decoration: BoxDecoration(color: AppTheme.primaryMaroon.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))), child: Text('${pagination.currentPage} ${l10n.outOf} ${pagination.totalPages}', style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon))),
              IconButton(onPressed: pagination.hasNext ? provider.loadNextPage : null, icon: Icon(Icons.chevron_right, color: pagination.hasNext ? AppTheme.primaryMaroon : Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }
}
