import 'package:flutter/material.dart';
import 'package:frontend/presentation/widgets/globals/custom_date_picker.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/prinicipal_acc_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../../../src/models/principal_account/principal_account_model.dart';
import '../../../l10n/app_localizations.dart';

class EditPrincipalAccountDialog extends StatefulWidget {
  final PrincipalAccount account;

  const EditPrincipalAccountDialog({super.key, required this.account});

  @override
  State<EditPrincipalAccountDialog> createState() => _EditPrincipalAccountDialogState();
}

class _EditPrincipalAccountDialogState extends State<EditPrincipalAccountDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _sourceIdController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late String _selectedSourceModule;
  late String _selectedTransactionType;
  String? _selectedHandledBy;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _sourceIdController = TextEditingController(text: widget.account.sourceId ?? '');
    _descriptionController = TextEditingController(text: widget.account.description);
    _amountController = TextEditingController(text: widget.account.amount.toString());
    _notesController = TextEditingController(text: widget.account.notes ?? '');
    _selectedSourceModule = widget.account.sourceModule;
    _selectedTransactionType = widget.account.type;
    _selectedHandledBy = widget.account.handledBy;
    _selectedDate = widget.account.date;
    _selectedTime = widget.account.time;

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sourceIdController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<PrincipalAccountProvider>(context, listen: false);

      final request = PrincipalAccountUpdateRequest(
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        handledBy: _selectedHandledBy,
      );

      await provider.updatePrincipalAccount(widget.account.id, request);

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
              l10n.principalAccountEntryUpdatedSuccessfully,
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
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _selectDateTime() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _selectedDate,
      initialTime: _selectedTime,
      title: l10n.selectTransactionDateTime,
      minDate: DateTime(2000),
      maxDate: DateTime(2101),
      onDateTimeSelected: (date, time) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
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
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 90.w, medium: 80.w, large: 70.w, ultrawide: 60.w),
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
        gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
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
            child: Icon(Icons.edit_outlined, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.editEntry : l10n.editPrincipalAccountEntry,
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
                    l10n.updateTransactionInformation,
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              widget.account.id,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
          SizedBox(width: context.smallPadding),
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
            Consumer<PrincipalAccountProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedSourceModule,
                  decoration: InputDecoration(
                    labelText: l10n.sourceModule,
                    prefixIcon: const Icon(Icons.source_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
                  ),
                  items: provider.availableSourceModules
                      .map(
                        (module) => DropdownMenuItem<String>(
                      value: module,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: _getSourceModuleColor(module), shape: BoxShape.circle),
                            child: Icon(_getSourceModuleIcon(module), color: AppTheme.pureWhite, size: context.iconSize('small')),
                          ),
                          SizedBox(width: context.smallPadding),
                          Text(_getFormattedSourceModule(module)),
                        ],
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (module) {
                    setState(() {
                      _selectedSourceModule = module!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return l10n.pleaseSelectSourceModule;
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            Consumer<PrincipalAccountProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedTransactionType,
                  decoration: InputDecoration(
                    labelText: l10n.transactionType,
                    prefixIcon: const Icon(Icons.swap_horiz_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
                  ),
                  items: provider.availableTransactionTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            type == 'credit' ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: type == 'credit' ? Colors.green : Colors.red,
                            size: context.iconSize('medium'),
                          ),
                          SizedBox(width: context.smallPadding),
                          Text(
                            type == 'credit' ? l10n.creditMoneyIn : l10n.debitMoneyOut,
                            style: TextStyle(color: type == 'credit' ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (type) {
                    setState(() {
                      _selectedTransactionType = type!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return l10n.pleaseSelectTransactionType;
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.sourceID,
              hint: isCompact ? l10n.referenceIDOptional : l10n.referenceIDFromSourceModuleOptional,
              controller: _sourceIdController,
              prefixIcon: Icons.tag_outlined,
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.description,
              hint: isCompact ? l10n.enterDescription : l10n.enterTransactionDescription,
              controller: _descriptionController,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterDescription;
                }
                if (value!.length < 5) {
                  return l10n.descriptionMustBeAtLeast5Characters;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.amount,
              hint: isCompact ? l10n.enterAmount : l10n.enterTransactionAmountPKR,
              controller: _amountController,
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterAmount;
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return l10n.pleaseEnterAValidAmount;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            Consumer<PrincipalAccountProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedHandledBy,
                  decoration: InputDecoration(
                    labelText: l10n.handledByOptional,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
                  ),
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(l10n.notSpecified)),
                    ...provider.availableHandlers.map(
                          (handler) => DropdownMenuItem<String>(
                        value: handler,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(color: _getPersonColor(handler), shape: BoxShape.circle),
                              child: Icon(Icons.person, color: AppTheme.pureWhite, size: context.iconSize('small')),
                            ),
                            SizedBox(width: context.smallPadding),
                            Text(handler),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (handler) {
                    setState(() {
                      _selectedHandledBy = handler;
                    });
                  },
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectDateTime,
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    child: Container(
                      padding: EdgeInsets.all(context.cardPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.1), Colors.blueAccent.withOpacity(0.1)]),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(context.borderRadius()),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.date_range_rounded, color: Colors.blue, size: context.iconSize('medium')),
                              SizedBox(width: context.smallPadding),
                              Text(
                                l10n.selectDateTime,
                                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.blue),
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
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                ),
              ],
            ),

            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.notes,
              hint: isCompact ? l10n.additionalNotesOptional : l10n.additionalNotesOrDetailsOptional,
              controller: _notesController,
              prefixIcon: Icons.note_outlined,
              maxLines: 2,
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
        Consumer<PrincipalAccountProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.updateEntry,
              onPressed: provider.isLoading ? null : _handleUpdate,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.save_rounded,
              backgroundColor: Colors.blue,
            );
          },
        ),
        SizedBox(height: context.cardPadding),
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
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Consumer<PrincipalAccountProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.updateEntry,
                onPressed: provider.isLoading ? null : _handleUpdate,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.save_rounded,
                backgroundColor: Colors.blue,
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getSourceModuleColor(String module) {
    switch (module.toLowerCase()) {
      case 'sales':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'advance_payment':
        return Colors.orange;
      case 'expenses':
        return Colors.red;
      case 'receivables':
        return Colors.purple;
      case 'payables':
        return Colors.brown;
      case 'zakat':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getSourceModuleIcon(String module) {
    switch (module.toLowerCase()) {
      case 'sales':
        return Icons.point_of_sale_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'advance_payment':
        return Icons.schedule_send_rounded;
      case 'expenses':
        return Icons.receipt_long_rounded;
      case 'receivables':
        return Icons.account_balance_outlined;
      case 'payables':
        return Icons.money_off_outlined;
      case 'zakat':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  String _getFormattedSourceModule(String module) {
    switch (module.toLowerCase()) {
      case 'sales':
        return 'Sales';
      case 'payment':
        return 'Payment';
      case 'advance_payment':
        return 'Advance Payment';
      case 'expenses':
        return 'Expenses';
      case 'receivables':
        return 'Receivables';
      case 'payables':
        return 'Payables';
      case 'zakat':
        return 'Zakat';
      default:
        return module;
    }
  }

  Color _getPersonColor(String person) {
    switch (person) {
      case 'Shahzain Baloch':
        return Colors.blue;
      case 'Huzaifa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
