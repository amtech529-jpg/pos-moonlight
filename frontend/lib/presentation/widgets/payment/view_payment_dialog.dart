import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../src/models/payment/payment_model.dart';
import '../../../src/models/payment/payment_request_models.dart';
import '../../../src/providers/payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/image_upload.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';

class ViewPaymentDialog extends StatefulWidget {
  final PaymentModel payment;

  const ViewPaymentDialog({super.key, required this.payment});

  @override
  State<ViewPaymentDialog> createState() => _ViewPaymentDialogState();
}

class _ViewPaymentDialogState extends State<ViewPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bonusController = TextEditingController();
  final _deductionController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEditing = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedPaymentMethod;
  String? _selectedPayerType;
  bool _isFinalPayment = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.payment.date;
    _selectedTime = TimeOfDay(hour: widget.payment.time.hour, minute: widget.payment.time.minute);
    _selectedPaymentMethod = widget.payment.paymentMethod;
    _selectedPayerType = widget.payment.payerType;
    _isFinalPayment = widget.payment.isFinalPayment;

    _amountController.text = widget.payment.amountPaid.toString();
    _bonusController.text = widget.payment.bonus.toString();
    _deductionController.text = widget.payment.deduction.toString();
    _descriptionController.text = widget.payment.description ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bonusController.dispose();
    _deductionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatPaymentMonth(BuildContext context, DateTime paymentMonth) {
    final l10n = AppLocalizations.of(context)!;
    final monthNames = [
      l10n.january, l10n.february, l10n.march, l10n.april,
      l10n.may, l10n.june, l10n.july, l10n.august,
      l10n.september, l10n.october, l10n.november, l10n.december
    ];
    return '${monthNames[paymentMonth.month - 1]} ${paymentMonth.year}';
  }

  String _formatPaymentMethod(String method) {
    return method.replaceAll('_', ' ').toUpperCase();
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
            tablet: MediaQuery.of(context).size.width * 0.9,
            small: MediaQuery.of(context).size.width * 0.95,
            medium: 800,
            large: 900,
            ultrawide: 1000,
          ),
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(padding: EdgeInsets.all(context.cardPadding), child: _isEditing ? _buildEditForm() : _buildViewContent()),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.cardPadding),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon])),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(_isEditing ? Icons.edit_rounded : Icons.visibility_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              _isEditing ? l10n.editPayment : l10n.viewPaymentDetails,
              style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
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
        color: AppTheme.lightGray,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isEditing) ...[
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: Text(
                l10n.cancel,
                style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
              ),
            ),
            SizedBox(width: context.smallPadding),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                foregroundColor: AppTheme.pureWhite,
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
              ),
              child: Text(
                l10n.saveChanges,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: Text(
                l10n.edit,
                style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.primaryMaroon),
              ),
            ),
            SizedBox(width: context.smallPadding),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                foregroundColor: AppTheme.pureWhite,
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
              ),
              child: Text(
                l10n.close,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewContent() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection(l10n.paymentInformation, [
          _buildInfoRow(l10n.paymentId, widget.payment.id.substring(0, 8)),
          _buildInfoRow(l10n.status, widget.payment.isActive ? l10n.active : l10n.inactive),
          _buildInfoRow(l10n.created, _formatDateTime(widget.payment.createdAt)),
          if (widget.payment.createdAt != widget.payment.updatedAt) _buildInfoRow(l10n.lastUpdated, _formatDateTime(widget.payment.updatedAt)),
        ]),

        SizedBox(height: context.cardPadding),

        _buildInfoSection(l10n.payerInformation, [
          _buildInfoRow(l10n.payerType, widget.payment.payerType.toUpperCase()),
          if (widget.payment.payerId != null) _buildInfoRow(l10n.payerId, widget.payment.payerId!),
          if (widget.payment.laborName != null && widget.payment.laborName!.isNotEmpty) ...[
            _buildInfoRow(l10n.laborName, widget.payment.laborName!),
            if (widget.payment.laborRole != null) _buildInfoRow(l10n.laborRole, widget.payment.laborRole!),
            if (widget.payment.laborPhone != null) _buildInfoRow(l10n.laborPhone, widget.payment.laborPhone!),
          ],
          if (widget.payment.vendorId != null) _buildInfoRow(l10n.vendorId, widget.payment.vendorId!),
          if (widget.payment.orderId != null) _buildInfoRow(l10n.orderId, widget.payment.orderId!),
          if (widget.payment.saleId != null) _buildInfoRow(l10n.saleId, widget.payment.saleId!),
        ]),

        SizedBox(height: context.cardPadding),

        _buildInfoSection(l10n.paymentDetails, [
          _buildInfoRow(l10n.amountPaid, 'PKR ${widget.payment.amountPaid.toStringAsFixed(2)}'),
          if (widget.payment.bonus > 0) _buildInfoRow(l10n.bonus, 'PKR ${widget.payment.bonus.toStringAsFixed(2)}'),
          if (widget.payment.deduction > 0) _buildInfoRow(l10n.deduction, 'PKR ${widget.payment.deduction.toStringAsFixed(2)}'),
          _buildInfoRow(l10n.netAmount, 'PKR ${widget.payment.netAmount.toStringAsFixed(2)}'),
          _buildInfoRow(l10n.paymentMethod, _formatPaymentMethod(widget.payment.paymentMethod)),
          _buildInfoRow(l10n.paymentMonth, _formatPaymentMonth(context, widget.payment.paymentMonth)),
          _buildInfoRow(l10n.isFinalPayment, widget.payment.isFinalPayment ? l10n.yes : l10n.no),
        ]),

        SizedBox(height: context.cardPadding),

        _buildInfoSection(l10n.dateAndTime, [
          _buildInfoRow(l10n.date, '${widget.payment.date.day}/${widget.payment.date.month}/${widget.payment.date.year}'),
          _buildInfoRow(l10n.time, '${widget.payment.time.hour.toString().padLeft(2, '0')}:${widget.payment.time.minute.toString().padLeft(2, '0')}'),
        ]),

        SizedBox(height: context.cardPadding),

        if (widget.payment.description != null && widget.payment.description!.isNotEmpty) ...[
          _buildInfoSection(l10n.description, [_buildInfoRow(l10n.details, widget.payment.description!, isMultiline: true)]),
          SizedBox(height: context.cardPadding),
        ],

        if (widget.payment.receiptImagePath != null && widget.payment.receiptImagePath!.isNotEmpty) ...[
          _buildInfoSection(l10n.receipt, [_buildReceiptSection()]),
        ],

        if (widget.payment.createdBy != null) ...[
          SizedBox(height: context.cardPadding),
          _buildInfoSection(l10n.systemInformation, [_buildInfoRow(l10n.createdBy, widget.payment.createdBy!)]),
        ],
      ],
    );
  }

  Widget _buildEditForm() {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormSection(l10n.basicInformation, [
            _buildTextField(
              controller: _amountController,
              label: l10n.amountPaid,
              prefix: 'PKR',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.amountIsRequired;
                if (double.tryParse(value) == null) return l10n.invalidAmount;
                return null;
              },
            ),
            SizedBox(height: context.smallPadding),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(controller: _bonusController, label: l10n.bonus, prefix: 'PKR', keyboardType: TextInputType.number),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: _buildTextField(controller: _deductionController, label: l10n.deduction, prefix: 'PKR', keyboardType: TextInputType.number),
                ),
              ],
            ),
            SizedBox(height: context.smallPadding),
            _buildTextField(controller: _descriptionController, label: l10n.description, maxLines: 3),
          ]),

          SizedBox(height: context.cardPadding),

          _buildFormSection(l10n.paymentDetails, [
            _buildDropdownField(
              label: l10n.paymentMethod,
              value: _selectedPaymentMethod,
              items: PaymentProvider.staticPaymentMethods,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value),
              validator: (value) => value == null ? l10n.paymentMethodIsRequired : null,
            ),
            SizedBox(height: context.smallPadding),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    label: l10n.payerType,
                    value: _selectedPayerType,
                    items: PaymentProvider.staticPayerTypes,
                    onChanged: (value) => setState(() => _selectedPayerType = value),
                    validator: (value) => value == null ? l10n.payerTypeIsRequired : null,
                  ),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: CheckboxListTile(
                    title: Text(l10n.finalPayment, style: TextStyle(fontSize: context.bodyFontSize)),
                    value: _isFinalPayment,
                    onChanged: (value) => setState(() => _isFinalPayment = value ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ]),

          SizedBox(height: context.cardPadding),

          _buildFormSection(l10n.dateAndTime, [
            Row(
              children: [
                Expanded(child: _buildDateField()),
                SizedBox(width: context.smallPadding),
                Expanded(child: _buildTimeField()),
              ],
            ),
          ]),

          SizedBox(height: context.cardPadding),

          _buildFormSection(l10n.receipt, [
            ResponsiveImageUploadWidget(
              initialImagePath: widget.payment.receiptImagePath,
              onImageChanged: (imagePath) {},
              label: l10n.receiptImage,
              context: context,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: context.smallPadding),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixText: prefix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
            contentPadding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.replaceAll('_', ' ')))).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
            contentPadding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.date,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(Duration(days: 365)),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: TextStyle(fontSize: context.bodyFontSize)),
                Icon(Icons.calendar_today, size: context.iconSize('small')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.time,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(context: context, initialTime: _selectedTime);
            if (time != null) setState(() => _selectedTime = time);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedTime.format(context), style: TextStyle(fontSize: context.bodyFontSize)),
                Icon(Icons.access_time, size: context.iconSize('small')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: context.smallPadding),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallPadding / 2),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: AppTheme.charcoalGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.payment.receiptImagePath != null) ...[
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(context.borderRadius()), child: _buildReceiptImage()),
          ),
          SizedBox(height: context.smallPadding),
        ],
        Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.purple, size: context.iconSize('small')),
            SizedBox(width: context.smallPadding / 2),
            Text(
              l10n.receiptAvailable,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.purple),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptImage() {
    if (widget.payment.receiptImagePath!.startsWith('http://') || widget.payment.receiptImagePath!.startsWith('https://')) {
      return Image.network(widget.payment.receiptImagePath!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildErrorWidget());
    } else if (widget.payment.receiptImagePath!.startsWith('/media/')) {
      final fullUrl = 'http://127.0.0.1:8000${widget.payment.receiptImagePath!}';
      return Image.network(fullUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildErrorWidget());
    } else {
      return Image.file(File(widget.payment.receiptImagePath!), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildErrorWidget());
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: context.iconSize('large')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${l10n.at} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _saveChanges() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      try {
        final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

        final amountPaid = double.tryParse(_amountController.text);
        if (amountPaid == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidAmount), backgroundColor: Colors.red));
          return;
        }

        final paymentMethod = _selectedPaymentMethod;
        if (paymentMethod == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectPaymentMethod), backgroundColor: Colors.red));
          return;
        }

        final timeDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);

        final success = await paymentProvider.updatePayment(
          id: widget.payment.id,
          amountPaid: amountPaid,
          bonus: double.tryParse(_bonusController.text),
          deduction: double.tryParse(_deductionController.text),
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          time: timeDateTime,
          paymentMethod: paymentMethod,
          paymentMonth: widget.payment.paymentMonth,
          isFinalPayment: _isFinalPayment,
        );

        if (success) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentUpdatedSuccessfully), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.failedToUpdatePayment), backgroundColor: Colors.red));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorUpdatingPayment}: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
