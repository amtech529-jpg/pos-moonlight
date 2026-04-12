import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/presentation/widgets/globals/custom_date_picker.dart';
import 'package:frontend/presentation/widgets/globals/drop_down.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/expenses/expenses_model.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/providers/expenses_provider.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';


class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _expenseController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Focus Nodes
  final _expenseFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _categoryFocusNode = FocusNode();
  final _recurringFocusNode = FocusNode();
  final _deductibleFocusNode = FocusNode();
  final _laborFocusNode = FocusNode();
  final _dateFocusNode = FocusNode();
  final _saveFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _isRecurring = false;
  bool _isSalaryDeductible = false;
  String? _selectedLaborId;
  String? _selectedCategory;


  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LaborProvider>().loadLabors();
        _animationController.forward();
      }
    });

    // Add listeners for border updates
    void focusListener() {
      if (mounted) setState(() {});
    }
    _expenseFocusNode.addListener(focusListener);
    _descriptionFocusNode.addListener(focusListener);
    _amountFocusNode.addListener(focusListener);
    _categoryFocusNode.addListener(focusListener);
    _recurringFocusNode.addListener(focusListener);
    _deductibleFocusNode.addListener(focusListener);
    _laborFocusNode.addListener(focusListener);
    _dateFocusNode.addListener(focusListener);
    _saveFocusNode.addListener(focusListener);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _expenseController.dispose();
    _descriptionController.dispose();
    _expenseFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _amountFocusNode.dispose();
    _categoryFocusNode.dispose();
    _recurringFocusNode.dispose();
    _deductibleFocusNode.dispose();
    _laborFocusNode.dispose();
    _dateFocusNode.dispose();
    _saveFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final expensesProvider = Provider.of<ExpensesProvider>(context, listen: false);

      await expensesProvider.addExpense(
        expense: _expenseController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        withdrawalBy: '', // Default value since it's removed from UI
        date: _selectedDate,
        time: _selectedTime,
        isRecurring: _isRecurring,
        isSalaryDeductible: _isSalaryDeductible,
        deductibleLaborId: _isSalaryDeductible ? _selectedLaborId : null,
        category: _selectedCategory,
      );

      if (mounted) {
        _showSuccessSnackbar();
        Navigator.of(context).pop();
      }
    }
  }

  void _showSuccessSnackbar() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.expenseAddedSuccessfully,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              message,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _handleCancel() {
    if (_animationController.isCompleted) {
      _animationController.reverse().then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectDateTime() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _selectedDate,
      initialTime: _selectedTime,
      title: l10n.selectExpenseDateTime,
      minDate: DateTime(2000),
      maxDate: DateTime.now().add(const Duration(days: 365)),
      onDateTimeSelected: (date, time) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
        _saveFocusNode.requestFocus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 90.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
                  maxHeight: 90.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildTabletLayout(),
                  small: _buildMobileLayout(),
                  medium: _buildDesktopLayout(),
                  large: _buildDesktopLayout(),
                  ultrawide: _buildDesktopLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(), _buildFormContent(isCompact: true)]),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(), _buildFormContent(isCompact: true)]),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(), _buildFormContent(isCompact: false)]),
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
            child: Icon(Icons.receipt_long_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.addExpense : l10n.addNewExpense,
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
                    l10n.recordNewExpenseEntry,
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
              onTap: _handleCancel,
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

  Widget _buildFormContent({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumTextField(
              label: l10n.expense,
              hint: isCompact ? l10n.enterExpense : l10n.enterExpenseTypeCategory,
              controller: _expenseController,
              prefixIcon: Icons.category_outlined,
              focusNode: _expenseFocusNode,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_descriptionFocusNode),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterExpenseType;
                }
                if (value!.length < 2) {
                  return l10n.expenseMinLength;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.description,
              hint: isCompact ? l10n.enterDescription : l10n.enterExpenseDescription,
              controller: _descriptionController,
              prefixIcon: Icons.description_outlined,
              focusNode: _descriptionFocusNode,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_amountFocusNode),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterDescription;
                }
                if (value!.length < 5) {
                  return l10n.descriptionMinLength;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.amount,
              hint: isCompact ? l10n.enterAmount : l10n.enterAmountPKR,
              controller: _amountController,
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              focusNode: _amountFocusNode,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _categoryFocusNode.requestFocus(),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterAmount;
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return l10n.pleaseEnterValidAmount;
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            PremiumDropdownField<String>(
              focusNode: _categoryFocusNode,
              label: l10n.expenseCategory,
              hint: l10n.selectCategory,
              value: _selectedCategory,
              prefixIcon: Icons.category_rounded,
              items: ExpensesProvider.expenseCategories.map((category) => DropdownItem<String>(value: category, label: category)).toList(),
              onChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });
                _recurringFocusNode.requestFocus();
              },
              validator: (value) {
                if (value == null) {
                  return l10n.pleaseSelectCategory;
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            Focus(
              focusNode: _recurringFocusNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
                  setState(() => _isRecurring = !_isRecurring);
                  _deductibleFocusNode.requestFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (context) {
                  final isFocused = _recurringFocusNode.hasFocus;
                  return Container(
                    decoration: isFocused ? BoxDecoration(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      border: Border.all(color: AppTheme.accentGold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ) : BoxDecoration(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      border: Border.all(color: Colors.transparent, width: 2),
                    ),
                    child: CheckboxListTile(
                      title: Text(l10n.recurringExpense, style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.normal)),
                      value: _isRecurring,
                      activeColor: AppTheme.primaryMaroon,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setState(() {
                          _isRecurring = value ?? false;
                        });
                        _deductibleFocusNode.requestFocus();
                      },
                    ),
                  );
                }
              ),
            ),
            
            // Salary Deductible Checkbox
            Focus(
              focusNode: _deductibleFocusNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
                  setState(() {
                    _isSalaryDeductible = !_isSalaryDeductible;
                    if (!_isSalaryDeductible) _selectedLaborId = null;
                  });
                  if (_isSalaryDeductible) {
                    _laborFocusNode.requestFocus();
                  } else {
                    _dateFocusNode.requestFocus();
                  }
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (context) {
                  final isFocused = _deductibleFocusNode.hasFocus;
                  return Container(
                    decoration: isFocused ? BoxDecoration(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      border: Border.all(color: AppTheme.accentGold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ) : BoxDecoration(
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      border: Border.all(color: Colors.transparent, width: 2),
                    ),
                    child: CheckboxListTile(
                      title: Text(l10n.deductFromSalary, style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.normal)),
                      value: _isSalaryDeductible,
                      activeColor: AppTheme.primaryMaroon,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setState(() {
                          _isSalaryDeductible = value ?? false;
                          if (!_isSalaryDeductible) _selectedLaborId = null;
                        });
                        if (_isSalaryDeductible) {
                          _laborFocusNode.requestFocus();
                        } else {
                          _dateFocusNode.requestFocus();
                        }
                      },
                    ),
                  );
                }
              ),
            ),

            if (_isSalaryDeductible) ...[
              SizedBox(height: context.smallPadding),
              Consumer<LaborProvider>(
                builder: (context, laborProvider, child) {
                  return PremiumDropdownField<String>(
                    focusNode: _laborFocusNode,
                    label: l10n.selectLabor,
                    hint: l10n.selectEmployeeForDeduction,
                    value: _selectedLaborId,
                    prefixIcon: Icons.badge_outlined,
                    items: laborProvider.labors.map((labor) => DropdownItem<String>(
                      value: labor.id, 
                      label: labor.name
                    )).toList(),
                    onChanged: (id) {
                      setState(() {
                        _selectedLaborId = id;
                      });
                      _dateFocusNode.requestFocus();
                    },
                    validator: (value) {
                      if (_isSalaryDeductible && value == null) {
                        return l10n.pleaseSelectALabor;
                      }
                      return null;
                    },
                  );
                },
              ),
              SizedBox(height: context.cardPadding),
            ],


            Focus(
              focusNode: _dateFocusNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  _selectDateTime();
                  _saveFocusNode.requestFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectDateTime,
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      child: Container(
                        padding: EdgeInsets.all(context.cardPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primaryMaroon.withOpacity(0.1), AppTheme.secondaryMaroon.withOpacity(0.1)]),
                          border: Border.all(color: isFocused ? AppTheme.accentGold : AppTheme.primaryMaroon.withOpacity(0.3), width: isFocused ? 2 : 1),
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                          boxShadow: isFocused ? [
                            BoxShadow(color: AppTheme.accentGold.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
                          ] : null,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.date_range_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
                                SizedBox(width: context.smallPadding),
                                Text(
                                  l10n.selectDateTime,
                                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
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
                                      l10n.date,
                                      style: TextStyle(
                                        fontSize: context.subtitleFontSize,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.charcoalGray.withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                      style: TextStyle(
                                        fontSize: context.bodyFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.charcoalGray,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(height: 40, width: 1, color: Colors.grey.shade300),
                                Column(
                                  children: [
                                    Text(
                                      l10n.time,
                                      style: TextStyle(
                                        fontSize: context.subtitleFontSize,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.charcoalGray.withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      _selectedTime.format(context),
                                      style: TextStyle(
                                        fontSize: context.bodyFontSize,
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
                  );
                }
              ),
            ),

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

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<ExpensesProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.addExpense,
              focusNode: _saveFocusNode,
              onPressed: provider.isLoading ? null : _handleSubmit,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.add_rounded,
            );
          },
        ),
        const SizedBox(height: 20),
        PremiumButton(
          text: l10n.cancel,
          onPressed: _handleCancel,
          isOutlined: true,
          height: context.buttonHeight,
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
            onPressed: _handleCancel,
            isOutlined: true,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Consumer<ExpensesProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.addExpense,
                focusNode: _saveFocusNode,
                onPressed: provider.isLoading ? null : _handleSubmit,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.add_rounded,
              );
            },
          ),
        ),
      ],
    );
  }
}
