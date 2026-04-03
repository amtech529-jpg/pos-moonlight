import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/custom_date_picker.dart';
import '../globals/drop_down.dart';
import '../../../l10n/app_localizations.dart';

class PaymentFilterDialog extends StatefulWidget {
  const PaymentFilterDialog({super.key});

  @override
  State<PaymentFilterDialog> createState() => _PaymentFilterDialogState();
}

class _PaymentFilterDialogState extends State<PaymentFilterDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String? _selectedLaborId;
  String? _selectedPayerType;
  String? _selectedPaymentMethod;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  DateTime? _paymentMonthFrom;
  DateTime? _paymentMonthTo;
  double? _minAmount;
  double? _maxAmount;
  bool? _hasReceipt;
  bool? _isFinalPayment;
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _showInactive = false;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  static const String _allValue = 'ALL';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    final provider = context.read<PaymentProvider>();
    _selectedLaborId = provider.selectedLaborId ?? _allValue;
    _selectedPayerType = provider.selectedPayerType ?? _allValue;
    _selectedPaymentMethod = provider.selectedPaymentMethod ?? _allValue;
    _dateFrom = provider.dateFrom;
    _dateTo = provider.dateTo;
    _paymentMonthFrom = provider.paymentMonthFrom;
    _paymentMonthTo = provider.paymentMonthTo;
    _minAmount = provider.minAmount;
    _maxAmount = provider.maxAmount;
    _hasReceipt = provider.hasReceipt;
    _isFinalPayment = provider.isFinalPayment;
    _sortBy = provider.sortBy;
    _sortAscending = provider.sortAscending;
    _showInactive = provider.showInactive;
    _searchQuery = provider.searchQuery;

    _searchController.text = _searchQuery;
    if (_minAmount != null) _minAmountController.text = _minAmount.toString();
    if (_maxAmount != null) _maxAmountController.text = _maxAmount.toString();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _handleApplyFilters() async {
    final provider = context.read<PaymentProvider>();

    final search = _searchController.text.trim();
    if (search != provider.searchQuery) {
      await provider.searchPayments(search);
    }

    if (_selectedLaborId != provider.selectedLaborId) {
      final laborId = _selectedLaborId == _allValue ? null : _selectedLaborId;
      provider.setLaborFilter(laborId);
    }

    if (_selectedPayerType != provider.selectedPayerType) {
      final payerType = _selectedPayerType == _allValue ? null : _selectedPayerType;
      provider.setPayerTypeFilter(payerType);
    }

    if (_selectedPaymentMethod != provider.selectedPaymentMethod) {
      final paymentMethod = _selectedPaymentMethod == _allValue ? null : _selectedPaymentMethod;
      provider.setPaymentMethodFilter(paymentMethod);
    }

    if (_dateFrom != provider.dateFrom || _dateTo != provider.dateTo) {
      provider.setDateRangeFilter(_dateFrom, _dateTo);
    }

    if (_paymentMonthFrom != provider.paymentMonthFrom || _paymentMonthTo != provider.paymentMonthTo) {
      provider.setPaymentMonthRangeFilter(_paymentMonthFrom, _paymentMonthTo);
    }

    final minAmount = _minAmountController.text.trim().isEmpty ? null : double.tryParse(_minAmountController.text.trim());
    final maxAmount = _maxAmountController.text.trim().isEmpty ? null : double.tryParse(_maxAmountController.text.trim());

    if (minAmount != provider.minAmount || maxAmount != provider.maxAmount) {
      provider.setAmountRangeFilter(minAmount, maxAmount);
    }

    if (_hasReceipt != provider.hasReceipt) {
      provider.setReceiptFilter(_hasReceipt);
    }

    if (_isFinalPayment != provider.isFinalPayment) {
      provider.setFinalPaymentFilter(_isFinalPayment);
    }

    if (_sortBy != provider.sortBy || _sortAscending != provider.sortAscending) {
      provider.setSortOptions(_sortBy, _sortAscending);
    }

    if (_showInactive != provider.showInactive) {
      provider.setShowInactiveFilter(_showInactive);
    }

    _handleClose();
  }

  void _handleClearFilters() {
    final provider = context.read<PaymentProvider>();
    provider.resetFilters();

    setState(() {
      _selectedLaborId = _allValue;
      _selectedPayerType = _allValue;
      _selectedPaymentMethod = _allValue;
      _dateFrom = null;
      _dateTo = null;
      _paymentMonthFrom = null;
      _paymentMonthTo = null;
      _minAmount = null;
      _maxAmount = null;
      _hasReceipt = null;
      _isFinalPayment = null;
      _sortBy = 'date';
      _sortAscending = false;
      _showInactive = false;
      _searchQuery = '';
      _searchController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
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
          Icon(Icons.filter_list_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Text(
              l10n.paymentFilters,
              style: TextStyle(
                fontSize: context.headerFontSize,
                fontWeight: FontWeight.w700,
                color: AppTheme.pureWhite,
                letterSpacing: -0.5,
              ),
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
            _buildEntitySection(),
            SizedBox(height: context.cardPadding),
            _buildPaymentDetailsSection(),
            SizedBox(height: context.cardPadding),
            _buildDateRangeSection(),
            SizedBox(height: context.cardPadding),
            _buildAmountRangeSection(),
            SizedBox(height: context.cardPadding),
            _buildSortingSection(),
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
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.search,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          TextField(
            controller: _searchController,
            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
            decoration: InputDecoration(
              hintText: l10n.searchByLaborVendorDescription,
              hintStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.borderRadius()),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.borderRadius()),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.borderRadius()),
                borderSide: BorderSide(color: AppTheme.primaryMaroon, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntitySection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.entityFilters,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.labor,
                  hint: l10n.selectLabor,
                  items: [
                    DropdownItem<String>(value: _allValue, label: l10n.allLabors),
                    ...context.read<PaymentProvider>().laborers.map((labor) => DropdownItem<String>(value: labor.id, label: labor.name)),
                  ],
                  value: _selectedLaborId,
                  onChanged: (value) => setState(() => _selectedLaborId = value),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.payerType,
                  hint: l10n.selectPayerType,
                  items: [
                    DropdownItem<String>(value: _allValue, label: l10n.allTypes),
                    ...PaymentProvider.staticPayerTypes.map((type) => DropdownItem<String>(value: type, label: type.replaceAll('_', ' '))),
                  ],
                  value: _selectedPayerType,
                  onChanged: (value) => setState(() => _selectedPayerType = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.paymentDetails,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.paymentMethod,
                  hint: l10n.selectPaymentMethod,
                  items: [
                    DropdownItem<String>(value: _allValue, label: l10n.allMethods),
                    ...PaymentProvider.staticPaymentMethods.map((method) => DropdownItem<String>(value: method, label: method.replaceAll('_', ' '))),
                  ],
                  value: _selectedPaymentMethod,
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.finalPayment,
                  hint: l10n.selectFinalPaymentStatus,
                  items: [
                    DropdownItem<String>(value: _allValue, label: l10n.all),
                    DropdownItem<String>(value: 'true', label: l10n.finalOnly),
                    DropdownItem<String>(value: 'false', label: l10n.partialOnly),
                  ],
                  value: _isFinalPayment?.toString() ?? _allValue,
                  onChanged: (value) => setState(() => _isFinalPayment = value == _allValue ? null : value == 'true'),
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.hasReceipt,
                  hint: l10n.selectReceiptStatus,
                  items: [
                    DropdownItem<String>(value: _allValue, label: l10n.all),
                    DropdownItem<String>(value: 'true', label: l10n.withReceipt),
                    DropdownItem<String>(value: 'false', label: l10n.withoutReceipt),
                  ],
                  value: _hasReceipt?.toString() ?? _allValue,
                  onChanged: (value) => setState(() => _hasReceipt = value == _allValue ? null : value == 'true'),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.showInactive,
                  hint: l10n.selectVisibility,
                  items: [
                    DropdownItem<String>(value: 'true', label: l10n.showAll),
                    DropdownItem<String>(value: 'false', label: l10n.activeOnly),
                  ],
                  value: _showInactive.toString(),
                  onChanged: (value) => setState(() => _showInactive = value == 'true'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.dateRanges,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: l10n.paymentDateFrom,
                  selectedDate: _dateFrom,
                  onDateSelected: (date) => setState(() => _dateFrom = date),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: _buildDatePicker(
                  label: l10n.paymentDateTo,
                  selectedDate: _dateTo,
                  onDateSelected: (date) => setState(() => _dateTo = date),
                  firstDate: DateTime(2020),
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
                  label: l10n.paymentMonthFrom,
                  selectedDate: _paymentMonthFrom,
                  onDateSelected: (date) => setState(() => _paymentMonthFrom = date),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: _buildDatePicker(
                  label: l10n.paymentMonthTo,
                  selectedDate: _paymentMonthTo,
                  onDateSelected: (date) => setState(() => _paymentMonthTo = date),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRangeSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.amountRangePkr,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAmountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
                  decoration: InputDecoration(
                    labelText: l10n.minimumAmount,
                    labelStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      borderSide: BorderSide(color: AppTheme.primaryMaroon, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
                  ),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: TextField(
                  controller: _maxAmountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
                  decoration: InputDecoration(
                    labelText: l10n.maximumAmount,
                    labelStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      borderSide: BorderSide(color: AppTheme.primaryMaroon, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortingSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sort_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.sortOptions,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.sortBy,
                  hint: l10n.selectSortField,
                  items: [
                    DropdownItem<String>(value: 'date', label: l10n.paymentDate),
                    DropdownItem<String>(value: 'amount', label: l10n.amount),
                    DropdownItem<String>(value: 'labor_name', label: l10n.laborName),
                    DropdownItem<String>(value: 'created_at', label: l10n.createdDate),
                  ],
                  value: _sortBy,
                  onChanged: (value) => setState(() => _sortBy = value ?? 'date'),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.order,
                  hint: l10n.selectSortOrder,
                  items: [
                    DropdownItem<String>(value: 'desc', label: l10n.descending),
                    DropdownItem<String>(value: 'asc', label: l10n.ascending),
                  ],
                  value: _sortAscending ? 'asc' : 'desc',
                  onChanged: (value) => setState(() => _sortAscending = value == 'asc'),
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
                if (selectedDate != null)
                  InkWell(
                    onTap: () => onDateSelected(null),
                    child: Icon(Icons.clear, color: Colors.grey.shade400, size: 16),
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
