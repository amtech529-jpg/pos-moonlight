import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/category_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../category/category_filter_dialog.dart';

class EnhancedCategoryTable extends StatefulWidget {
  final Function(Category) onEdit;
  final Function(Category) onDelete;
  final Function(Category) onView;
  final CategoryFilter? filter;

  const EnhancedCategoryTable({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    this.filter,
  });

  @override
  State<EnhancedCategoryTable> createState() => _EnhancedCategoryTableState();
}

class _EnhancedCategoryTableState extends State<EnhancedCategoryTable> {
  // Separate controllers for synchronized scrolling
  late ScrollController _headerHorizontalController;
  late ScrollController _contentHorizontalController;
  late ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController = ScrollController();
    _contentHorizontalController = ScrollController();
    _verticalController = ScrollController();

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

  /// Get filtered categories based on the applied filter
  List<Category> _getFilteredCategories(List<Category> allCategories) {
    if (widget.filter == null) {
      return allCategories;
    }

    List<Category> filtered = List.from(allCategories);

    // Filter by status
    if (widget.filter!.status != null && widget.filter!.status!.isNotEmpty) {
      filtered = filtered.where((category) {
        switch (widget.filter!.status) {
          case 'active':
            return true; // All categories are active by default in this implementation
          case 'inactive':
            return false; // No inactive categories in current implementation
          default:
            return true;
        }
      }).toList();
    }

    // Filter by date range
    if (widget.filter!.startDate != null) {
      filtered = filtered.where((category) {
        return category.dateCreated.isAfter(widget.filter!.startDate!.subtract(Duration(days: 1)));
      }).toList();
    }

    if (widget.filter!.endDate != null) {
      filtered = filtered.where((category) {
        return category.dateCreated.isBefore(widget.filter!.endDate!.add(Duration(days: 1)));
      }).toList();
    }

    // Sort categories
    if (widget.filter!.sortBy != null && widget.filter!.sortBy!.isNotEmpty) {
      switch (widget.filter!.sortBy) {
        case 'name_asc':
          filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case 'name_desc':
          filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case 'created_desc':
          filtered.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
          break;
        case 'created_asc':
          filtered.sort((a, b) => a.dateCreated.compareTo(b.dateCreated));
          break;
        case 'updated_desc':
          filtered.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
          break;
      }
    }

    return filtered;
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
      child: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
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

          if (provider.categories.isEmpty) {
            return _buildEmptyState(context);
          }

          // Get filtered categories
          final filteredCategories = _getFilteredCategories(provider.categories);
          
          if (filteredCategories.isEmpty) {
            return _buildEmptyState(context, message: "No categories match the current filter");
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
                      horizontal: context.cardPadding / 2,
                    ),
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
                            children: filteredCategories.asMap().entries.map((entry) {
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

  double _getTableWidth(BuildContext context) {
    // Fixed table width to ensure all columns are visible
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: 1400.0,
      small: 1500.0,
      medium: 1600.0,
      large: 1700.0,
      ultrawide: 1800.0,
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        // Name
        Container(
          width: columnWidths[1],
          child: _buildHeaderCell(context, l10n.name),
        ),

        // Description
        Container(
          width: columnWidths[2],
          child: _buildHeaderCell(context, l10n.notes),
        ),

        // Date Created
        Container(
          width: columnWidths[3],
          child: _buildHeaderCell(context, '${l10n.date} ${l10n.created}'),
        ),

        // Last Edited
        Container(
          width: columnWidths[4],
          child: _buildHeaderCell(context, l10n.lastUpdated),
        ),

        // Actions
        Container(
          width: columnWidths[5],
          child: _buildHeaderCell(context, l10n.actions),
        ),
      ],
    );
  }

  List<double> _getColumnWidths(BuildContext context) {
    return [
      120.0, // Category ID (Hidden/Unused in UI)
      200.0, // Name
      300.0, // Description
      150.0, // Date Created
      150.0, // Last Edited
      280.0, // Actions
    ];
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

  Widget _buildTableRow(BuildContext context, Category category, int index) {
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
          // Name
          Container(
            width: columnWidths[1],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoalGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Description
          Container(
            width: columnWidths[2],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: category.description.isNotEmpty
                ? Text(
              category.description,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoalGray,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
                : Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.smallPadding / 2,
                vertical: context.smallPadding / 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                l10n.notSpecified,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

          // Date Created
          Container(
            width: columnWidths[3],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(category.dateCreated),
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                Text(
                  _getRelativeDate(category.dateCreated),
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Last Edited
          Container(
            width: columnWidths[4],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(category.lastEdited),
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                Text(
                  _getRelativeDate(category.lastEdited),
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            width: columnWidths[5],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: _buildActions(context, category),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Category category) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onView(category),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.visibility_outlined,
                color: Colors.purple,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Edit Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onEdit(category),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: Colors.blue,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Delete Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onDelete(category),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? message}) {
    final l10n = AppLocalizations.of(context)!;
    final displayMessage = message ?? l10n.noData ?? "No categories found";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(
              context,
              tablet: 15.w,
              small: 20.w,
              medium: 12.w,
              large: 10.w,
              ultrawide: 8.w,
            ),
            height: ResponsiveBreakpoints.responsive(
              context,
              tablet: 15.w,
              small: 20.w,
              medium: 12.w,
              large: 10.w,
              ultrawide: 8.w,
            ),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(context.borderRadius('xl')),
            ),
            child: Icon(
              Icons.category_outlined,
              size: context.iconSize('xl'),
              color: Colors.grey[400],
            ),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            displayMessage,
            style: TextStyle(
              fontSize: context.headerFontSize * 0.8,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(
                context,
                tablet: 80.w,
                small: 70.w,
                medium: 60.w,
                large: 50.w,
                ultrawide: 40.w,
              ),
            ),
            child: Text(
              '${l10n.add} ${l10n.category} ${l10n.products}',
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),

        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getRelativeDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return l10n.today;
    } else if (difference == 1) {
      return l10n.yesterday;
    } else if (difference < 7) {
      return l10n.daysAgo(difference);
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? l10n.oneWeekAgo : l10n.weeksAgo(weeks);
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? l10n.oneMonthAgo : l10n.monthsAgo(months);
    } else {
      final years = (difference / 365).floor();
      return years == 1 ? l10n.oneYearAgo : l10n.yearsAgo(years);
    }
  }
}