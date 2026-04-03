import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/zakat_provider.dart';
import '../../../src/models/zakat/zakat_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/zakat/add_zakat_dialog.dart';
import '../../widgets/zakat/delete_zakat_dialog.dart';
import '../../widgets/zakat/edit_zakat_dialog.dart';
import '../../widgets/zakat/view_zakat_dialog.dart';
import '../../widgets/zakat/zakat_table.dart';
import '../../widgets/zakat/zakat_filter_dialog.dart';

class ZakatPage extends StatefulWidget {
  const ZakatPage({super.key});

  @override
  State<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends State<ZakatPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ZakatProvider>();
      provider.loadZakatRecords();
      provider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddZakatDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const AddZakatDialog());
  }

  void _showEditZakatDialog(Zakat zakat) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditZakatDialog(zakat: zakat),
    );
  }

  void _showDeleteZakatDialog(Zakat zakat) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteZakatDialog(zakat: zakat),
    );
  }

  void _showViewZakatDialog(Zakat zakat) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewZakatDetailsDialog(zakat: zakat),
    );
  }

  Future<void> _handleRefresh() async {
    final provider = context.read<ZakatProvider>();
    await provider.refreshZakatRecords();
  }

  void _handleFilterTap() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const ZakatFilterDialog());
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
              Consumer<ZakatProvider>(
                builder: (context, provider, child) {
                  return context.statsCardColumns == 2 ? _buildMobileStatsGrid(provider) : _buildDesktopStatsRow(provider);
                },
              ),
              SizedBox(height: context.cardPadding * 0.5),
              _buildSearchSection(),
              SizedBox(height: context.cardPadding * 0.5),
              Expanded(
                child: EnhancedZakatTable(onEdit: _showEditZakatDialog, onDelete: _showDeleteZakatDialog, onView: _showViewZakatDialog),
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
                style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.screenTooSmallMessage,
                style: TextStyle(fontSize: 3.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
                l10n.zakatManagement,
                style: TextStyle(
                  fontSize: context.headingFontSize / 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                l10n.zakatManagementDescription,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
          l10n.zakatManagement,
          style: TextStyle(
            fontSize: context.headingFontSize / 1.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.trackZakatContributions,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
          l10n.zakat,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.trackContributions,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
          onTap: _showAddZakatDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.5, vertical: context.cardPadding / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? l10n.add : '${l10n.add} ${l10n.zakat}',
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

  Widget _buildDesktopStatsRow(ZakatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.zakatStats;

    return Row(
      children: [
        Expanded(child: _buildStatsCard(l10n.totalRecords, stats['total'].toString(), Icons.account_balance_wallet_rounded, Colors.blue)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard(l10n.thisYear, stats['thisYear'].toString(), Icons.calendar_today_rounded, Colors.green)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard(l10n.totalAmount, 'PKR ${stats['totalAmount']}', Icons.attach_money_rounded, Colors.purple)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard(l10n.thisMonth, stats['thisMonth'].toString(), Icons.date_range_rounded, Colors.orange)),
      ],
    );
  }

  Widget _buildMobileStatsGrid(ZakatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.zakatStats;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatsCard(l10n.total, stats['total'].toString(), Icons.account_balance_wallet_rounded, Colors.blue)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildStatsCard(l10n.thisYear, stats['thisYear'].toString(), Icons.calendar_today_rounded, Colors.green)),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildStatsCard(l10n.amount, 'PKR ${stats['totalAmount']}', Icons.attach_money_rounded, Colors.purple)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildStatsCard(l10n.thisMonth, stats['thisMonth'].toString(), Icons.date_range_rounded, Colors.orange)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
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
        Expanded(flex: 4, child: _buildSearchBar()),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 1, child: _buildFilterButton()),
      ],
    );
  }

  Widget _buildTabletSearchLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        SizedBox(height: context.cardPadding),
        Row(children: [Expanded(child: _buildFilterButton())]),
      ],
    );
  }

  Widget _buildMobileSearchLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        SizedBox(height: context.smallPadding),
        Row(children: [Expanded(child: _buildFilterButton())]),
      ],
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: Consumer<ZakatProvider>(
        builder: (context, provider, child) {
          return TextField(
            controller: _searchController,
            onChanged: provider.searchZakat,
            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
            decoration: InputDecoration(
              hintText: context.isTablet ? '${l10n.search} ${l10n.zakat}...' : l10n.searchZakatHint,
              hintStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: context.iconSize('medium')),
              suffixIcon: provider.searchQuery.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  provider.searchZakat('');
                },
                icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: context.iconSize('small')),
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2, vertical: context.cardPadding / 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
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
            Icon(Icons.filter_list_rounded, color: Colors.green, size: context.iconSize('medium')),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                l10n.filter,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.green),
              ),
            ],
          ],
        ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
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
                  style: TextStyle(fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context), fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
