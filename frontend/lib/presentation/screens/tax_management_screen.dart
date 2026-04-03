import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../src/models/sales/sale_model.dart';
import '../../src/providers/auth_provider.dart';
import '../../src/providers/tax_rates_provider.dart';
import '../../src/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/sales/tax_configuration_widget.dart';
import '../../src/services/tax_rates_service.dart';

class TaxManagementScreen extends StatefulWidget {
  const TaxManagementScreen({super.key});

  @override
  State<TaxManagementScreen> createState() => _TaxManagementScreenState();
}

class _TaxManagementScreenState extends State<TaxManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaxRatesProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('TaxManagement', 'add') ?? true;
    final bool canEdit = currentUser?.canPerform('TaxManagement', 'edit') ?? true;
    final bool canDelete = currentUser?.canPerform('TaxManagement', 'delete') ?? true;

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: _buildMainContent(canAdd, canEdit, canDelete),
    );
  }

  Widget _buildMainContent(bool canAdd, bool canEdit, bool canDelete) {
    return Column(
      children: [
        _buildHeader(canAdd),
        Expanded(child: _buildContent(canEdit, canDelete)),
      ],
    );
  }

  Widget _buildHeader(bool canAdd) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: context.pagePadding,
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        boxShadow: [BoxShadow(color: AppTheme.shadowColor, blurRadius: context.shadowBlur('light'), offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('large')),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.taxManagement,
                  style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                ),
                Text(
                  l10n.taxManagementDescription,
                  style: TextStyle(fontSize: context.subtitleFontSize, color: AppTheme.charcoalGray.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          _buildHeaderActions(canAdd),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(bool canAdd) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _buildSearchField(),
        if (canAdd) ...[
          SizedBox(width: context.cardPadding),
          ElevatedButton.icon(
            onPressed: () => _showAddTaxRateDialog(),
            icon: Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('small')),
            label: Text(
              l10n.addTaxRate,
              style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchField() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 300,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.searchTaxRatesHint,
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.charcoalGray.withOpacity(0.5)),
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
          contentPadding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding),
        ),
        onChanged: (value) {
          context.read<TaxRatesProvider>().searchTaxRates(value);
        },
      ),
    );
  }

  Widget _buildContent(bool canEdit, bool canDelete) {
    return Container(
      padding: context.pagePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildTaxRatesList(canEdit, canDelete)),
          SizedBox(width: context.cardPadding),
          Expanded(flex: 1, child: _buildTaxConfiguration()),
        ],
      ),
    );
  }

  Widget _buildTaxRatesList(bool canEdit, bool canDelete) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('medium')),
        boxShadow: [BoxShadow(color: AppTheme.shadowColor, blurRadius: context.shadowBlur(), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeader(),
          Expanded(child: _buildTaxRatesTable(canEdit, canDelete)),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
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
          Text(
            l10n.taxRates,
            style: TextStyle(fontSize: context.headingFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          const Spacer(),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<TaxRatesProvider>(
      builder: (context, provider, child) {
        return Wrap(
          spacing: context.smallPadding,
          children: [
            FilterChip(
              label: Text(l10n.all),
              selected: provider.taxTypeFilter == null && provider.isActiveFilter == null,
              onSelected: (selected) {
                if (selected) {
                  provider.clearFilters();
                  provider.loadTaxRates(refresh: true);
                }
              },
              selectedColor: AppTheme.primaryMaroon.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryMaroon,
            ),
            FilterChip(
              label: Text(l10n.active),
              selected: provider.isActiveFilter == true,
              onSelected: (selected) {
                provider.filterByActiveStatus(selected ? true : null);
              },
              selectedColor: AppTheme.primaryMaroon.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryMaroon,
            ),
            FilterChip(
              label: Text(l10n.inactive),
              selected: provider.isActiveFilter == false,
              onSelected: (selected) {
                provider.filterByActiveStatus(selected ? false : null);
              },
              selectedColor: AppTheme.primaryMaroon.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryMaroon,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaxRatesTable(bool canEdit, bool canDelete) {
    return Consumer<TaxRatesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: SizedBox(
              width: 6.w,
              height: 6.w,
              child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
            ),
          );
        }

        if (provider.taxRates.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(children: provider.taxRates.map((taxRate) => _buildTaxRateCard(taxRate, canEdit, canDelete)).toList()),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, color: AppTheme.lightGray, size: 12.w),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.noTaxRatesFound,
            style: TextStyle(fontSize: context.headingFontSize, fontWeight: FontWeight.w500, color: AppTheme.lightGray),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            l10n.addFirstTaxRate,
            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.lightGray.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRateCard(TaxRateModel taxRate, bool canEdit, bool canDelete) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.5), width: 1),
        boxShadow: [BoxShadow(color: AppTheme.shadowColor, blurRadius: context.shadowBlur('light'), offset: Offset(0, 1))],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(context.cardPadding),
        leading: Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: taxRate.isActive ? AppTheme.primaryMaroon.withOpacity(0.1) : AppTheme.lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: taxRate.isActive ? AppTheme.primaryMaroon : AppTheme.lightGray,
            size: context.iconSize('medium'),
          ),
        ),
        title: Text(
          taxRate.name,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taxRate.taxTypeDisplay,
              style: TextStyle(fontSize: context.captionFontSize, color: AppTheme.charcoalGray.withOpacity(0.7)),
            ),
            if (taxRate.description?.isNotEmpty == true)
              Text(
                taxRate.description!,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: AppTheme.charcoalGray.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                '${taxRate.percentage.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
              ),
            ),
            SizedBox(width: context.smallPadding),
            if (canEdit || canDelete)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppTheme.charcoalGray),
                onSelected: (value) => _handleTaxRateAction(value, taxRate),
                itemBuilder: (context) => [
                  if (canEdit)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: AppTheme.primaryMaroon),
                          SizedBox(width: context.smallPadding),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                  if (canEdit)
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(taxRate.isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.primaryMaroon),
                          SizedBox(width: context.smallPadding),
                          Text(taxRate.isActive ? l10n.deactivate : l10n.activate),
                        ],
                      ),
                    ),
                  if (canDelete)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.red),
                          SizedBox(width: context.smallPadding),
                          Text(l10n.delete),
                        ],
                      ),
                    ),
                ],
              )
            else
               Text(
                "View-only",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<TaxRatesProvider>(
      builder: (context, provider, child) {
        if (provider.totalPages <= 1) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: AppTheme.lightGray.withOpacity(0.2),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(context.borderRadius('medium')),
              bottomRight: Radius.circular(context.borderRadius('medium')),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.page} ${provider.currentPage} ${l10n.outOf} ${provider.totalPages}',
                style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: provider.hasPrevious ? provider.loadPreviousPage : null,
                    icon: Icon(Icons.chevron_left_rounded),
                    color: provider.hasPrevious ? AppTheme.primaryMaroon : AppTheme.lightGray,
                  ),
                  IconButton(
                    onPressed: provider.hasNext ? provider.loadNextPage : null,
                    icon: Icon(Icons.chevron_right_rounded),
                    color: provider.hasNext ? AppTheme.primaryMaroon : AppTheme.lightGray,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxConfiguration() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius('medium')),
              boxShadow: [BoxShadow(color: AppTheme.shadowColor, blurRadius: context.shadowBlur(), offset: Offset(0, 2))],
            ),
            child: SingleChildScrollView(
              child: TaxConfigurationWidget(
                isEditable: false,
                onConfigurationChanged: (config) {},
              ),
            ),
          ),
          SizedBox(height: context.cardPadding),
          _buildStatisticsCard(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<TaxRatesProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(context.borderRadius('medium')),
            boxShadow: [BoxShadow(color: AppTheme.shadowColor, blurRadius: context.shadowBlur(), offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.statistics,
                style: TextStyle(fontSize: context.headingFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              SizedBox(height: context.cardPadding),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(l10n.totalTaxRates, provider.taxRatesCount.toString(), Icons.receipt_long_rounded, AppTheme.primaryMaroon),
                      ),
                      SizedBox(width: context.smallPadding),
                      Expanded(
                        child: _buildStatItem(l10n.activeRates, provider.activeTaxRatesCount.toString(), Icons.check_circle_rounded, Colors.green),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: context.iconSize('medium')),
              SizedBox(height: context.smallPadding / 2),
              Text(
                value,
                style: TextStyle(fontSize: context.headingFontSize, fontWeight: FontWeight.w700, color: color),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.smallPadding / 4),
              Text(
                label,
                style: TextStyle(fontSize: context.captionFontSize, color: AppTheme.charcoalGray.withOpacity(0.7)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleTaxRateAction(String action, TaxRateModel taxRate) {
    switch (action) {
      case 'edit':
        _showEditTaxRateDialog(taxRate);
        break;
      case 'toggle':
        _toggleTaxRateStatus(taxRate);
        break;
      case 'delete':
        _showDeleteTaxRateDialog(taxRate);
        break;
    }
  }

  void _showAddTaxRateDialog() {
    showDialog(
      context: context,
      builder: (context) => _TaxRateDialog(
        onSaved: (taxRate) {
          context.read<TaxRatesProvider>().loadTaxRates(refresh: true);
        },
      ),
    );
  }

  void _showEditTaxRateDialog(TaxRateModel taxRate) {
    showDialog(
      context: context,
      builder: (context) => _TaxRateDialog(
        taxRate: taxRate,
        onSaved: (updatedTaxRate) {
          context.read<TaxRatesProvider>().loadTaxRates(refresh: true);
        },
      ),
    );
  }

  void _toggleTaxRateStatus(TaxRateModel taxRate) {
    context.read<TaxRatesProvider>().toggleTaxRateStatus(taxRate.id);
  }

  void _showDeleteTaxRateDialog(TaxRateModel taxRate) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.deleteTaxRate,
          style: TextStyle(fontSize: context.headingFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        content: Text(
          '${l10n.deleteTaxRateConfirmation} "${taxRate.name}"? ${l10n.actionCannotBeUndone}',
          style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: AppTheme.charcoalGray)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TaxRatesProvider>().deleteTaxRate(taxRate.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: AppTheme.pureWhite),
            child: Text(l10n.delete, style: TextStyle(color: AppTheme.pureWhite)),
          ),
        ],
      ),
    );
  }
}

