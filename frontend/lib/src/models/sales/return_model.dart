import 'package:flutter/material.dart';

class ReturnModel {
  final String id;
  final String saleId;
  final String saleInvoiceNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String returnNumber;
  final DateTime returnDate;
  final String status;
  final String reason;
  final String? reasonDetails;
  final double totalReturnAmount;
  final double refundAmount;
  final String? refundMethod;
  final String? notes;
  final String? approvedById;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? processedById;
  final String? processedByName;
  final DateTime? processedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdById;
  final String? createdByName;
  final int returnItemsCount;
  final bool canBeApproved;
  final bool canBeProcessed;
  final bool canBeCancelled;

  ReturnModel({
    required this.id,
    required this.saleId,
    required this.saleInvoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.returnNumber,
    required this.returnDate,
    required this.status,
    required this.reason,
    this.reasonDetails,
    required this.totalReturnAmount,
    required this.refundAmount,
    this.refundMethod,
    this.notes,
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
    this.processedById,
    this.processedByName,
    this.processedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdById,
    this.createdByName,
    required this.returnItemsCount,
    required this.canBeApproved,
    required this.canBeProcessed,
    required this.canBeCancelled,
  });

  String get formattedReturnDate => '${returnDate.day}/${returnDate.month}/${returnDate.year}';
  String get formattedTotalReturnAmount => 'PKR ${totalReturnAmount.toStringAsFixed(2)}';
  String get formattedRefundAmount => 'PKR ${refundAmount.toStringAsFixed(2)}';

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.blue;
      case 'REJECTED':
        return Colors.red;
      case 'PROCESSED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending Approval';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'PROCESSED':
        return 'Processed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get reasonColor {
    switch (reason.toUpperCase()) {
      case 'DEFECTIVE':
        return Colors.red;
      case 'WRONG_SIZE':
        return Colors.orange;
      case 'WRONG_COLOR':
        return Colors.purple;
      case 'QUALITY_ISSUE':
        return Colors.red;
      case 'CUSTOMER_CHANGE_MIND':
        return Colors.blue;
      case 'DAMAGED_IN_TRANSIT':
        return Colors.red;
      case 'OTHER':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 [ReturnModel] Full JSON data: $json');
    debugPrint('🔍 [ReturnModel] Parsing return data: refund_amount = ${json['refund_amount']}');
    debugPrint('🔍 [ReturnModel] sale_invoice_number = ${json['sale_invoice_number']}');
    debugPrint('🔍 [ReturnModel] reason = ${json['reason']}');
    final totalReturnAmount = double.tryParse(json['refund_amount']?.toString() ?? '0') ?? 0.0;
    debugPrint('✅ [ReturnModel] Parsed totalReturnAmount: $totalReturnAmount');
    return ReturnModel(
      id: json['id'] ?? '',
      saleId: json['sale'] ?? '',
      saleInvoiceNumber: json['sale_invoice_number'] ?? '',
      customerId: json['customer'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      returnNumber: json['return_number'] ?? '',
      returnDate: DateTime.parse(json['return_date']),
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
      reasonDetails: json['reason_details'],
      totalReturnAmount: double.tryParse(json['total_return_amount']?.toString() ?? json['refund_amount']?.toString() ?? '0') ?? 0.0,
      refundAmount: double.tryParse(json['total_return_amount']?.toString() ?? json['refund_amount']?.toString() ?? '0') ?? 0.0,
      refundMethod: json['refund_method'],
      notes: json['notes'],
      approvedById: json['approved_by']?.toString(),
      approvedByName: json['approved_by_name'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      processedById: json['processed_by']?.toString(),
      processedByName: json['processed_by_name'],
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdById: json['created_by']?.toString(),
      createdByName: json['created_by_name'],
      returnItemsCount: json['return_items_count'] ?? 0,
      canBeApproved: json['can_be_approved'] ?? false,
      canBeProcessed: json['can_be_processed'] ?? false,
      canBeCancelled: json['can_be_cancelled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale': saleId,
      'sale_invoice_number': saleInvoiceNumber,
      'customer': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'return_number': returnNumber,
      'return_date': returnDate.toIso8601String().split('T')[0],
      'status': status,
      'reason': reason,
      'reason_details': reasonDetails,
      'refund_amount': totalReturnAmount,
      'refund_method': refundMethod,
      'notes': notes,
      'approved_by': approvedById,
      'approved_by_name': approvedByName,
      'approved_at': approvedAt?.toIso8601String(),
      'processed_by': processedById,
      'processed_by_name': processedByName,
      'processed_at': processedAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdById,
      'created_by_name': createdByName,
      'return_items_count': returnItemsCount,
      'can_be_approved': canBeApproved,
      'can_be_processed': canBeProcessed,
      'can_be_cancelled': canBeCancelled,
    };
  }

  ReturnModel copyWith({
    String? id,
    String? saleId,
    String? saleInvoiceNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? returnNumber,
    DateTime? returnDate,
    String? status,
    String? reason,
    String? reasonDetails,
    double? totalReturnAmount,
    double? refundAmount,
    String? refundMethod,
    String? notes,
    String? approvedById,
    String? approvedByName,
    DateTime? approvedAt,
    String? processedById,
    String? processedByName,
    DateTime? processedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdById,
    String? createdByName,
    int? returnItemsCount,
    bool? canBeApproved,
    bool? canBeProcessed,
    bool? canBeCancelled,
  }) {
    return ReturnModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      saleInvoiceNumber: saleInvoiceNumber ?? this.saleInvoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      returnNumber: returnNumber ?? this.returnNumber,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      reasonDetails: reasonDetails ?? this.reasonDetails,
      totalReturnAmount: totalReturnAmount ?? this.totalReturnAmount,
      refundAmount: refundAmount ?? this.refundAmount,
      refundMethod: refundMethod ?? this.refundMethod,
      notes: notes ?? this.notes,
      approvedById: approvedById ?? this.approvedById,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      processedById: processedById ?? this.processedById,
      processedByName: processedByName ?? this.processedByName,
      processedAt: processedAt ?? this.processedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      returnItemsCount: returnItemsCount ?? this.returnItemsCount,
      canBeApproved: canBeApproved ?? this.canBeApproved,
      canBeProcessed: canBeProcessed ?? this.canBeProcessed,
      canBeCancelled: canBeCancelled ?? this.canBeCancelled,
    );
  }
}

class ReturnItemModel {
  final String id;
  final String returnRequestId;
  final String saleItemId;
  final String productId;
  final String productName;
  final int quantityReturned;
  final int originalQuantity;
  final double originalPrice;
  final double returnAmount;
  final String condition;
  final String? conditionNotes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReturnItemModel({
    required this.id,
    required this.returnRequestId,
    required this.saleItemId,
    required this.productId,
    required this.productName,
    required this.quantityReturned,
    required this.originalQuantity,
    required this.originalPrice,
    required this.returnAmount,
    required this.condition,
    this.conditionNotes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedOriginalPrice => 'PKR ${originalPrice.toStringAsFixed(2)}';
  String get formattedReturnAmount => 'PKR ${returnAmount.toStringAsFixed(2)}';

  Color get conditionColor {
    switch (condition.toUpperCase()) {
      case 'NEW':
        return Colors.green;
      case 'GOOD':
        return Colors.blue;
      case 'FAIR':
        return Colors.orange;
      case 'POOR':
        return Colors.red;
      case 'DAMAGED':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  String get conditionDisplay {
    switch (condition.toUpperCase()) {
      case 'NEW':
        return 'New/Unused';
      case 'GOOD':
        return 'Good Condition';
      case 'FAIR':
        return 'Fair Condition';
      case 'POOR':
        return 'Poor Condition';
      case 'DAMAGED':
        return 'Damaged';
      default:
        return condition;
    }
  }

  factory ReturnItemModel.fromJson(Map<String, dynamic> json) {
    return ReturnItemModel(
      id: json['id'] ?? '',
      returnRequestId: json['return_request'] ?? '',
      saleItemId: json['sale_item'] ?? '',
      productId: json['product'] ?? '',
      productName: json['product_name'] ?? '',
      quantityReturned: json['quantity_returned'] ?? 0,
      originalQuantity: json['original_quantity'] ?? 0,
      originalPrice: double.tryParse(json['original_price']?.toString() ?? '0') ?? 0.0,
      returnAmount: double.tryParse(json['return_amount']?.toString() ?? '0') ?? 0.0,
      condition: json['condition'] ?? '',
      conditionNotes: json['condition_notes'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'return_request': returnRequestId,
      'sale_item': saleItemId,
      'product': productId,
      'product_name': productName,
      'quantity_returned': quantityReturned,
      'original_quantity': originalQuantity,
      'original_price': originalPrice,
      'return_amount': returnAmount,
      'condition': condition,
      'condition_notes': conditionNotes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReturnItemModel copyWith({
    String? id,
    String? returnRequestId,
    String? saleItemId,
    String? productId,
    String? productName,
    int? quantityReturned,
    int? originalQuantity,
    double? originalPrice,
    double? returnAmount,
    String? condition,
    String? conditionNotes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReturnItemModel(
      id: id ?? this.id,
      returnRequestId: returnRequestId ?? this.returnRequestId,
      saleItemId: saleItemId ?? this.saleItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantityReturned: quantityReturned ?? this.quantityReturned,
      originalQuantity: originalQuantity ?? this.originalQuantity,
      originalPrice: originalPrice ?? this.originalPrice,
      returnAmount: returnAmount ?? this.returnAmount,
      condition: condition ?? this.condition,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RefundModel {
  final String id;
  final String returnRequestId;
  final String returnNumber;
  final String saleInvoiceNumber;
  final String customerName;
  final String refundNumber;
  final DateTime refundDate;
  final double amount;
  final String method;
  final String status;
  final String? referenceNumber;
  final String? notes;
  final String? processedById;
  final String? processedByName;
  final DateTime? processedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdById;
  final String? createdByName;

  RefundModel({
    required this.id,
    required this.returnRequestId,
    required this.returnNumber,
    required this.saleInvoiceNumber,
    required this.customerName,
    required this.refundNumber,
    required this.refundDate,
    required this.amount,
    required this.method,
    required this.status,
    this.referenceNumber,
    this.notes,
    this.processedById,
    this.processedByName,
    this.processedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdById,
    this.createdByName,
  });

  String get formattedRefundDate => '${refundDate.day}/${refundDate.month}/${refundDate.year}';
  String get formattedAmount => 'PKR ${amount.toStringAsFixed(2)}';

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'PROCESSED':
        return 'Processed';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get methodColor {
    switch (method.toUpperCase()) {
      case 'CASH':
        return Colors.green;
      case 'CREDIT_NOTE':
        return Colors.blue;
      case 'EXCHANGE':
        return Colors.purple;
      case 'BANK_TRANSFER':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  String get methodDisplay {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Cash Refund';
      case 'CREDIT_NOTE':
        return 'Credit Note';
      case 'EXCHANGE':
        return 'Product Exchange';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      default:
        return method;
    }
  }

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 [RefundModel] Parsing refund JSON: $json');
    
    final returnRequestId = json['return_request_id']?.toString() ?? json['return_request']?.toString() ?? '';
    final returnNumber = json['return_number']?.toString() ?? '';
    final saleInvoiceNumber = json['sale_invoice_number']?.toString() ?? '';
    final customerName = json['customer_name']?.toString() ?? '';
    
    debugPrint('🔍 [RefundModel] Extracted fields:');
    debugPrint('  - returnRequestId: "$returnRequestId"');
    debugPrint('  - returnNumber: "$returnNumber"');
    debugPrint('  - saleInvoiceNumber: "$saleInvoiceNumber"');
    debugPrint('  - customerName: "$customerName"');
    
    final refundModel = RefundModel(
      id: json['id']?.toString() ?? '',
      returnRequestId: returnRequestId,
      returnNumber: returnNumber,
      saleInvoiceNumber: saleInvoiceNumber,
      customerName: customerName,
      refundNumber: json['refund_number']?.toString() ?? '',
      refundDate: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      referenceNumber: json['reference_number']?.toString(),
      notes: json['notes']?.toString(),
      processedById: json['processed_by']?.toString(),
      processedByName: json['processed_by_name']?.toString(),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      createdById: json['created_by']?.toString(),
      createdByName: json['created_by_name']?.toString(),
    );
    
    debugPrint('✅ [RefundModel] Created RefundModel with:');
    debugPrint('  - returnRequestId: "${refundModel.returnRequestId}"');
    debugPrint('  - returnNumber: "${refundModel.returnNumber}"');
    debugPrint('  - saleInvoiceNumber: "${refundModel.saleInvoiceNumber}"');
    debugPrint('  - customerName: "${refundModel.customerName}"');
    
    return refundModel;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'return_request': returnRequestId,
      'return_number': returnNumber,
      'sale_invoice_number': saleInvoiceNumber,
      'customer_name': customerName,
      'refund_number': refundNumber,
      'refund_date': refundDate.toIso8601String().split('T')[0],
      'amount': amount,
      'method': method,
      'status': status,
      'reference_number': referenceNumber,
      'notes': notes,
      'processed_by': processedById,
      'processed_by_name': processedByName,
      'processed_at': processedAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdById,
      'created_by_name': createdByName,
    };
  }

  RefundModel copyWith({
    String? id,
    String? returnRequestId,
    String? returnNumber,
    String? saleInvoiceNumber,
    String? customerName,
    String? refundNumber,
    DateTime? refundDate,
    double? amount,
    String? method,
    String? status,
    String? referenceNumber,
    String? notes,
    String? processedById,
    String? processedByName,
    DateTime? processedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdById,
    String? createdByName,
  }) {
    return RefundModel(
      id: id ?? this.id,
      returnRequestId: returnRequestId ?? this.returnRequestId,
      returnNumber: returnNumber ?? this.returnNumber,
      saleInvoiceNumber: saleInvoiceNumber ?? this.saleInvoiceNumber,
      customerName: customerName ?? this.customerName,
      refundNumber: refundNumber ?? this.refundNumber,
      refundDate: refundDate ?? this.refundDate,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      processedById: processedById ?? this.processedById,
      processedByName: processedByName ?? this.processedByName,
      processedAt: processedAt ?? this.processedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
