import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import '../../../src/providers/payables_provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/custom_date_picker.dart';
import '../globals/drop_down.dart';
import '../../../l10n/app_localizations.dart';

class PayableFilterDialog extends StatefulWidget {
  const PayableFilterDialog({super.key});

  @override
  State<PayableFilterDialog> createState() => _PayableFilterDialogState();
}

class _PayableFilterDialogState extends State<PayableFilterDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Filter state variables
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedVendor;
  DateTime? _dueAfter;
  DateTime? _dueBefore;
  DateTime? _borrowedAfter;
  DateTime? _borrowedBefore;
  String _searchQuery = '';

  // Text controllers for custom inputs
  final TextEditingController _searchController = TextEditingController();

  // Predefined options
  final List<String> _statusOptions = ['ACTIVE', 'PAID', 'OVERDUE', 'PARTIALLY_PAID', 'CANCELLED'];
  final List<String> _priorityOptions = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
  static const String _allValue = 'ALL';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    // Initialize with current filter values
    final provider = context.read<PayablesProvider>();
    _selectedStatus = provider.selectedStatus ?? _allValue;
    _selectedPriority = provider.selectedPriority ?? _allValue;
    _selectedVendor = provider.selectedVendor ?? _allValue;
    _dueAfter = provider.dueAfter;
    _dueBefore = provider.dueBefore;
    _borrowedAfter = provider.borrowedAfter;
    _borrowedBefore = provider.borrowedBefore;
    _searchQuery = provider.searchQuery;

    _searchController.text = _searchQuery;

    _animationController.forward();

    // Load vendors for selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorProvider = context.read<VendorProvider>();
      vendorProvider.loadVendors();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleApplyFilters() async {
    final provider = context.read<PayablesProvider>();

    // Update search from text controller
    final search = _searchController.text.trim();

    // Apply filters using existing provider methods
    if (search != provider.searchQuery) {
      provider.setSearchQuery(search);
    }
    if (_selectedStatus != provider.selectedStatus) {
      final status = _selectedStatus == _allValue ? null : _selectedStatus;
      provider.setStatusFilter(status);
    }
    if (_selectedPriority != provider.selectedPriority) {
      final priority = _selectedPriority == _allValue ? null : _selectedPriority;
      provider.setPriorityFilter(priority);
    }
    if (_selectedVendor != provider.selectedVendor) {
      final vendor = _selectedVendor == _allValue ? null : _selectedVendor;
      provider.setVendorFilter(vendor);
    }
    if (_dueAfter != provider.dueAfter || _dueBefore != provider.dueBefore) {
      provider.setDueDateRange(_dueAfter, _dueBefore);
    }
    if (_borrowedAfter != provider.borrowedAfter || _borrowedBefore != provider.borrowedBefore) {
      provider.setBorrowedDateRange(_borrowedAfter, _borrowedBefore);
    }

    _handleClose();
  }

  void _handleClearFilters() async {
    final provider = context.read<PayablesProvider>();
    provider.clearFilters();

    // Reset local state
    setState(() {
      _selectedStatus = _allValue;
      _selectedPriority = _allValue;
      _selectedVendor = _allValue;
      _dueAfter = null;
      _dueBefore = null;
      _borrowedAfter = null;
      _borrowedBefore = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  String _getStatusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case 'ACTIVE':
        return l10n.active;
      case 'PAID':
        return l10n.paidStatus;
      case 'OVERDUE':
        return l10n.overdue;
      case 'PARTIALLY_PAID':
        return l10n.partiallyPaid;
      case 'CANCELLED':
        return l10n.cancelled;
      default:
        return status;
    }
  }

  String _getPriorityLabel(BuildContext context, String priority) {
    final l10n = AppLocalizations.of(context)!;

    switch (priority) {
      case 'LOW':
        return l10n.low;
      case 'MEDIUM':
        return l10n.medium;
      case 'HIGH':
        return l10n.high;
      case 'URGENT':
        return l10n.urgent;
      default:
        return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 99.w, small: 98.w, medium: 90.w, large: 85.w, ultrawide: 75.w),
                  maxHeight: ResponsiveBreakpoints.responsive(context, tablet: 90.h, small: 95.h, medium: 85.h, large: 80.h, ultrawide: 75.h),
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(child: _buildFilterContent()),
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
            child: Icon(Icons.filter_list_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.filterPayables,
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
                    l10n.applyFiltersToFindSpecificPayables,
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

  Widget _buildFilterContent() {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchSection(),
            SizedBox(height: context.cardPadding),
            _buildStatusPrioritySection(),
            SizedBox(height: context.cardPadding),
            _buildVendorSection(),
            SizedBox(height: context.cardPadding),
            _buildDateRangeSection(),
            SizedBox(height: context.mainPadding),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.search,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.cardPadding),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchByCreditorNameReasonNotes,
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryMaroon),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPrioritySection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statusAndPriority,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.status,
                  hint: l10n.selectStatus,
                  items: [
                    DropdownItem<String>(value: _allValue, label: l10n.allStatuses),
                    ..._statusOptions.map((status) => DropdownItem<String>(value: status, label: _getStatusLabel(context, status))),
                  ],
                  value: _selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.priority,
                  hint: l10n.selectPriority,
                  items: [
                    DropdownItem<String>(value: _allValue, label: l10n.allPriorities),
                    ..._priorityOptions.map((priority) => DropdownItem<String>(value: priority, label: _getPriorityLabel(context, priority))),
                  ],
                  value: _selectedPriority,
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVendorSection() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        return Container(
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.vendor,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              SizedBox(height: context.cardPadding),
              PremiumDropdownField<String>(
                label: l10n.vendor,
                hint: l10n.selectVendor,
                items: [
                  DropdownItem<String>(value: _allValue, label: l10n.allVendors),
                  ...vendorProvider.vendors.map(
                        (vendor) => DropdownItem<String>(value: vendor.id, label: vendor.businessName.isNotEmpty ? vendor.businessName : vendor.name),
                  ),
                ],
                value: _selectedVendor,
                onChanged: (value) {
                  setState(() {
                    _selectedVendor = value;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dateRanges,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: l10n.dueAfter,
                  selectedDate: _dueAfter,
                  onDateSelected: (date) {
                    setState(() {
                      _dueAfter = date;
                    });
                  },
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: _buildDatePicker(
                  label: l10n.dueBefore,
                  selectedDate: _dueBefore,
                  onDateSelected: (date) {
                    setState(() {
                      _dueBefore = date;
                    });
                  },
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: l10n.borrowedAfter,
                  selectedDate: _borrowedAfter,
                  onDateSelected: (date) {
                    setState(() {
                      _borrowedAfter = date;
                    });
                  },
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: _buildDatePicker(
                  label: l10n.borrowedBefore,
                  selectedDate: _borrowedBefore,
                  onDateSelected: (date) {
                    setState(() {
                      _borrowedBefore = date;
                    });
                  },
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: context.smallPadding),
        InkWell(
          onTap: () async {
            await context.showSyncfusionDateTimePicker(
              initialDate: selectedDate ?? DateTime.now(),
              initialTime: const TimeOfDay(hour: 0, minute: 0),
              onDateTimeSelected: (date, time) {
                onDateSelected(date);
              },
              title: l10n.selectDate,
              minDate: firstDate,
              maxDate: lastDate,
              showTimeInline: false,
            );
          },
          child: Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.primaryMaroon, size: 16),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                        : l10n.selectDate,
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      color: selectedDate != null ? AppTheme.charcoalGray : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: l10n.clearAll,
            onPressed: _handleClearFilters,
            backgroundColor: Colors.grey.shade300,
            textColor: AppTheme.charcoalGray,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: PremiumButton(
            text: l10n.applyFilters,
            onPressed: _handleApplyFilters,
            backgroundColor: AppTheme.primaryMaroon,
            textColor: AppTheme.pureWhite,
          ),
        ),
      ],
    );
  }
}
