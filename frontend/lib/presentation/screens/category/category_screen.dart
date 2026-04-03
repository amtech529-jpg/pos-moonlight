import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/category_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/category/add_category_dailog.dart';
import '../../widgets/category/category_table.dart';
import '../../widgets/category/delete_category_dialog.dart';
import '../../widgets/category/edit_category_dialog.dart';
import '../../widgets/category/view_category_details_dialog.dart';
import '../../widgets/category/category_filter_dialog.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Local state for the current filter
  CategoryFilter _activeFilter = CategoryFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddCategoryDialog(),
    );
  }

  /// Opens the filter dialog and updates the local filter state
  void _showFilterDialog() async {
    final result = await showDialog<CategoryFilter>(
      context: context,
      builder: (context) => CategoryFilterDialog(initialFilter: _activeFilter),
    );

    if (result != null) {
      setState(() {
        _activeFilter = result;
      });
      // You can add logic here to trigger a filtered fetch from the provider
      // context.read<CategoryProvider>().fetchCategories(filter: _activeFilter);
    }
  }

  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditCategoryDialog(category: category),
    );
  }

  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteCategoryDialog(category: category),
    );
  }

  void _showViewCategoryDialog(Category category) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewCategoryDetailsDialog(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check minimum screen size support
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Padding(
        padding: EdgeInsets.all(context.mainPadding / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Header Section
            ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildTabletHeader(),
              small: _buildMobileHeader(),
              medium: _buildDesktopHeader(),
              large: _buildDesktopHeader(),
              ultrawide: _buildDesktopHeader(),
            ),

            SizedBox(height: context.mainPadding),

            // Responsive Stats Cards
            Consumer<CategoryProvider>(
              builder: (context, provider, child) {
                return context.statsCardColumns == 2
                    ? _buildMobileStatsGrid(provider)
                    : _buildDesktopStatsRow(provider);
              },
            ),

            SizedBox(height: context.cardPadding * 0.5),

            // Responsive Search Section
            _buildSearchSection(),

            SizedBox(height: context.cardPadding * 0.5),

            // Enhanced Categories Table with View functionality
            Expanded(
              child: EnhancedCategoryTable(
                filter: _activeFilter,
                onEdit: _showEditCategoryDialog,
                onDelete: _showDeleteCategoryDialog,
                onView: _showViewCategoryDialog,
              ),
            ),
          ],
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
              Icon(
                Icons.screen_rotation_outlined,
                size: 15.w,
                color: Colors.grey[400],
              ),
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
        // Page Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.category} ${l10n.customerManagement}',
                style: TextStyle(
                  fontSize: context.headingFontSize / 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                l10n.customerManagementDescription,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Add Category Button
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Title
        Text(
          '${l10n.category} ${l10n.customerManagement}',
          style: TextStyle(
            fontSize: context.headingFontSize / 1.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.manageProductCategories,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: context.cardPadding),

        // Add Category Button (full width on tablet)
        SizedBox(
          width: double.infinity,
          child: _buildAddButton(),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Page Title
        Text(
          l10n.category,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.manageProductCategories,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: context.cardPadding),

        // Add Category Button (full width)
        SizedBox(
          width: double.infinity,
          child: _buildAddButton(),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
        ),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddCategoryDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.cardPadding * 0.5,
              vertical: context.cardPadding / 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: AppTheme.pureWhite,
                  size: context.iconSize('medium'),
                ),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? l10n.add : '${l10n.add} ${l10n.category}',
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

  Widget _buildDesktopStatsRow(CategoryProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.categoryStats;

    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
              '${l10n.total} ${l10n.category}',
              stats['total'].toString(),
              Icons.category_rounded,
              Colors.blue
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
              l10n.recent,
              stats['recentlyAdded'].toString(),
              Icons.new_releases_rounded,
              Colors.green
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
              l10n.popular,
              stats['mostPopular'],
              Icons.trending_up_rounded,
              Colors.purple
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
              l10n.updated,
              stats['recentlyUpdated'].toString(),
              Icons.update_rounded,
              Colors.orange
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsGrid(CategoryProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.categoryStats;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                  l10n.total,
                  stats['total'].toString(),
                  Icons.category_rounded,
                  Colors.blue
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                  l10n.recent,
                  stats['recentlyAdded'].toString(),
                  Icons.new_releases_rounded,
                  Colors.green
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                  l10n.popular,
                  stats['mostPopular'],
                  Icons.trending_up_rounded,
                  Colors.purple
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                  l10n.updated,
                  stats['recentlyUpdated'].toString(),
                  Icons.update_rounded,
                  Colors.orange
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
      child: ResponsiveBreakpoints.responsive(
        context,
        tablet: _buildTabletSearchLayout(),
        small: _buildMobileSearchLayout(),
        medium: _buildDesktopSearchLayout(),
        large: _buildDesktopSearchLayout(),
        ultrawide: _buildDesktopSearchLayout(),
      ),
    );
  }

  Widget _buildDesktopSearchLayout() {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 3,
          child: _buildSearchBar(),
        ),

        SizedBox(width: context.cardPadding),

        // Filter Button
        Expanded(
          flex: 1,
          child: _buildFilterButton(),
        ),

        SizedBox(width: context.smallPadding),

        // Export Button
        Expanded(
          flex: 1,
          child: _buildExportButton(),
        ),
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
            Expanded(child: _buildExportButton()),
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
            Expanded(child: _buildExportButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          return TextField(
            controller: _searchController,
            onChanged: provider.searchCategories,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: AppTheme.charcoalGray,
            ),
            decoration: InputDecoration(
              hintText: context.isTablet
                  ? '${l10n.search} ${l10n.category}...'
                  : l10n.searchCategoriesHint,
              hintStyle: TextStyle(
                fontSize: context.bodyFontSize * 0.9,
                color: Colors.grey[500],
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey[500],
                size: context.iconSize('medium'),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  provider.searchCategories('');
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

    return InkWell(
      onTap: _showFilterDialog,
      borderRadius: BorderRadius.circular(context.borderRadius()),
      child: Container(
        height: context.buttonHeight / 1.5,
        padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
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
    );
  }

  Widget _buildExportButton() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_rounded,
            color: AppTheme.accentGold,
            size: context.iconSize('medium'),
          ),
          if (!context.isTablet) ...[
            SizedBox(width: context.smallPadding),
            Text(
              l10n.export,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.accentGold,
              ),
            ),
          ],
        ],
      ),
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
            child: Icon(
              icon,
              color: color,
              size: context.dashboardIconSize('medium'),
            ),
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
                    fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context), // Use dashboard-specific size
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
