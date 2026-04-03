import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/drop_down.dart'; // PremiumDropdownField & DropdownItem
import '../globals/custom_date_picker.dart'; // SyncfusionDateTimePicker
import '../globals/text_field.dart'; // PremiumTextField
import '../globals/text_button.dart'; // PremiumButton

class PurchaseFilter {
  String? vendorId;
  String? status;
  DateTime? startDate;
  DateTime? endDate;
  String? searchQuery;

  PurchaseFilter({this.vendorId, this.status, this.startDate, this.endDate, this.searchQuery});
}

class PurchaseFilterDialog extends StatefulWidget {
  final PurchaseFilter initialFilter;

  const PurchaseFilterDialog({super.key, required this.initialFilter});

  @override
  State<PurchaseFilterDialog> createState() => _PurchaseFilterDialogState();
}

class _PurchaseFilterDialogState extends State<PurchaseFilterDialog> {
  late PurchaseFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    // Clone the initial filter to avoid direct mutation
    _currentFilter = PurchaseFilter(
      vendorId: widget.initialFilter.vendorId,
      status: widget.initialFilter.status,
      startDate: widget.initialFilter.startDate,
      endDate: widget.initialFilter.endDate,
      searchQuery: widget.initialFilter.searchQuery,
    );

    Future.microtask(() => context.read<VendorProvider>().initialize());
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
        width: 50.w, // Increased width for larger fonts
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
                  l10n.filter ?? "Filter Purchases",
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

            // Vendor Selection
            Consumer<VendorProvider>(
              builder: (context, provider, child) {
                return PremiumDropdownField<String>(
                  label: l10n.vendor,
                  value: _currentFilter.vendorId,
                  items: provider.vendors.map((v) => DropdownItem<String>(
                    value: v.id!,
                    label: v.name,
                  )).toList(),
                  onChanged: (val) => setState(() => _currentFilter.vendorId = val),
                  hint: "All Vendors",
                );
              },
            ),
            SizedBox(height: context.mainPadding),

            // Status Selection
            PremiumDropdownField<String>(
              label: "Status",
              value: _currentFilter.status,
              items: [
                DropdownItem(value: 'draft', label: "Draft"),
                DropdownItem(value: 'posted', label: "Posted"),
              ],
              onChanged: (val) => setState(() => _currentFilter.status = val),
              hint: "All Statuses",
            ),
            SizedBox(height: context.mainPadding),

            // Date Range Selection
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: "From Date",
                    date: _currentFilter.startDate,
                    onSelected: (date) => setState(() => _currentFilter.startDate = date),
                  ),
                ),
                SizedBox(width: context.mainPadding),
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: "To Date",
                    date: _currentFilter.endDate,
                    onSelected: (date) => setState(() => _currentFilter.endDate = date),
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
                      _currentFilter = PurchaseFilter();
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
        context.showSyncfusionDateTimePicker(
          initialDate: date ?? DateTime.now(),
          initialTime: TimeOfDay.now(),
          onDateTimeSelected: (selectedDate, _) => onSelected(selectedDate),
        );
      },
      child: IgnorePointer(
        child: PremiumTextField(
          label: label,
          controller: TextEditingController(
            text: date != null ? "${date.day}/${date.month}/${date.year}" : "",
          ),
          prefixIcon: Icons.calendar_month_rounded,
          hint: "Select Date",
        ),
      ),
    );
  }
}