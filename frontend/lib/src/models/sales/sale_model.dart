import 'package:flutter/material.dart';

// ============================================================================
// HELPER FUNCTIONS - Robust parsing for API responses
// ============================================================================

/// Helper function to safely parse numeric values from API (handles strings, numbers, and nulls)
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    if (value.isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    if (value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

// ============================================================================
// TAX RATE MODEL
// ============================================================================

class TaxRateModel {
  final String id;
  final String name;
  final String taxType;
  final double percentage;
  final bool isActive;
  final String? description;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  bool get isCurrentlyEffective {
    final now = DateTime.now();
    if (effectiveTo != null) {
      return effectiveFrom.isBefore(now) && effectiveTo!.isAfter(now);
    }
    return effectiveFrom.isBefore(now);
  }

  String get taxTypeDisplay {
    switch (taxType) {
      case 'GST':
        return 'General Sales Tax';
      case 'FED':
        return 'Federal Excise Duty';
      case 'WHT':
        return 'Withholding Tax';
      case 'ADDITIONAL':
        return 'Additional Tax';
      case 'CUSTOM':
        return 'Custom Tax';
      default:
        return taxType;
    }
  }

  String get displayName => '$name ($percentage%)';

  TaxRateModel({
    required this.id,
    required this.name,
    required this.taxType,
    required this.percentage,
    required this.isActive,
    this.description,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaxRateModel.fromJson(Map<String, dynamic> json) {
    return TaxRateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      taxType: json['tax_type'] as String? ?? 'GST',
      percentage: _parseDouble(json['percentage']),
      isActive: json['is_active'] as bool? ?? true,
      description: json['description'] as String?,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.parse(json['effective_from'] as String)
          : DateTime.now(),
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tax_type': taxType,
      'percentage': percentage,
      'is_active': isActive,
      'description': description,
      'effective_from': effectiveFrom.toIso8601String(),
      'effective_to': effectiveTo?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaxRateModel copyWith({
    String? id,
    String? name,
    String? taxType,
    double? percentage,
    bool? isActive,
    String? description,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaxRateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      taxType: taxType ?? this.taxType,
      percentage: percentage ?? this.percentage,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// TAX CONFIGURATION MODEL
// ============================================================================

class TaxConfiguration {
  final Map<String, TaxConfigItem> taxes;

  TaxConfiguration({Map<String, TaxConfigItem>? taxes}) : taxes = taxes ?? {};

  double get totalTaxAmount {
    return taxes.values.fold(0.0, (sum, tax) => sum + tax.amount);
  }

  double get totalTaxPercentage {
    return taxes.values.fold(0.0, (sum, tax) => sum + tax.percentage);
  }

  bool get hasTaxes => taxes.isNotEmpty;

  List<TaxConfigItem> get taxList => taxes.values.toList();

  factory TaxConfiguration.fromJson(Map<String, dynamic> json) {
    final Map<String, TaxConfigItem> taxes = {};

    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        taxes[key] = TaxConfigItem.fromJson(value);
      }
    });

    return TaxConfiguration(taxes: taxes);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    taxes.forEach((key, value) {
      result[key] = value.toJson();
    });
    return result;
  }

  TaxConfiguration copyWith({Map<String, TaxConfigItem>? taxes}) {
    return TaxConfiguration(taxes: taxes ?? this.taxes);
  }

  void addTax(String type, TaxConfigItem tax) {
    taxes[type] = tax;
  }

  void removeTax(String type) {
    taxes.remove(type);
  }

  void clearTaxes() {
    taxes.clear();
  }
}

// ============================================================================
// INDIVIDUAL TAX CONFIGURATION ITEM
// ============================================================================

class TaxConfigItem {
  final String name;
  final double percentage;
  final double amount;
  final String? description;

  TaxConfigItem({
    required this.name,
    required this.percentage,
    required this.amount,
    this.description,
  });

  factory TaxConfigItem.fromJson(Map<String, dynamic> json) {
    return TaxConfigItem(
      name: json['name'] as String? ?? '',
      percentage: _parseDouble(json['percentage']),
      amount: _parseDouble(json['amount']),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'percentage': percentage,
      'amount': amount,
      'description': description,
    };
  }

  TaxConfigItem copyWith({
    String? name,
    double? percentage,
    double? amount,
    String? description,
  }) {
    return TaxConfigItem(
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }
}

// ============================================================================
// SALE ITEM MODEL
// ============================================================================

class SaleItemModel {
  final String id;
  final String saleId;
  final String? orderItemId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final int days; // Added for rental sync
  final String pricingType; // Added for rental sync
  final double itemDiscount;
  final double lineTotal;
  final String? customizationNotes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  double get totalBeforeDiscount => unitPrice * quantity;
  double get discountAmount => totalBeforeDiscount - lineTotal;
  double get discountPercentage =>
      totalBeforeDiscount > 0 ? (discountAmount / totalBeforeDiscount) * 100 : 0;
  double get discountedUnitPrice =>
      quantity > 0 ? lineTotal / quantity : unitPrice;

  SaleItemModel({
    required this.id,
    required this.saleId,
    this.orderItemId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.days = 1,
    this.pricingType = 'PER_DAY',
    required this.itemDiscount,
    required this.lineTotal,
    this.customizationNotes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as String? ?? '',
      saleId: json['sale'] as String? ?? '',
      orderItemId: json['order_item'] as String?,
      productId: json['product'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Unknown Product',
      unitPrice: _parseDouble(json['unit_price']),
      quantity: _parseInt(json['quantity']),
      days: json['days'] != null ? _parseInt(json['days']) : 1,
      pricingType: json['pricing_type'] ?? 'PER_DAY',
      itemDiscount: _parseDouble(json['item_discount']),
      lineTotal: _parseDouble(json['line_total']),
      customizationNotes: json['customization_notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale': saleId,
      'order_item': orderItemId,
      'product': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'days': days,
      'pricing_type': pricingType,
      'item_discount': itemDiscount,
      'line_total': lineTotal,
      'customization_notes': customizationNotes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SaleItemModel copyWith({
    String? id,
    String? saleId,
    String? orderItemId,
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    int? days,
    String? pricingType,
    double? itemDiscount,
    double? lineTotal,
    String? customizationNotes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      orderItemId: orderItemId ?? this.orderItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      days: days ?? this.days,
      pricingType: pricingType ?? this.pricingType,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      lineTotal: lineTotal ?? this.lineTotal,
      customizationNotes: customizationNotes ?? this.customizationNotes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// MAIN SALE MODEL
// ============================================================================

class SaleModel {
  final String id;
  final String invoiceNumber;
  final String? orderId;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final double subtotal;
  final double overallDiscount;
  final TaxConfiguration taxConfiguration;
  final double gstPercentage;
  final double taxAmount;
  final double grandTotal;
  final double amountPaid;
  final double remainingAmount;
  final bool isFullyPaid;
  final String paymentMethod;
  final Map<String, dynamic>? splitPaymentDetails;
  final DateTime dateOfSale;
  final String status;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final List<SaleItemModel> saleItems;

  // Computed properties
  String get formattedInvoiceNumber => '#$invoiceNumber';
  String get dateTimeText =>
      '${dateOfSale.day}/${dateOfSale.month}/${dateOfSale.year}';
  int get totalItems => saleItems.fold(0, (sum, item) => sum + item.quantity);
  double get paymentPercentage =>
      grandTotal > 0 ? (amountPaid / grandTotal) * 100 : 0;
  int get salesAgeDays => DateTime.now().difference(dateOfSale).inDays;

  bool get isPaid => status == 'PAID';
  bool get isPartial => status == 'PARTIAL' || (amountPaid > 0 && !isFullyPaid);
  bool get isUnpaid => status == 'UNPAID' || amountPaid == 0;

  Color get statusColor {
    switch (status) {
      case 'PAID':
      case 'DELIVERED':
        return Colors.green;
      case 'PARTIAL':
      case 'INVOICED':
      case 'ISSUED':
      case 'SENT':
        return Colors.orange;
      case 'UNPAID':
      case 'DRAFT':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      case 'RETURNED':
        return Colors.red;
      case 'CLOSED':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'INVOICED':
        return 'Invoiced';
      case 'ISSUED':
        return 'Pending';
      case 'SENT':
        return 'Unpaid';
      case 'PAID':
        return 'Paid';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'RETURNED':
        return 'Returned';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }

  String get paymentStatusDisplay {
    if (isFullyPaid) return 'Fully Paid';
    if (amountPaid > 0)
      return 'Partially Paid (${paymentPercentage.toStringAsFixed(1)}%)';
    return 'Unpaid';
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'CASH':
        return 'Cash';
      case 'CARD':
        return 'Credit/Debit Card';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      case 'MOBILE_PAYMENT':
        return 'Mobile Payment';
      case 'SPLIT':
        return 'Split Payment';
      case 'CREDIT':
        return 'Credit Sale';
      default:
        return paymentMethod;
    }
  }

  String get taxSummaryDisplay {
    if (!taxConfiguration.hasTaxes) return 'No taxes applied';

    final taxList = taxConfiguration.taxList;
    if (taxList.length == 1) {
      final tax = taxList.first;
      return '${tax.name}: ${tax.percentage}%';
    } else {
      return 'Multiple taxes (${taxList.length} types)';
    }
  }

  SaleModel({
    required this.id,
    required this.invoiceNumber,
    this.orderId,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.subtotal,
    required this.overallDiscount,
    required this.taxConfiguration,
    required this.gstPercentage,
    required this.taxAmount,
    required this.grandTotal,
    required this.amountPaid,
    required this.remainingAmount,
    required this.isFullyPaid,
    required this.paymentMethod,
    this.splitPaymentDetails,
    required this.dateOfSale,
    required this.status,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    required this.saleItems,
  });

  // ✅ FIXED: Robust fromJson that handles missing fields in API "List" responses
  factory SaleModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'DRAFT';
    final grandTotal = _parseDouble(json['grand_total']);
    final amountPaid = (status == 'ISSUED' || status == 'SENT') ? 0.0 : _parseDouble(json['amount_paid'] ?? 0.0);

    return SaleModel(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      orderId: json['order_id'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String? ?? 'Walk-in Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerEmail: json['customer_email'] as String?,

      // Handle numeric fields safely
      subtotal: _parseDouble(json['subtotal']),
      overallDiscount: _parseDouble(json['overall_discount']),
      taxConfiguration: TaxConfiguration.fromJson(
          json['tax_configuration'] as Map<String, dynamic>? ?? {}),
      gstPercentage: _parseDouble(json['gst_percentage']),
      taxAmount: _parseDouble(json['tax_amount']),
      grandTotal: grandTotal,
      amountPaid: amountPaid,

      // Calculate remaining amount if missing (List View doesn't send it)
      remainingAmount: json['remaining_amount'] != null
          ? _parseDouble(json['remaining_amount'])
          : grandTotal - amountPaid,

      isFullyPaid: json['is_fully_paid'] as bool? ?? (json['remaining_amount'] == 0),
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      splitPaymentDetails: json['split_payment_details'] as Map<String, dynamic>?,

      // Date of Sale
      dateOfSale: json['date_of_sale'] != null
          ? DateTime.parse(json['date_of_sale'] as String)
          : DateTime.now(),

      status: status,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,

      // --- FIX: Use Fallbacks for Missing Dates ---
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['date_of_sale'] != null
          ? DateTime.parse(json['date_of_sale'] as String)
          : DateTime.now()),

      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),

      createdBy: json['created_by'] as String?,

      // --- FIX: ULTRA ROBUST ITEMS LIST PARSING ---
      // This checks every possible key the backend might be sending for items
      saleItems: ((json['sale_items'] as List<dynamic>?) ?? 
                  (json['items'] as List<dynamic>?) ?? 
                  (json['products'] as List<dynamic>?) ?? 
                  (json['sale_details'] as List<dynamic>?) ??
                  (json['details'] as List<dynamic>?))
          ?.map((item) => SaleItemModel.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'order_id': orderId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'subtotal': subtotal,
      'overall_discount': overallDiscount,
      'tax_configuration': taxConfiguration.toJson(),
      'gst_percentage': gstPercentage,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'amount_paid': amountPaid,
      'remaining_amount': remainingAmount,
      'is_fully_paid': isFullyPaid,
      'payment_method': paymentMethod,
      'split_payment_details': splitPaymentDetails,
      'date_of_sale': dateOfSale.toIso8601String(),
      'status': status,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'sale_items': saleItems.map((item) => item.toJson()).toList(),
    };
  }

  SaleModel copyWith({
    String? id,
    String? invoiceNumber,
    String? orderId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    double? subtotal,
    double? overallDiscount,
    TaxConfiguration? taxConfiguration,
    double? gstPercentage,
    double? taxAmount,
    double? grandTotal,
    double? amountPaid,
    double? remainingAmount,
    bool? isFullyPaid,
    String? paymentMethod,
    Map<String, dynamic>? splitPaymentDetails,
    DateTime? dateOfSale,
    String? status,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<SaleItemModel>? saleItems,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      subtotal: subtotal ?? this.subtotal,
      overallDiscount: overallDiscount ?? this.overallDiscount,
      taxConfiguration: taxConfiguration ?? this.taxConfiguration,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      isFullyPaid: isFullyPaid ?? this.isFullyPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      splitPaymentDetails: splitPaymentDetails ?? this.splitPaymentDetails,
      dateOfSale: dateOfSale ?? this.dateOfSale,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      saleItems: saleItems ?? this.saleItems,
    );
  }
}

// ============================================================================
// INVOICE MODEL
// ============================================================================

class InvoiceModel {
  final String id;
  final String saleId;
  final String? orderId;
  final String saleInvoiceNumber;
  final String customerName;
  final double grandTotal;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final double writeOffAmount;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime? dueDate;
  final String status;
  final String? notes;
  final String? termsConditions;
  final String? pdfFile;
  final bool emailSent;
  final DateTime? emailSentAt;
  final DateTime? viewedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  // Computed properties
  String get formattedIssueDate =>
      '${issueDate.day}/${issueDate.month}/${issueDate.year}';
  String get formattedDueDate => dueDate != null
      ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
      : 'Not specified';
  int get daysUntilDue {
    if (dueDate == null || status == 'PAID' || status == 'CANCELLED') return 0;
    final now = DateTime.now();
    return dueDate!.difference(now).inDays;
  }

  bool get isOverdue =>
      dueDate != null &&
          status != 'PAID' &&
          status != 'CANCELLED' &&
          DateTime.now().isAfter(dueDate!);

  Color get statusColor {
    switch (status) {
      case 'PAID':
        return Colors.green;
      case 'OVERDUE':
        return Colors.red;
      case 'ISSUED': // Pending
        return Colors.orange;
      case 'SENT': // Unpaid
        return Colors.red;
      case 'VIEWED':
        return Colors.blue;
      case 'PARTIALLY_PAID':
        return Colors.blue;
      case 'WRITTEN_OFF':
        return Colors.purple;
      case 'DRAFT':
        return Colors.grey;
      case 'CLOSED':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'ISSUED':
        return 'Pending';
      case 'SENT':
        return 'Unpaid';
      case 'VIEWED':
        return 'Viewed';
      case 'PAID':
        return 'Paid';
      case 'PARTIALLY_PAID':
        return 'Partially Paid';
      case 'WRITTEN_OFF':
        return 'Written Off';
      case 'OVERDUE':
        return 'Overdue';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }

  InvoiceModel({
    required this.id,
    required this.saleId,
    this.orderId,
    required this.saleInvoiceNumber,
    required this.customerName,
    required this.grandTotal,
    this.totalAmount = 0.0,
    this.amountPaid = 0.0,
    this.amountDue = 0.0,
    this.writeOffAmount = 0.0,
    required this.invoiceNumber,
    required this.issueDate,
    this.dueDate,
    required this.status,
    this.notes,
    this.termsConditions,
    this.pdfFile,
    required this.emailSent,
    this.emailSentAt,
    this.viewedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('🔍 [InvoiceModel] Parsing JSON: $json');
      
      // Helper function to handle both int and string types
      String? _parseString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;
        if (value is int) return value.toString();
        if (value is double) return value.toString();
        return value.toString();
      }
      
      final status = json['status'] as String? ?? 'DRAFT';
      double amountPaid = _parseDouble(json['amount_paid']);
      double amountDue = _parseDouble(json['amount_due']);
      double grandTotal = _parseDouble(json['grand_total'] ?? json['total_amount']);

      // Removed manual override to allow advance payments to be correctly reflected

      // Handle saleId extraction (could be a string ID or a nested object)
      dynamic saleData = json['sale'] ?? json['sale_id'];
      String sId = '';
      if (saleData is String) {
        sId = saleData;
      } else if (saleData is Map) {
        sId = _parseString(saleData['id']) ?? '';
      }

      final invoice = InvoiceModel(
        id: json['id'] as String? ?? '',
        saleId: sId,
        orderId: _parseString(json['order'] ?? json['order_id']),
        saleInvoiceNumber: json['sale_invoice_number'] as String? ?? '',
        customerName: json['customer_name'] as String? ?? '',
        grandTotal: grandTotal,
        totalAmount: _parseDouble(json['total_amount']),
        amountPaid: amountPaid,
        amountDue: (['WRITTEN_OFF', 'CLOSED', 'PAID'].contains(status.toUpperCase())) ? 0 : amountDue,
        writeOffAmount: (['WRITTEN_OFF', 'CLOSED'].contains(status.toUpperCase())) 
            ? (grandTotal > 0 ? (grandTotal - amountPaid) : (_parseDouble(json['total_amount']) - amountPaid)) 
            : _parseDouble(json['write_off_amount']),
        invoiceNumber: json['invoice_number'] as String? ?? '',
        issueDate: json['issue_date'] != null
            ? DateTime.parse(json['issue_date'] as String)
            : DateTime.now(),
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        status: status,
        notes: _parseString(json['notes']),
        termsConditions: _parseString(json['terms_conditions']),
        pdfFile: _parseString(json['pdf_file']),
        emailSent: json['email_sent'] as bool? ?? false,
        emailSentAt: json['email_sent_at'] != null
            ? DateTime.parse(json['email_sent_at'] as String)
            : null,
        viewedAt: json['viewed_at'] != null
            ? DateTime.parse(json['viewed_at'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        createdBy: _parseString(json['created_by']),
      );
      
      debugPrint('✅ [InvoiceModel] Successfully parsed invoice: ${invoice.invoiceNumber}');
      return invoice;
    } catch (e) {
      debugPrint('❌ [InvoiceModel] Error parsing JSON: $e');
      debugPrint('❌ [InvoiceModel] JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale': saleId,
      'order': orderId,
      'sale_invoice_number': saleInvoiceNumber,
      'customer_name': customerName,
      'grand_total': grandTotal,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'amount_due': amountDue,
      'write_off_amount': writeOffAmount,
      'invoice_number': invoiceNumber,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'terms_conditions': termsConditions,
      'pdf_file': pdfFile,
      'email_sent': emailSent,
      'email_sent_at': emailSentAt?.toIso8601String(),
      'viewed_at': viewedAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  InvoiceModel copyWith({
    String? id,
    String? saleId,
    String? orderId,
    String? saleInvoiceNumber,
    String? customerName,
    double? grandTotal,
    double? totalAmount,
    double? amountPaid,
    double? amountDue,
    double? writeOffAmount,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    String? status,
    String? notes,
    String? termsConditions,
    String? pdfFile,
    bool? emailSent,
    DateTime? emailSentAt,
    DateTime? viewedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      orderId: orderId ?? this.orderId,
      saleInvoiceNumber: saleInvoiceNumber ?? this.saleInvoiceNumber,
      customerName: customerName ?? this.customerName,
      grandTotal: grandTotal ?? this.grandTotal,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      amountDue: amountDue ?? this.amountDue,
      writeOffAmount: writeOffAmount ?? this.writeOffAmount,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      termsConditions: termsConditions ?? this.termsConditions,
      pdfFile: pdfFile ?? this.pdfFile,
      emailSent: emailSent ?? this.emailSent,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      viewedAt: viewedAt ?? this.viewedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

// ============================================================================
// RECEIPT MODEL
// ============================================================================

class ReceiptModel {
  final String id;
  final String saleId;
  final String saleInvoiceNumber;
  final String customerName;
  final String paymentId;
  final double paymentAmount;
  final String paymentMethod;
  final String receiptNumber;
  final DateTime generatedAt;
  final String status;
  final String? pdfFile;
  final bool emailSent;
  final DateTime? emailSentAt;
  final DateTime? viewedAt;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  // Computed properties
  String get formattedGeneratedDate =>
      '${generatedAt.day}/${generatedAt.month}/${generatedAt.year}';
  String get formattedPaymentAmount =>
      'PKR ${paymentAmount.toStringAsFixed(2)}';

  Color get statusColor {
    switch (status) {
      case 'GENERATED':
        return Colors.blue;
      case 'SENT':
        return Colors.orange;
      case 'VIEWED':
        return Colors.green;
      case 'ARCHIVED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'GENERATED':
        return 'Generated';
      case 'SENT':
        return 'Sent';
      case 'VIEWED':
        return 'Viewed';
      case 'ARCHIVED':
        return 'Archived';
      default:
        return status;
    }
  }

  ReceiptModel({
    required this.id,
    required this.saleId,
    required this.saleInvoiceNumber,
    required this.customerName,
    required this.paymentId,
    required this.paymentAmount,
    required this.paymentMethod,
    required this.receiptNumber,
    required this.generatedAt,
    required this.status,
    this.pdfFile,
    required this.emailSent,
    this.emailSentAt,
    this.viewedAt,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'] as String? ?? '',
      saleId: json['sale'] as String? ?? '',
      saleInvoiceNumber: json['sale_invoice_number'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      paymentId: json['payment'] as String? ?? '',
      paymentAmount: _parseDouble(json['payment_amount'] ?? json['sale_amount'] ?? '0.0'),
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      receiptNumber: json['receipt_number'] as String? ?? '',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'GENERATED',
      pdfFile: json['pdf_file'] as String?,
      emailSent: json['email_sent'] as bool? ?? false,
      emailSentAt: json['email_sent_at'] != null
          ? DateTime.parse(json['email_sent_at'] as String)
          : null,
      viewedAt: json['viewed_at'] != null
          ? DateTime.parse(json['viewed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale': saleId,
      'sale_invoice_number': saleInvoiceNumber,
      'customer_name': customerName,
      'payment': paymentId,
      'payment_amount': paymentAmount,
      'payment_method': paymentMethod,
      'receipt_number': receiptNumber,
      'generated_at': generatedAt.toIso8601String(),
      'status': status,
      'pdf_file': pdfFile,
      'email_sent': emailSent,
      'email_sent_at': emailSentAt?.toIso8601String(),
      'viewed_at': viewedAt?.toIso8601String(),
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  ReceiptModel copyWith({
    String? id,
    String? saleId,
    String? saleInvoiceNumber,
    String? customerName,
    String? paymentId,
    double? paymentAmount,
    String? paymentMethod,
    String? receiptNumber,
    DateTime? generatedAt,
    String? status,
    String? pdfFile,
    bool? emailSent,
    DateTime? emailSentAt,
    DateTime? viewedAt,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      saleInvoiceNumber: saleInvoiceNumber ?? this.saleInvoiceNumber,
      customerName: customerName ?? this.customerName,
      paymentId: paymentId ?? this.paymentId,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      generatedAt: generatedAt ?? this.generatedAt,
      status: status ?? this.status,
      pdfFile: pdfFile ?? this.pdfFile,
      emailSent: emailSent ?? this.emailSent,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      viewedAt: viewedAt ?? this.viewedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}