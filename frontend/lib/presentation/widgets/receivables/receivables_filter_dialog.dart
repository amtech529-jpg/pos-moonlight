import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/drop_down.dart'; // PremiumDropdownField & DropdownItem
import '../globals/custom_date_picker.dart'; // SyncfusionDateTimePicker
import '../globals/text_field.dart'; // PremiumTextField
import '../globals/text_button.dart'; // PremiumButton

class ReceivablesFilter {
  String? customerId;
  String? status;
  DateTime? startDate;
  DateTime? endDate;
  String? amountRange;
  bool? overdueOnly;

  ReceivablesFilter({
    this.customerId, 
    this.status, 
    this.startDate, 
    this.endDate,
    this.amountRange,
    this.overdueOnly
  });
}

class ReceivablesFilterDialog extends StatefulWidget {
  final ReceivablesFilter initialFilter;

  const ReceivablesFilterDialog({super.key, required this.initialFilter});

  @override
  State<ReceivablesFilterDialog> createState() => _ReceivablesFilterDialogState();
}

class _ReceivablesFilterDialogState extends State<ReceivablesFilterDialog> {
  late ReceivablesFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    // Clone the initial filter to avoid direct mutation
    _currentFilter = ReceivablesFilter(
      customerId: widget.initialFilter.customerId,
      status: widget.initialFilter.status,
      startDate: widget.initialFilter.startDate,
      endDate: widget.initialFilter.endDate,
      amountRange: widget.initialFilter.amountRange,
      overdueOnly: widget.initialFilter.overdueOnly,
    );

    Future.microtask(() => context.read<CustomerProvider>().initialize());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
      ),
      backgroundColor: AppTheme.creamWhite,
      child: Container(
        width: 50.w,
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.smallPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: AppTheme.primaryMaroon,
                    size: context.iconSize('medium'),
                  ),
                ),
                SizedBox(width: context.smallPadding),
                Text(
                  l10n.filter ?? "Filter Receivables",
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 32),

            // Customer Selection
            Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                return PremiumDropdownField(
                  label: l10n.customer ?? "Customer",
                  hint: l10n.selectCustomer ?? "Select Customer",
                  value: _currentFilter.customerId,
                  items: [
                    DropdownItem(value: '', label: 'All Customers'),
                    ...provider.customers.map((customer) => DropdownItem(
                      value: customer.id,
                      label: customer.name,
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _currentFilter.customerId = value?.isEmpty == true ? null : value;
                    });
                  },
                );
              },
            ),

            SizedBox(height: context.cardPadding),

            // Status Selection
            PremiumDropdownField(
              label: l10n.status ?? "Status",
              hint: l10n.selectStatus ?? "Select Status",
              value: _currentFilter.status,
              items: [
                DropdownItem(value: '', label: 'All Status'),
                DropdownItem(value: 'pending', label: 'Pending'),
                DropdownItem(value: 'partial', label: 'Partial'),
                DropdownItem(value: 'paid', label: 'Paid'),
                DropdownItem(value: 'overdue', label: 'Overdue'),
              ],
              onChanged: (value) {
                setState(() {
                  _currentFilter.status = value?.isEmpty == true ? null : value;
                });
              },
            ),

            SizedBox(height: context.cardPadding),

            // Amount Range Selection
            PremiumDropdownField(
              label: "Amount Range",
              hint: "Select Amount Range",
              value: _currentFilter.amountRange,
              items: [
                DropdownItem(value: '', label: 'All Amounts'),
                DropdownItem(value: '0-1000', label: 'Rs. 0 - 1,000'),
                DropdownItem(value: '1000-5000', label: 'Rs. 1,000 - 5,000'),
                DropdownItem(value: '5000-10000', label: 'Rs. 5,000 - 10,000'),
                DropdownItem(value: '10000-50000', label: 'Rs. 10,000 - 50,000'),
                DropdownItem(value: '50000+', label: 'Rs. 50,000+'),
              ],
              onChanged: (value) {
                setState(() {
                  _currentFilter.amountRange = value?.isEmpty == true ? null : value;
                });
              },
            ),

            SizedBox(height: context.cardPadding),

            // Overdue Only Checkbox
            Row(
              children: [
                Checkbox(
                  value: _currentFilter.overdueOnly ?? false,
                  onChanged: (value) {
                    setState(() {
                      _currentFilter.overdueOnly = value;
                    });
                  },
                  activeColor: AppTheme.primaryMaroon,
                ),
                SizedBox(width: context.smallPadding),
                Text(
                  "Overdue Only",
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    color: AppTheme.charcoalGray,
                  ),
                ),
              ],
            ),

            SizedBox(height: context.cardPadding),

            // Date Range
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: l10n.startDate ?? "Start Date",
                    date: _currentFilter.startDate,
                    onSelected: (date) {
                      setState(() {
                        _currentFilter.startDate = date;
                      });
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: l10n.endDate ?? "End Date",
                    date: _currentFilter.endDate,
                    onSelected: (date) {
                      setState(() {
                        _currentFilter.endDate = date;
                      });
                    },
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Footer Actions
            Row(
              children: [
                PremiumButton(
                  text: "Reset All",
                  onPressed: () {
                    setState(() {
                      _currentFilter = ReceivablesFilter();
                    });
                  },
                  isOutlined: true,
                  backgroundColor: Colors.grey[600],
                  width: 120,
                  height: 40,
                ),
                const Spacer(),
                PremiumButton(
                  text: l10n.cancel,
                  onPressed: () => Navigator.pop(context),
                  isOutlined: true,
                  backgroundColor: AppTheme.charcoalGray,
                  width: 100,
                  height: 40,
                ),
                SizedBox(width: context.smallPadding),
                PremiumButton(
                  text: l10n.apply ?? "Apply",
                  onPressed: () => Navigator.pop(context, _currentFilter),
                  backgroundColor: AppTheme.primaryMaroon,
                  width: 120,
                  height: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
      BuildContext context, {
        required String label,
        required DateTime? date,
        required Function(DateTime) onSelected,
      }) {
    return InkWell(
      onTap: () {
        showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(Duration(days: 30)),
        ).then((selectedDate) {
          if (selectedDate != null) {
            onSelected(selectedDate);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(context.cardPadding / 1.5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: context.captionFontSize,
                color: AppTheme.charcoalGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: context.smallPadding / 2),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: context.iconSize('small'),
                  color: AppTheme.primaryMaroon,
                ),
                SizedBox(width: context.smallPadding / 2),
                Text(
                  date != null 
                    ? "${date.day}-${date.month}-${date.year}"
                    : "Select date",
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    color: date != null ? AppTheme.charcoalGray : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
