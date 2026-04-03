import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/providers/tax_rates_provider.dart';
import '../../../src/theme/app_theme.dart';

class TaxConfigurationWidget extends StatefulWidget {
  final TaxConfiguration? initialConfiguration;
  final Function(TaxConfiguration) onConfigurationChanged;
  final bool isEditable;

  const TaxConfigurationWidget({super.key, this.initialConfiguration, required this.onConfigurationChanged, this.isEditable = true});

  @override
  State<TaxConfigurationWidget> createState() => _TaxConfigurationWidgetState();
}

class _TaxConfigurationWidgetState extends State<TaxConfigurationWidget> {
  late TaxConfiguration _taxConfiguration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taxConfiguration = widget.initialConfiguration ?? TaxConfiguration();
    _loadDefaultTaxRates();
  }

  Future<void> _loadDefaultTaxRates() async {
    if (!widget.isEditable) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<TaxRatesProvider>();
      await provider.loadActiveTaxRates();

      if (provider.activeTaxRates.isNotEmpty && _taxConfiguration.taxes.isEmpty) {
        _updateTaxConfigurationFromRates(provider.activeTaxRates);
      }
    } catch (e) {
      // Handle error silently for now
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateTaxConfigurationFromRates(List<TaxRateModel> rates) {
    final Map<String, TaxConfigItem> newTaxes = {};

    for (final rate in rates) {
      newTaxes[rate.taxType] = TaxConfigItem(
        name: rate.name,
        percentage: rate.percentage,
        amount: 0.0,
        description: rate.description,
      );
    }

    setState(() {
      _taxConfiguration = TaxConfiguration(taxes: newTaxes);
    });

    widget.onConfigurationChanged(_taxConfiguration);
  }

  void _updateTaxAmount(String taxType, double amount) {
    if (!widget.isEditable) return;

    final currentTaxes = Map<String, TaxConfigItem>.from(_taxConfiguration.taxes);
    if (currentTaxes.containsKey(taxType)) {
      currentTaxes[taxType] = currentTaxes[taxType]!.copyWith(amount: amount);
    }

    setState(() {
      _taxConfiguration = TaxConfiguration(taxes: currentTaxes);
    });

    widget.onConfigurationChanged(_taxConfiguration);
  }

  void _toggleTax(String taxType, bool enabled) {
    if (!widget.isEditable) return;

    final currentTaxes = Map<String, TaxConfigItem>.from(_taxConfiguration.taxes);

    if (enabled) {
      if (!currentTaxes.containsKey(taxType)) {
        final provider = context.read<TaxRatesProvider>();
        final rate = provider.getActiveTaxRateByType(taxType);
        if (rate != null) {
          currentTaxes[taxType] = TaxConfigItem(name: rate.name, percentage: rate.percentage, amount: 0.0, description: rate.description);
        }
      }
    } else {
      currentTaxes.remove(taxType);
    }

    setState(() {
      _taxConfiguration = TaxConfiguration(taxes: currentTaxes);
    });

    widget.onConfigurationChanged(_taxConfiguration);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('medium')),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), if (_isLoading) _buildLoadingState(), if (!_isLoading) _buildTaxConfiguration(), _buildSummary()],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('medium')),
          topRight: Radius.circular(context.borderRadius('medium')),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              l10n.taxConfiguration,
              style: TextStyle(fontSize: context.headingFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            ),
          ),
          if (widget.isEditable)
            IconButton(
              onPressed: _loadDefaultTaxRates,
              icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('small')),
              tooltip: l10n.refreshTaxRates,
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      child: Center(
        child: SizedBox(
          width: 4.w,
          height: 4.w,
          child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildTaxConfiguration() {
    return Consumer<TaxRatesProvider>(
      builder: (context, provider, child) {
        if (provider.activeTaxRates.isEmpty) {
          return _buildNoTaxRatesState();
        }

        return Column(
          children: [...provider.activeTaxRates.map((rate) => _buildTaxItem(rate)), if (widget.isEditable) _buildAddCustomTaxButton(provider)],
        );
      },
    );
  }

  Widget _buildNoTaxRatesState() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: AppTheme.lightGray, size: 8.w),
            SizedBox(height: context.smallPadding),
            Text(
              l10n.noTaxRatesAvailable,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.lightGray),
            ),
            SizedBox(height: context.smallPadding / 2),
            Text(
              l10n.contactAdministratorToSetupTaxRates,
              style: TextStyle(fontSize: context.captionFontSize, color: AppTheme.lightGray.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxItem(TaxRateModel rate) {
    final l10n = AppLocalizations.of(context)!;
    final isEnabled = _taxConfiguration.taxes.containsKey(rate.taxType);
    final taxItem = _taxConfiguration.taxes[rate.taxType];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding / 2),
      decoration: BoxDecoration(
        color: isEnabled ? AppTheme.creamWhite : AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: isEnabled ? AppTheme.primaryMaroon.withOpacity(0.2) : Colors.transparent, width: 1),
      ),
      child: Column(
        children: [
          // Tax Header
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: isEnabled ? AppTheme.primaryMaroon.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.borderRadius('small')),
                topRight: Radius.circular(context.borderRadius('small')),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rate.name,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? AppTheme.primaryMaroon : AppTheme.lightGray,
                        ),
                      ),
                      Text(
                        rate.taxTypeDisplay,
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          color: isEnabled ? AppTheme.primaryMaroon.withOpacity(0.7) : AppTheme.lightGray,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isEditable)
                  Switch(value: isEnabled, onChanged: (value) => _toggleTax(rate.taxType, value), activeColor: AppTheme.primaryMaroon),
              ],
            ),
          ),

          // Tax Details
          if (isEnabled)
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.rate}: ${rate.percentage.toStringAsFixed(2)}%',
                          style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
                        ),
                      ),
                      if (rate.description?.isNotEmpty == true)
                        Expanded(
                          child: Text(
                            rate.description!,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              color: AppTheme.charcoalGray.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.smallPadding),
                  _buildAmountInput(l10n, rate.taxType, taxItem?.amount ?? 0.0),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(AppLocalizations l10n, String taxType, double amount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${l10n.amount}:',
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
          ),
        ),
        SizedBox(width: context.smallPadding),
        Expanded(
          child: TextFormField(
            initialValue: amount.toStringAsFixed(2),
            enabled: widget.isEditable,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'Rs. ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                borderSide: BorderSide(color: AppTheme.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                borderSide: BorderSide(color: AppTheme.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                borderSide: BorderSide(color: AppTheme.primaryMaroon),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
            ),
            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
            onChanged: (value) {
              final newAmount = double.tryParse(value) ?? 0.0;
              _updateTaxAmount(taxType, newAmount);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddCustomTaxButton(TaxRatesProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.all(context.cardPadding),
      child: OutlinedButton.icon(
        onPressed: () => _showAddCustomTaxDialog(provider),
        icon: Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('small')),
        label: Text(
          l10n.addCustomTax,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.primaryMaroon),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.primaryMaroon),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius('small'))),
          padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(context.borderRadius('medium')),
          bottomRight: Radius.circular(context.borderRadius('medium')),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.totalTaxAmount}:',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              Text(
                'Rs. ${_taxConfiguration.totalTaxAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: AppTheme.primaryMaroon),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.totalTaxPercentage}:',
                style: TextStyle(fontSize: context.captionFontSize, color: AppTheme.charcoalGray.withOpacity(0.7)),
              ),
              Text(
                '${_taxConfiguration.totalTaxPercentage.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCustomTaxDialog(TaxRatesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _AddCustomTaxDialog(
        onTaxAdded: (name, percentage, description) {
          final customTaxType = 'CUSTOM_${DateTime.now().millisecondsSinceEpoch}';
          final currentTaxes = Map<String, TaxConfigItem>.from(_taxConfiguration.taxes);

          currentTaxes[customTaxType] = TaxConfigItem(name: name, percentage: percentage, amount: 0.0, description: description);

          setState(() {
            _taxConfiguration = TaxConfiguration(taxes: currentTaxes);
          });

          widget.onConfigurationChanged(_taxConfiguration);
        },
      ),
    );
  }
}