class _TaxRateDialog extends StatefulWidget {
  final TaxRateModel? taxRate;
  final Function(TaxRateModel) onSaved;

  const _TaxRateDialog({this.taxRate, required this.onSaved});

  @override
  State<_TaxRateDialog> createState() => _TaxRateDialogState();
}

class _TaxRateDialogState extends State<_TaxRateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _percentageController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedTaxType = 'GST';
  bool _isActive = true;
  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;

  @override
  void initState() {
    super.initState();
    if (widget.taxRate != null) {
      _nameController.text = widget.taxRate!.name;
      _percentageController.text = widget.taxRate!.percentage.toString();
      _descriptionController.text = widget.taxRate!.description ?? '';
      _selectedTaxType = widget.taxRate!.taxType;
      _isActive = widget.taxRate!.isActive;
      _effectiveFrom = widget.taxRate!.effectiveFrom;
      _effectiveTo = widget.taxRate!.effectiveTo;
    } else {
      _effectiveFrom = DateTime.now();
    }
  }

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
        widget.taxRate == null ? l10n.addTaxRate : l10n.editTaxRate,
        style: TextStyle(fontSize: context.headingFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              SizedBox(height: context.cardPadding),
              DropdownButtonFormField<String>(
                value: _selectedTaxType,
                decoration: InputDecoration(
                  labelText: l10n.taxType,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                ),
                items: ['GST', 'FED', 'WHT', 'ADDITIONAL', 'CUSTOM'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTaxType = value!;
                  });
                },
              ),
              SizedBox(height: context.cardPadding),
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
              SizedBox(height: context.cardPadding),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.descriptionOptional,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                ),
                maxLines: 2,
              ),
              SizedBox(height: context.cardPadding),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(
                        l10n.active,
                        style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value ?? true;
                        });
                      },
                      activeColor: AppTheme.primaryMaroon,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: TextStyle(color: AppTheme.charcoalGray)),
        ),
        ElevatedButton(
          onPressed: _saveTaxRate,
          child: Text(widget.taxRate == null ? l10n.add : l10n.update, style: TextStyle(color: AppTheme.pureWhite)),
        ),
      ],
    );
  }

  void _saveTaxRate() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<TaxRatesProvider>();
      final name = _nameController.text.trim();
      final percentage = double.parse(_percentageController.text);
      final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

      if (widget.taxRate == null) {
        final request = CreateTaxRateRequest(
          name: name,
          taxType: _selectedTaxType,
          percentage: percentage,
          description: description,
          effectiveFrom: _effectiveFrom,
          effectiveTo: _effectiveTo,
        );

        final success = await provider.createTaxRate(request);
        if (success && mounted) {
          widget.onSaved(widget.taxRate!);
          Navigator.of(context).pop();
        }
      } else {
        final request = UpdateTaxRateRequest(
          name: name,
          taxType: _selectedTaxType,
          percentage: percentage,
          description: description,
          effectiveFrom: _effectiveFrom,
          effectiveTo: _effectiveTo,
          isActive: _isActive,
        );

        final success = await provider.updateTaxRate(widget.taxRate!.id, request);
        if (success && mounted) {
          widget.onSaved(widget.taxRate!);
          Navigator.of(context).pop();
        }
      }
    }
  }
}