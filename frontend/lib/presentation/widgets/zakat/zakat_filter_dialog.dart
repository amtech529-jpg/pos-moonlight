import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import '../../../src/providers/zakat_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/custom_date_picker.dart';

class ZakatFilterDialog extends StatefulWidget {
  const ZakatFilterDialog({super.key});

  @override
  State<ZakatFilterDialog> createState() => _ZakatFilterDialogState();
}

class _ZakatFilterDialogState extends State<ZakatFilterDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String? _selectedBeneficiary;
  String? _selectedAuthority;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _showInactiveOnly = false;
  String _searchQuery = '';

  final TextEditingController _beneficiaryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _authorityOptions = ['Mr. Shahzain Baloch', 'Mr Sheikh Huzaifa'];

  final List<String> _commonBeneficiaries = ['Esha', 'Faatima', 'sadfg', 'Family', 'Orphanage', 'Mosque', 'School', 'Hospital'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    final provider = context.read<ZakatProvider>();
    _selectedBeneficiary = provider.selectedBeneficiary;
    _selectedAuthority = provider.selectedAuthority;
    _dateFrom = provider.dateFrom;
    _dateTo = provider.dateTo;
    _searchQuery = provider.searchQuery;
    _showInactiveOnly = provider.showInactive;

    _beneficiaryController.text = _selectedBeneficiary ?? '';
    _searchController.text = _searchQuery;

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _beneficiaryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleApplyFilters() async {
    final provider = context.read<ZakatProvider>();

    final beneficiary = _beneficiaryController.text.trim().isEmpty ? null : _beneficiaryController.text.trim();
    final search = _searchController.text.trim();

    if (beneficiary != provider.selectedBeneficiary) {
      await provider.setBeneficiaryFilter(beneficiary);
    }
    if (_selectedAuthority != provider.selectedAuthority) {
      await provider.setAuthorityFilter(_selectedAuthority);
    }
    if (_dateFrom != provider.dateFrom || _dateTo != provider.dateTo) {
      await provider.setDateRangeFilter(_dateFrom, _dateTo);
    }
    if (search != provider.searchQuery) {
      await provider.searchZakat(search);
    }
    if (_showInactiveOnly != provider.showInactive) {
      await provider.setShowInactiveFilter(_showInactiveOnly);
    }

    _handleClose();
  }

  void _handleClearFilters() async {
    final provider = context.read<ZakatProvider>();
    await provider.clearFilters();
    _handleClose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _selectDateRange() async {
    final l10n = AppLocalizations.of(context)!;

    final startDate = await _selectCustomDate(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      title: l10n.selectStartDate,
      minDate: DateTime(2000),
      maxDate: DateTime.now(),
    );

    if (startDate != null) {
      final endDate = await _selectCustomDate(
        context: context,
        initialDate: _dateTo ?? startDate,
        title: l10n.selectEndDate,
        minDate: startDate,
        maxDate: DateTime.now(),
      );

      if (endDate != null) {
        setState(() {
          _dateFrom = startDate;
          _dateTo = endDate;
        });
      }
    }
  }

  Future<DateTime?> _selectCustomDate({
    required BuildContext context,
    required DateTime initialDate,
    required String title,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    final completer = Completer<DateTime?>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SyncfusionDateTimePicker(
          initialDate: initialDate,
          initialTime: TimeOfDay.now(),
          onDateTimeSelected: (date, time) {
            completer.complete(date);
          },
          title: title,
          minDate: minDate,
          maxDate: maxDate,
          showTimeInline: false,
        );
      },
    );

    return completer.future;
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
                width: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 98.w, medium: 80.w, large: 70.w, ultrawide: 60.w),
                constraints: BoxConstraints(maxWidth: 600, maxHeight: 85.h),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
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
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.filter_alt_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),

          SizedBox(width: context.cardPadding),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.filterZakatRecords,
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
                    l10n.refineYourZakatList,
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
            _buildFilterSection(title: l10n.searchZakatRecords, icon: Icons.search_outlined, child: _buildSearchFilter()),

            SizedBox(height: context.cardPadding),

            _buildFilterSection(title: l10n.recordStatus, icon: Icons.flag_outlined, child: _buildStatusFilter()),

            SizedBox(height: context.cardPadding),

            _buildFilterSection(title: l10n.beneficiary, icon: Icons.person_outline, child: _buildBeneficiaryFilter()),

            SizedBox(height: context.cardPadding),

            _buildFilterSection(title: l10n.authorizationAuthority, icon: Icons.verified_user_outlined, child: _buildAuthorityFilter()),

            SizedBox(height: context.cardPadding),

            _buildFilterSection(title: l10n.dateRange, icon: Icons.date_range_outlined, child: _buildDateRangeFilter()),

            SizedBox(height: context.mainPadding),

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
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
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
        hintText: l10n.searchByNameDescriptionBeneficiaryOrNotes,
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
        contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
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
            l10n.showInactiveRecordsOnly,
            style: TextStyle(fontSize: ResponsiveBreakpoints.getDashboardSubtitleFontSize(context), fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
          ),
          activeColor: AppTheme.primaryMaroon,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_showInactiveOnly)
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: context.iconSize('small')),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Text(
                    l10n.onlyDeactivatedZakatRecordsWillBeShown,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBeneficiaryFilter() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        TextFormField(
          controller: _beneficiaryController,
          style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
          decoration: InputDecoration(
            hintText: l10n.enterBeneficiaryName,
            hintStyle: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[500]),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[500], size: context.iconSize('medium')),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius()),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius()),
              borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
          ),
          onChanged: (value) {
            setState(() {
              _selectedBeneficiary = value.isEmpty ? null : value;
            });
          },
        ),
        SizedBox(height: context.smallPadding),
        Wrap(
          spacing: context.smallPadding / 2,
          runSpacing: context.smallPadding / 4,
          children: _commonBeneficiaries
              .map((beneficiary) => _buildQuickSelectChip(label: beneficiary, onTap: () => setState(() => _beneficiaryController.text = beneficiary)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAuthorityFilter() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(
          l10n.selectAuthorizationAuthority,
          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: context.smallPadding),
        ...(_authorityOptions.map(
              (authority) => RadioListTile<String>(
            value: authority,
            groupValue: _selectedAuthority,
            onChanged: (value) {
              setState(() {
                _selectedAuthority = value;
              });
            },
            title: Text(
              authority,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
            ),
            activeColor: AppTheme.primaryMaroon,
            dense: true,
          ),
        )),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _selectedAuthority = null;
            });
          },
          icon: Icon(Icons.clear, color: Colors.grey[600], size: context.iconSize('small')),
          label: Text(
            l10n.clearAuthorityFilter,
            style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDateRange,
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Container(
                  padding: EdgeInsets.all(context.cardPadding),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.date_range_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
                          SizedBox(width: context.smallPadding),
                          Text(
                            l10n.selectDateRange,
                            style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                          ),
                        ],
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Text(
                        _dateFrom != null && _dateTo != null
                            ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year} - ${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}'
                            : l10n.noDateRangeSelected,
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          color: _dateFrom != null && _dateTo != null ? AppTheme.charcoalGray : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_dateFrom != null || _dateTo != null) ...[
          SizedBox(height: context.smallPadding),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    });
                  },
                  icon: Icon(Icons.clear, color: Colors.red[600], size: context.iconSize('small')),
                  label: Text(
                    l10n.clearDateRange,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.red[600]),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          color: AppTheme.primaryMaroon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: AppTheme.primaryMaroon),
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
          backgroundColor: AppTheme.primaryMaroon,
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
            backgroundColor: AppTheme.primaryMaroon,
          ),
        ),
      ],
    );
  }
}
