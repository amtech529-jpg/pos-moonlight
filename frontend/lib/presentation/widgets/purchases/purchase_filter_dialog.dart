import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _vendorFocusNode = FocusNode();
  final _fromDateFocusNode = FocusNode();
  final _toDateFocusNode = FocusNode();
  final _applyFocusNode = FocusNode();

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

    // Add listeners to rebuild on focus for visual feedback
    _vendorFocusNode.addListener(() => setState(() {}));
    _fromDateFocusNode.addListener(() => setState(() {}));
    _toDateFocusNode.addListener(() => setState(() {}));
    _applyFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _vendorFocusNode.dispose();
    _fromDateFocusNode.dispose();
    _toDateFocusNode.dispose();
    _applyFocusNode.dispose();
    super.dispose();
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
        constraints: const BoxConstraints(maxWidth: 500),
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
                    label: v.businessName.isNotEmpty ? v.businessName : v.name,
                  )).toList(),
                  hint: "All Companies",
                  focusNode: _vendorFocusNode,
                  onChanged: (val) {
                    setState(() => _currentFilter.vendorId = val);
                    FocusScope.of(context).requestFocus(_fromDateFocusNode);
                  },
                );
              },
            ),
            SizedBox(height: context.mainPadding),



            // Date Range Selection
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: "From Date",
                    focusNode: _fromDateFocusNode,
                    date: _currentFilter.startDate,
                    onSelected: (date) {
                      setState(() => _currentFilter.startDate = date);
                      FocusScope.of(context).requestFocus(_toDateFocusNode);
                    },
                  ),
                ),
                SizedBox(width: context.mainPadding),
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: "To Date",
                    focusNode: _toDateFocusNode,
                    date: _currentFilter.endDate,
                    onSelected: (date) {
                      setState(() => _currentFilter.endDate = date);
                      FocusScope.of(context).requestFocus(_applyFocusNode);
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
                  backgroundColor: Colors.black,
                  textColor: Colors.black,
                  width: 100,
                  height: 40,
                ),
                SizedBox(width: context.smallPadding),
                PremiumButton(
                  text: l10n.apply ?? "Apply",
                  onPressed: () => Navigator.pop(context, _currentFilter),
                  backgroundColor: AppTheme.primaryMaroon,
                  focusNode: _applyFocusNode,
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
        required FocusNode focusNode,
        required Function(DateTime) onSelected,
      }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
          context.showSyncfusionDateTimePicker(
            initialDate: date ?? DateTime.now(),
            initialTime: TimeOfDay.now(),
            onDateTimeSelected: (selectedDate, _) => onSelected(selectedDate),
          );
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          context.showSyncfusionDateTimePicker(
            initialDate: date ?? DateTime.now(),
            initialTime: TimeOfDay.now(),
            onDateTimeSelected: (selectedDate, _) => onSelected(selectedDate),
          );
        },
        child: AbsorbPointer(
          child: PremiumTextField(
            label: label,
            controller: TextEditingController(
              text: date != null ? "${date.day}/${date.month}/${date.year}" : "",
            ),
            prefixIcon: Icons.calendar_month_rounded,
            hint: "Select Date",
            // Visual indicator for focus
            containerDecoration: focusNode.hasFocus 
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                )
              : null,
          ),
        ),
      ),
    );
  }
}