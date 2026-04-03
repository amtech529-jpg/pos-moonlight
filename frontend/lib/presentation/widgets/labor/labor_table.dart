import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'labor_table_helpers.dart';

class EnhancedLaborTable extends StatefulWidget {
  final Function(LaborModel) onEdit;
  final Function(LaborModel) onDelete;
  final Function(LaborModel) onView;

  const EnhancedLaborTable({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  State<EnhancedLaborTable> createState() => _EnhancedLaborTableState();
}

class _EnhancedLaborTableState extends State<EnhancedLaborTable> {
  // Separate controllers for synchronized scrolling
  late ScrollController _headerHorizontalController;
  late ScrollController _contentHorizontalController;
  late ScrollController _verticalController;
  late LaborTableHelpers _helpers;

  @override
  void initState() {
    super.initState();
    // Initialize ALL controllers immediately
    _headerHorizontalController = ScrollController();
    _contentHorizontalController = ScrollController();
    _verticalController = ScrollController();

    _helpers = LaborTableHelpers(
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onView: widget.onView,
    );

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
      ),
      child: Consumer<LaborProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState(context);
          }

          if (provider.hasError) {
            return _helpers.buildErrorState(context, provider);
          }

          if (provider.labors.isEmpty) {
            return _helpers.buildEmptyState(context);
          }

          return Column(
            children: [
              // 1. Table Header (Horizontal Scroll Only)
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
                    padding: EdgeInsets.symmetric(
                        vertical: context.cardPadding * 0.85,
                        horizontal: context.cardPadding / 2),
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
                          // Use Column instead of ListView for smoother nested scrolling
                          child: Column(
                            children: provider.labors.asMap().entries.map((entry) {
                              return _buildTableRow(context, entry.value, entry.key);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (provider.paginationInfo != null &&
                  provider.paginationInfo!.totalPages > 1)
                _buildPaginationControls(context, provider),
            ],
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
      tablet: 1480.0,
      small: 1580.0,
      medium: 1680.0,
      large: 1780.0,
      ultrawide: 1880.0,
    );
  }

  List<double> _getColumnWidths(BuildContext context) {
    if (context.shouldShowCompactLayout) {
      return [
        180.0, // Name
        150.0, // Phone
        180.0, // CNIC
        150.0, // Designation
        120.0, // Status
        150.0, // Joined Date
        300.0, // Actions
      ];
    } else {
      return [
        180.0, // Name
        150.0, // Phone
        180.0, // CNIC
        150.0, // Designation
        120.0, // Salary
        120.0, // City
        120.0, // Status
        150.0, // Joined Date
        300.0, // Actions
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
          child: _buildSortableHeaderCell(context, l10n.name, 'name'),
        ),
        Container(
          width: columnWidths[1],
          child: _buildHeaderCell(context, l10n.phone),
        ),
        Container(
          width: columnWidths[2],
          child: _buildHeaderCell(context, l10n.cnic),
        ),
        Container(
          width: columnWidths[3],
          child: _buildSortableHeaderCell(context, l10n.designation, 'designation'),
        ),
        if (!context.shouldShowCompactLayout)
          Container(
            width: columnWidths[4],
            child: _buildSortableHeaderCell(context, l10n.salary, 'salary'),
          ),
        if (!context.shouldShowCompactLayout)
          Container(
            width: columnWidths[5],
            child: _buildSortableHeaderCell(context, l10n.city, 'city'),
          ),
        Container(
          width: columnWidths[context.shouldShowCompactLayout ? 4 : 6],
          child: _buildHeaderCell(context, l10n.status),
        ),
        Container(
          width: columnWidths[context.shouldShowCompactLayout ? 5 : 7],
          child: _buildSortableHeaderCell(context, l10n.joinedDate, 'joining_date'),
        ),
        Container(
          width: columnWidths[context.shouldShowCompactLayout ? 6 : 8],
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
    return Consumer<LaborProvider>(
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
                  isCurrentSort
                      ? (provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                      : Icons.sort,
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

  Widget _buildTableRow(BuildContext context, LaborModel labor, int index) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Container(
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.pureWhite
            : AppTheme.lightGray.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: context.cardPadding / 2),
      child: Row(
        children: [
          Container(
            width: columnWidths[0],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labor.name,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (labor.isNewLabor || labor.isRecentLabor) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Row(
                    children: [
                      if (labor.isNewLabor)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.newLabel,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      if (labor.isRecentLabor && !labor.isNewLabor) ...[
                        if (labor.isNewLabor) SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.recentLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: columnWidths[1],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              labor.formattedPhone,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoalGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: columnWidths[2],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              labor.cnic,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoalGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: columnWidths[3],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              labor.designation,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoalGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[4],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                'PKR ${labor.salary.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ),
          if (!context.shouldShowCompactLayout)
            Container(
              width: columnWidths[5],
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                labor.city,
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.charcoalGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 4 : 6],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.smallPadding,
                vertical: context.smallPadding / 2,
              ),
              decoration: BoxDecoration(
                color: _helpers.getStatusColor(labor.isActive ? 'Active' : 'Inactive').withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(
                  color: _helpers.getStatusColor(labor.isActive ? 'Active' : 'Inactive').withOpacity(0.3),
                ),
              ),
              child: Text(
                labor.isActive ? l10n.active : l10n.inactive,
                style: TextStyle(
                  fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: _helpers.getStatusColor(labor.isActive ? 'Active' : 'Inactive'),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 5 : 7],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(labor.joiningDate),
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                Text(
                  _formatDate(labor.joiningDate),
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: columnWidths[context.shouldShowCompactLayout ? 6 : 8],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: _helpers.buildActionsRow(context, labor),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, LaborProvider provider) {
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
            '${l10n.showing} ${((pagination.currentPage - 1) * pagination.pageSize) + 1}-${pagination.currentPage * pagination.pageSize > pagination.totalCount ? pagination.totalCount : pagination.currentPage * pagination.pageSize} ${l10n.outOf} ${pagination.totalCount} ${l10n.labors}',
            style: TextStyle(
              fontSize: context.subtitleFontSize,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: pagination.hasPrevious ? provider.loadPreviousPage : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: pagination.hasPrevious ? AppTheme.primaryMaroon : Colors.grey[400],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.cardPadding,
                  vertical: context.smallPadding,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Text(
                  '${pagination.currentPage} ${l10n.outOf} ${pagination.totalPages}',
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryMaroon,
                  ),
                ),
              ),
              IconButton(
                onPressed: pagination.hasNext ? provider.loadNextPage : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: pagination.hasNext ? AppTheme.primaryMaroon : Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}