import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/drop_down.dart'; // PremiumDropdownField & DropdownItem
import '../globals/custom_date_picker.dart'; // SyncfusionDateTimePicker
import '../globals/text_field.dart'; // PremiumTextField
import '../globals/text_button.dart'; // PremiumButton

class CategoryFilter {
  String? status;
  DateTime? startDate;
  DateTime? endDate;
  String? sortBy;

  CategoryFilter({
    this.status, 
    this.startDate, 
    this.endDate,
    this.sortBy
  });
}

class CategoryFilterDialog extends StatefulWidget {
  final CategoryFilter initialFilter;

  const CategoryFilterDialog({super.key, required this.initialFilter});

  @override
  State<CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<CategoryFilterDialog> {
  late CategoryFilter _currentFilter;
  final _statusFocusNode = FocusNode();
  final _sortFocusNode = FocusNode();
  final _startDateFocusNode = FocusNode();
  final _endDateFocusNode = FocusNode();
  final _applyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Clone the initial filter to avoid direct mutation
    _currentFilter = CategoryFilter(
      status: widget.initialFilter.status,
      startDate: widget.initialFilter.startDate,
      endDate: widget.initialFilter.endDate,
      sortBy: widget.initialFilter.sortBy,
    );

    // Add listeners to rebuild on focus
    _statusFocusNode.addListener(() => setState(() {}));
    _sortFocusNode.addListener(() => setState(() {}));
    _startDateFocusNode.addListener(() => setState(() {}));
    _endDateFocusNode.addListener(() => setState(() {}));
    _applyFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _statusFocusNode.dispose();
    _sortFocusNode.dispose();
    _startDateFocusNode.dispose();
    _endDateFocusNode.dispose();
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
                  l10n.filter ?? "Filter Categories",
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

            // Status Selection
            PremiumDropdownField(
              label: l10n.status ?? "Status",
              hint: l10n.selectStatus ?? "Select Status",
              value: _currentFilter.status,
              focusNode: _statusFocusNode,
              items: [
                DropdownItem(value: '', label: 'All Status'),
                DropdownItem(value: 'active', label: 'Active'),
                DropdownItem(value: 'inactive', label: 'Inactive'),
              ],
              onChanged: (value) {
                setState(() {
                  _currentFilter.status = value?.isEmpty == true ? null : value;
                });
                FocusScope.of(context).requestFocus(_sortFocusNode);
              },
            ),

            SizedBox(height: context.cardPadding),

            // Sort By Selection
            PremiumDropdownField(
              label: "Sort By",
              hint: "Select Sort Option",
              value: _currentFilter.sortBy,
              focusNode: _sortFocusNode,
              items: [
                DropdownItem(value: '', label: 'Default'),
                DropdownItem(value: 'name_asc', label: 'Name (A-Z)'),
                DropdownItem(value: 'name_desc', label: 'Name (Z-A)'),
                DropdownItem(value: 'created_desc', label: 'Newest First'),
                DropdownItem(value: 'created_asc', label: 'Oldest First'),
                DropdownItem(value: 'updated_desc', label: 'Recently Updated'),
              ],
              onChanged: (value) {
                setState(() {
                  _currentFilter.sortBy = value?.isEmpty == true ? null : value;
                });
                FocusScope.of(context).requestFocus(_startDateFocusNode);
              },
            ),

            SizedBox(height: context.cardPadding),

            // Date Range
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: l10n.startDate ?? "Start Date",
                    focusNode: _startDateFocusNode,
                    date: _currentFilter.startDate,
                    onSelected: (date) {
                      setState(() {
                        _currentFilter.startDate = date;
                      });
                      FocusScope.of(context).requestFocus(_endDateFocusNode);
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: l10n.endDate ?? "End Date",
                    focusNode: _endDateFocusNode,
                    date: _currentFilter.endDate,
                    onSelected: (date) {
                      setState(() {
                        _currentFilter.endDate = date;
                      });
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
                      _currentFilter = CategoryFilter();
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
            title: label,
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
            title: label,
            onDateTimeSelected: (selectedDate, _) => onSelected(selectedDate),
          );
        },
        child: AbsorbPointer(
          child: PremiumTextField(
            label: label,
            controller: TextEditingController(
              text: date != null ? "${date.day}-${date.month}-${date.year}" : "",
            ),
            prefixIcon: Icons.calendar_today_rounded,
            hint: "Select date",
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
