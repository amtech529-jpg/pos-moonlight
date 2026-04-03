import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';

class VendorFilterDialog extends StatefulWidget {
  const VendorFilterDialog({super.key});

  @override
  State<VendorFilterDialog> createState() => _VendorFilterDialogState();
}

class _VendorFilterDialogState extends State<VendorFilterDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Filter state variables
  String? _selectedCity;
  String? _selectedArea;
  bool _showInactiveOnly = false;
  String _searchQuery = '';

  // Text controllers for custom inputs
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Predefined options
  final List<String> _commonCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
  ];
  final List<String> _commonAreas = [
    'Gulshan',
    'Clifton',
    'DHA',
    'Johar Town',
    'Model Town',
    'F-7',
    'Blue Area',
    'Saddar',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    // Initialize with current filter values
    final provider = context.read<VendorProvider>();
    _selectedCity = provider.selectedCity;
    _selectedArea = provider.selectedArea;
    _showInactiveOnly = provider.showInactive;
    _searchQuery = provider.searchQuery;

    _cityController.text = _selectedCity ?? '';
    _areaController.text = _selectedArea ?? '';
    _searchController.text = _searchQuery;

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleApplyFilters() async {
    final provider = context.read<VendorProvider>();

    // Update city, area, and search from text controllers
    final city = _cityController.text.trim().isEmpty ? null : _cityController.text.trim();
    final area = _areaController.text.trim().isEmpty ? null : _areaController.text.trim();
    final search = _searchController.text.trim();

    // Apply filters using existing provider methods
    if (city != provider.selectedCity) {
      await provider.setCityFilter(city);
    }
    if (area != provider.selectedArea) {
      await provider.setAreaFilter(area);
    }
    if (_showInactiveOnly != provider.showInactive) {
      await provider.toggleShowInactive();
    }
    if (search != provider.searchQuery) {
      await provider.searchVendors(search);
    }

    _handleClose();
  }

  void _handleClearFilters() async {
    final provider = context.read<VendorProvider>();
    await provider.clearAllFilters();
    _handleClose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 95.w,
                  small: 98.w,
                  medium: 80.w,
                  large: 70.w,
                  ultrawide: 60.w,
                ),
                constraints: BoxConstraints(maxWidth: 600, maxHeight: 85.h),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: context.shadowBlur('heavy'),
                      offset: Offset(0, context.cardPadding),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(child: _buildContent()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.accentGold, Color(0xFFD4AF37)]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Icon(Icons.filter_alt_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),

          SizedBox(width: context.cardPadding),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.filter} ${l10n.vendor}',
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!context.isTablet) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    l10n.refineVendorList,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleClose,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                child: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Filter
            _buildFilterSection(
              title: '${l10n.search} ${l10n.vendor}',
              icon: Icons.search_outlined,
              child: _buildSearchFilter(),
            ),

            SizedBox(height: context.cardPadding),

            // Status Filter
            _buildFilterSection(
              title: '${l10n.vendor} ${l10n.status}',
              icon: Icons.flag_outlined,
              child: _buildStatusFilter(),
            ),

            SizedBox(height: context.cardPadding),

            // Location Filters
            _buildFilterSection(
              title: l10n.location,
              icon: Icons.location_on_outlined,
              child: _buildLocationFilters(),
            ),

            SizedBox(height: context.mainPadding),

            // Action Buttons
            ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildCompactButtons(),
              small: _buildCompactButtons(),
              medium: _buildDesktopButtons(),
              large: _buildDesktopButtons(),
              ultrawide: _buildDesktopButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveBreakpoints.getDashboardBodyFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          child,
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: _searchController,
      style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
      decoration: InputDecoration(
        hintText: l10n.searchVendorsHint,
        hintStyle: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[500]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: context.iconSize('medium')),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
          borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.cardPadding,
          vertical: context.cardPadding / 2,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildStatusFilter() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        CheckboxListTile(
          value: _showInactiveOnly,
          onChanged: (value) {
            setState(() {
              _showInactiveOnly = value ?? false;
            });
          },
          title: Text(
            l10n.showInactiveVendorsOnly,
            style: TextStyle(
              fontSize: ResponsiveBreakpoints.getDashboardSubtitleFontSize(context),
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoalGray,
            ),
          ),
          activeColor: AppTheme.primaryMaroon,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_showInactiveOnly)
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: context.iconSize('small')),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Text(
                    l10n.onlyDeactivatedVendorsShown,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationFilters() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // City Filter
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.city,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoalGray,
              ),
            ),
            SizedBox(height: context.smallPadding),
            TextFormField(
              controller: _cityController,
              style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
              decoration: InputDecoration(
                hintText: '${l10n.enterEmail} ${l10n.city}',
                hintStyle: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[500]),
                prefixIcon: Icon(
                  Icons.location_city_outlined,
                  color: Colors.grey[500],
                  size: context.iconSize('medium'),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.cardPadding,
                  vertical: context.cardPadding / 2,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value.isEmpty ? null : value;
                });
              },
            ),
            SizedBox(height: context.smallPadding),
            Wrap(
              spacing: context.smallPadding / 2,
              runSpacing: context.smallPadding / 4,
              children: _commonCities
                  .map(
                    (city) => _buildQuickSelectChip(
                  label: city,
                  onTap: () => setState(() => _cityController.text = city),
                ),
              )
                  .toList(),
            ),
          ],
        ),

        SizedBox(height: context.cardPadding),

        // Area Filter
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.area,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoalGray,
              ),
            ),
            SizedBox(height: context.smallPadding),
            TextFormField(
              controller: _areaController,
              style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
              decoration: InputDecoration(
                hintText: '${l10n.enterEmail} ${l10n.area}',
                hintStyle: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[500]),
                prefixIcon: Icon(
                  Icons.map_outlined,
                  color: Colors.grey[500],
                  size: context.iconSize('medium'),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.cardPadding,
                  vertical: context.cardPadding / 2,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedArea = value.isEmpty ? null : value;
                });
              },
            ),
            SizedBox(height: context.smallPadding),
            Wrap(
              spacing: context.smallPadding / 2,
              runSpacing: context.smallPadding / 4,
              children: _commonAreas
                  .map(
                    (area) => _buildQuickSelectChip(
                  label: area,
                  onTap: () => setState(() => _areaController.text = area),
                ),
              )
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.borderRadius('small')),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
        decoration: BoxDecoration(
          color: AppTheme.accentGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.captionFontSize,
            fontWeight: FontWeight.w500,
            color: AppTheme.accentGold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumButton(
          text: l10n.applyFilters,
          onPressed: _handleApplyFilters,
          height: context.buttonHeight,
          icon: Icons.filter_alt_rounded,
          backgroundColor: AppTheme.accentGold,
        ),
        SizedBox(height: context.cardPadding),
        PremiumButton(
          text: l10n.clearAllFilters,
          onPressed: _handleClearFilters,
          height: context.buttonHeight,
          icon: Icons.clear_all_rounded,
          isOutlined: true,
          backgroundColor: Colors.red[600],
          textColor: Colors.red[600],
        ),
        SizedBox(height: context.smallPadding),
        PremiumButton(
          text: l10n.cancel,
          onPressed: _handleClose,
          height: context.buttonHeight,
          isOutlined: true,
          backgroundColor: Colors.grey[600],
          textColor: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildDesktopButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: l10n.cancel,
            onPressed: _handleClose,
            height: context.buttonHeight / 1.5,
            isOutlined: true,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: PremiumButton(
            text: l10n.clearAll,
            onPressed: _handleClearFilters,
            height: context.buttonHeight / 1.5,
            icon: Icons.clear_all_rounded,
            isOutlined: true,
            backgroundColor: Colors.red[600],
            textColor: Colors.red[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          flex: 2,
          child: PremiumButton(
            text: l10n.applyFilters,
            onPressed: _handleApplyFilters,
            height: context.buttonHeight / 1.5,
            icon: Icons.filter_alt_rounded,
            backgroundColor: AppTheme.accentGold,
          ),
        ),
      ],
    );
  }
}
