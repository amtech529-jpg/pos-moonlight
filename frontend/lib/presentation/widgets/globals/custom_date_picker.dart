import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';

class SyncfusionDateTimePicker extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay initialTime;
  final Function(DateTime date, TimeOfDay time) onDateTimeSelected;
  final String title;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool showTimeInline;

  const SyncfusionDateTimePicker({
    super.key,
    required this.initialDate,
    required this.initialTime,
    required this.onDateTimeSelected,
    this.title = 'Select Date & Time',
    this.minDate,
    this.maxDate,
    this.showTimeInline = true,
  });

  @override
  State<SyncfusionDateTimePicker> createState() => _SyncfusionDateTimePickerState();
}

class _SyncfusionDateTimePickerState extends State<SyncfusionDateTimePicker> {
  late DateTime _tempSelectedDate;
  late TimeOfDay _tempSelectedTime;

  @override
  void initState() {
    super.initState();
    _tempSelectedDate = widget.initialDate;
    _tempSelectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius('large'))),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveBreakpoints.responsive(
            context,
            tablet: MediaQuery.of(context).size.width * 0.8,
            small: MediaQuery.of(context).size.width * 0.9,
            medium: 500,
            large: 500,
            ultrawide: 500,
          ),
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: SingleChildScrollView(child: _buildContent())),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.cardPadding),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon])),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.date_range_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: SfDateRangePicker(
                initialSelectedDate: _tempSelectedDate,
                initialDisplayDate: _tempSelectedDate,
                minDate: widget.minDate ?? DateTime(2000),
                maxDate: widget.maxDate ?? DateTime.now().add(const Duration(days: 365)),
                selectionMode: DateRangePickerSelectionMode.single,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is DateTime) {
                    setState(() {
                      _tempSelectedDate = args.value as DateTime;
                    });
                  }
                },
                monthCellStyle: DateRangePickerMonthCellStyle(
                  todayTextStyle: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.w600),
                  textStyle: TextStyle(color: AppTheme.charcoalGray),
                  leadingDatesTextStyle: TextStyle(color: Colors.grey.shade400),
                  trailingDatesTextStyle: TextStyle(color: Colors.grey.shade400),
                ),
                selectionColor: AppTheme.primaryMaroon,
                todayHighlightColor: AppTheme.primaryMaroon,
                headerStyle: DateRangePickerHeaderStyle(
                  textAlign: TextAlign.center,
                  textStyle: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                monthViewSettings: const DateRangePickerMonthViewSettings(
                  firstDayOfWeek: 1,
                  showTrailingAndLeadingDates: true,
                ),
                yearCellStyle: DateRangePickerYearCellStyle(
                  textStyle: TextStyle(color: AppTheme.charcoalGray),
                  todayTextStyle: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          if (widget.showTimeInline) ...[SizedBox(height: context.cardPadding), _buildTimeSection()],
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_outlined, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.selectTime,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),

          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.hour,
                        style: TextStyle(
                          fontSize: context.subtitleFontSize,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.charcoalGray.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Container(
                        height: 100,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _tempSelectedTime = TimeOfDay(hour: index, minute: _tempSelectedTime.minute);
                            });
                          },
                          controller: FixedExtentScrollController(initialItem: _tempSelectedTime.hour),
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 24) return null;
                              final isSelected = index == _tempSelectedTime.hour;
                              return Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryMaroon.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(context.borderRadius()),
                                ),
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: context.bodyFontSize,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
                                  ),
                                ),
                              );
                            },
                            childCount: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(width: 1, height: 80, color: Colors.grey.shade300),

                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.minute,
                        style: TextStyle(
                          fontSize: context.subtitleFontSize,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.charcoalGray.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Container(
                        height: 100,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _tempSelectedTime = TimeOfDay(
                                hour: _tempSelectedTime.hour,
                                minute: index * 5,
                              );
                            });
                          },
                          controller: FixedExtentScrollController(initialItem: (_tempSelectedTime.minute / 5).round()),
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 12) return null;
                              final minute = index * 5;
                              final isSelected = minute == _tempSelectedTime.minute;
                              return Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryMaroon.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(context.borderRadius()),
                                ),
                                child: Text(
                                  minute.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: context.bodyFontSize,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
                                  ),
                                ),
                              );
                            },
                            childCount: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.smallPadding),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.selected}: ${_tempSelectedTime.format(context)}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
            ),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: context.bodyFontSize),
            ),
          ),
          SizedBox(width: context.smallPadding),
          ElevatedButton(
            onPressed: () {
              widget.onDateTimeSelected(_tempSelectedDate, _tempSelectedTime);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: AppTheme.pureWhite,
              padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
            ),
            child: Text(
              l10n.confirm,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.bodyFontSize),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTimeDialog() async {
    Navigator.of(context).pop();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _tempSelectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryMaroon,
              onPrimary: AppTheme.pureWhite,
              surface: AppTheme.pureWhite,
              onSurface: AppTheme.charcoalGray,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _tempSelectedTime = picked;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SyncfusionDateTimePicker(
          initialDate: _tempSelectedDate,
          initialTime: _tempSelectedTime,
          onDateTimeSelected: widget.onDateTimeSelected,
          title: widget.title,
          minDate: widget.minDate,
          maxDate: widget.maxDate,
          showTimeInline: widget.showTimeInline,
        );
      },
    );
  }
}

extension SyncfusionDateTimePickerExtension on BuildContext {
  Future<void> showSyncfusionDateTimePicker({
    required DateTime initialDate,
    required TimeOfDay initialTime,
    required Function(DateTime date, TimeOfDay time) onDateTimeSelected,
    String title = 'Select Date & Time',
    DateTime? minDate,
    DateTime? maxDate,
    bool showTimeInline = true,
  }) {
    return showDialog<void>(
      context: this,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SyncfusionDateTimePicker(
          initialDate: initialDate,
          initialTime: initialTime,
          onDateTimeSelected: onDateTimeSelected,
          title: title,
          minDate: minDate,
          maxDate: maxDate,
          showTimeInline: showTimeInline,
        );
      },
    );
  }
}
