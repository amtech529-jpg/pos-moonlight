import 'package:flutter/material.dart';
import 'package:frontend/presentation/widgets/globals/custom_date_picker.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/profit_loss/profit_loss_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ProfitLossPeriodSelector extends StatelessWidget {
  const ProfitLossPeriodSelector({super.key});

  Future<void> _showCustomDatePicker(BuildContext context, ProfitLossProvider provider) async {
    await _showCustomDateRangeDialog(context, provider);
  }

  Future<void> _showCustomDateRangeDialog(BuildContext context, ProfitLossProvider provider) async {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CustomDateRangeDialog(
        initialStartDate: provider.customStartDate,
        initialEndDate: provider.customEndDate,
        onDateRangeSelected: (start, end) async {
          provider.setCustomDateRange(start, end);
          await provider.calculateProfitLoss(startDate: start, endDate: end, periodType: 'custom');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfitLossProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(context.cardPadding / 2),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: context.shadowBlur(),
                offset: Offset(0, context.smallPadding),
              ),
            ],
          ),
          child: ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildTabletLayout(context, provider),
            small: _buildMobileLayout(context, provider),
            medium: _buildDesktopLayout(context, provider),
            large: _buildDesktopLayout(context, provider),
            ultrawide: _buildDesktopLayout(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.availablePeriodTypes.map((period) {
                final isSelected = provider.selectedPeriodType == period;
                return Padding(
                  padding: EdgeInsets.only(right: context.smallPadding),
                  child: _buildPeriodButton(context, provider, period, isSelected),
                );
              }).toList(),
            ),
          ),
        ),
        if (provider.selectedPeriodType == 'custom') ...[
          SizedBox(width: context.cardPadding),
          GestureDetector(
            onTap: () => _showCustomDatePicker(context, provider),
            child: Container(
              padding: EdgeInsets.all(context.cardPadding / 1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryMaroon.withOpacity(0.1), AppTheme.primaryMaroon.withOpacity(0.05)],
                ),
                border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(context.borderRadius()),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        color: AppTheme.primaryMaroon,
                        size: context.iconSize('medium'),
                      ),
                      SizedBox(width: context.smallPadding),
                      Text(
                        l10n.selectDateRange,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryMaroon,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.smallPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            l10n.from,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.charcoalGray.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '${provider.customStartDate.day}/${provider.customStartDate.month}/${provider.customStartDate.year}',
                            style: TextStyle(
                              fontSize: context.subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.grey.shade400,
                        size: context.iconSize('small'),
                      ),
                      SizedBox(width: 10),
                      Column(
                        children: [
                          Text(
                            l10n.to,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.charcoalGray.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '${provider.customEndDate.day}/${provider.customEndDate.month}/${provider.customEndDate.year}',
                            style: TextStyle(
                              fontSize: context.subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, ProfitLossProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: provider.availablePeriodTypes.map((period) {
              final isSelected = provider.selectedPeriodType == period;
              return Padding(
                padding: EdgeInsets.only(right: context.smallPadding),
                child: _buildPeriodButton(context, provider, period, isSelected),
              );
            }).toList(),
          ),
        ),
        if (provider.selectedPeriodType == 'custom') ...[
          SizedBox(height: context.cardPadding),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _showCustomDatePicker(context, provider),
              child: Container(
                padding: EdgeInsets.all(context.cardPadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryMaroon.withOpacity(0.1),
                      AppTheme.primaryMaroon.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          color: AppTheme.primaryMaroon,
                          size: context.iconSize('medium'),
                        ),
                        SizedBox(width: context.smallPadding),
                        Text(
                          l10n.selectDateRange,
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryMaroon,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.smallPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              l10n.from,
                              style: TextStyle(
                                fontSize: context.captionFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.charcoalGray.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '${provider.customStartDate.day}/${provider.customStartDate.month}/${provider.customEndDate.year}',
                              style: TextStyle(
                                fontSize: context.subtitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.charcoalGray,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.grey.shade400,
                          size: context.iconSize('small'),
                        ),
                        Column(
                          children: [
                            Text(
                              l10n.to,
                              style: TextStyle(
                                fontSize: context.captionFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.charcoalGray.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '${provider.customEndDate.day}/${provider.customEndDate.month}/${provider.customEndDate.year}',
                              style: TextStyle(
                                fontSize: context.subtitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.charcoalGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ProfitLossProvider provider) {
    return _buildTabletLayout(context, provider);
  }

  Widget _buildPeriodButton(
      BuildContext context,
      ProfitLossProvider provider,
      String period,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () => provider.setPeriodType(period),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryMaroon : Colors.transparent,
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          border: Border.all(color: isSelected ? AppTheme.primaryMaroon : Colors.grey.shade300, width: 1),
        ),
        child: Text(
          _getPeriodDisplayName(context, period),
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.pureWhite : AppTheme.charcoalGray,
          ),
        ),
      ),
    );
  }

  String _getPeriodDisplayName(BuildContext context, String period) {
    final l10n = AppLocalizations.of(context)!;

    switch (period) {
      case 'daily':
        return l10n.daily;
      case 'weekly':
        return l10n.weekly;
      case 'monthly':
        return l10n.monthly;
      case 'yearly':
        return l10n.yearly;
      case 'custom':
        return l10n.custom;
      default:
        return period;
    }
  }
}

class _CustomDateRangeDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime, DateTime) onDateRangeSelected;

  const _CustomDateRangeDialog({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onDateRangeSelected,
  });

  @override
  State<_CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<_CustomDateRangeDialog> with SingleTickerProviderStateMixin {
  late DateTime _startDate;
  late DateTime _endDate;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _startDate,
      initialTime: TimeOfDay.fromDateTime(_startDate),
      title: l10n.selectStartDate,
      minDate: DateTime(2020),
      maxDate: _endDate,
      onDateTimeSelected: (date, time) {
        setState(() {
          _startDate = date;
        });
      },
    );
  }

  Future<void> _selectEndDate() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _endDate,
      initialTime: TimeOfDay.fromDateTime(_endDate),
      title: l10n.selectEndDate,
      minDate: _startDate,
      maxDate: DateTime.now(),
      onDateTimeSelected: (date, time) {
        setState(() {
          _endDate = date;
        });
      },
    );
  }

  void _handleConfirm() {
    widget.onDateRangeSelected(_startDate, _endDate);
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth * 0.8,
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: context.shadowBlur('heavy'),
                      offset: Offset(0, context.cardPadding),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.cardPadding),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(context.borderRadius('large')),
                          topRight: Radius.circular(context.borderRadius('large')),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            color: AppTheme.pureWhite,
                            size: context.iconSize('large'),
                          ),
                          SizedBox(width: context.cardPadding),
                          Expanded(
                            child: Text(
                              l10n.selectDateRange,
                              style: TextStyle(
                                fontSize: context.headerFontSize,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.pureWhite,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _handleCancel,
                            child: Container(
                              padding: EdgeInsets.all(context.smallPadding),
                              child: Icon(
                                Icons.close_rounded,
                                color: AppTheme.pureWhite,
                                size: context.iconSize('medium'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(context.cardPadding),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _selectStartDate,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(context.cardPadding),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(context.borderRadius()),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.green,
                                        size: context.iconSize('medium'),
                                      ),
                                      SizedBox(width: context.smallPadding),
                                      Text(
                                        l10n.startDate,
                                        style: TextStyle(
                                          fontSize: context.bodyFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: context.smallPadding),
                                  Text(
                                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                    style: TextStyle(
                                      fontSize: context.bodyFontSize * 1.2,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.charcoalGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: context.cardPadding),

                          GestureDetector(
                            onTap: _selectEndDate,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(context.cardPadding),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(context.borderRadius()),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_rounded,
                                        color: Colors.red,
                                        size: context.iconSize('medium'),
                                      ),
                                      SizedBox(width: context.smallPadding),
                                      Text(
                                        l10n.endDate,
                                        style: TextStyle(
                                          fontSize: context.bodyFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: context.smallPadding),
                                  Text(
                                    '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                    style: TextStyle(
                                      fontSize: context.bodyFontSize * 1.2,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.charcoalGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: context.mainPadding),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: context.buttonHeight / 1.5,
                                  child: OutlinedButton(
                                    onPressed: _handleCancel,
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
                                      side: BorderSide(color: Colors.grey.shade400),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(context.borderRadius()),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.cancel,
                                      style: TextStyle(
                                        fontSize: context.bodyFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: context.cardPadding),
                              Expanded(
                                child: Container(
                                  height: context.buttonHeight / 1.5,
                                  child: ElevatedButton(
                                    onPressed: _handleConfirm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryMaroon,
                                      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(context.borderRadius()),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.applyRange,
                                      style: TextStyle(
                                        fontSize: context.bodyFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.pureWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