class _AddCustomTaxDialog extends StatefulWidget {
  final Function(String name, double percentage, String? description) onTaxAdded;

  const _AddCustomTaxDialog({required this.onTaxAdded});

  @override
  State<_AddCustomTaxDialog> createState() => _AddCustomTaxDialogState();
}

class _AddCustomTaxDialogState extends State<_AddCustomTaxDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _percentageController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        l10n.addCustomTax,
        style: TextStyle(fontSize: context.headingFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.taxName,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterTaxName;
                }
                return null;
              },
            ),
            SizedBox(height: context.smallPadding),
            TextFormField(
              controller: _percentageController,
              decoration: InputDecoration(
                labelText: l10n.taxPercentage,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterTaxPercentage;
                }
                final percentage = double.tryParse(value!);
                if (percentage == null || percentage < 0 || percentage > 100) {
                  return l10n.pleaseEnterValidPercentage;
                }
                return null;
              },
            ),
            SizedBox(height: context.smallPadding),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: TextStyle(color: AppTheme.charcoalGray)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final name = _nameController.text.trim();
              final percentage = double.parse(_percentageController.text);
              final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

              widget.onTaxAdded(name, percentage, description);
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.addTax, style: TextStyle(color: AppTheme.pureWhite)),
        ),
      ],
    );
  }
}
