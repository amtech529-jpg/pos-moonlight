import 'package:flutter/material.dart';

class PaymentModel {
  final String id;
  final String? laborId;
  final String? vendorId;
  final String? orderId;
  final String? saleId;
  final String payerType;
  final String? payerId;
  final String? laborName;
  final String? laborPhone;
  final String? laborRole;
  final double amountPaid;
  final double bonus;
  final double deduction;
  final DateTime paymentMonth;
  final bool isFinalPayment;
  final String paymentMethod;
  final String? description;
  final DateTime date;
  final DateTime time;
  final String? receiptImagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  PaymentModel({
    required this.id,
    this.laborId,
    this.vendorId,
    this.orderId,
    this.saleId,
    required this.payerType,
    this.payerId,
    this.laborName,
    this.laborPhone,
    this.laborRole,
    required this.amountPaid,
    this.bonus = 0.0,
    this.deduction = 0.0,
    required this.paymentMonth,
    this.isFinalPayment = false,
    required this.paymentMethod,
    this.description,
    required this.date,
    required this.time,
    this.receiptImagePath,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  // Computed properties
  double get netAmount => amountPaid + bonus - deduction;
  String get formattedAmount => 'PKR ${netAmount.toStringAsFixed(2)}';
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
  String get formattedTime => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // Check if payment has a receipt
  bool get hasReceipt => receiptImagePath != null && receiptImagePath!.isNotEmpty;

  // Status properties
  String get statusText => isActive ? 'Active' : 'Inactive';
  Color get statusColor => isActive ? Colors.green : Colors.red;

  // Vendor information
  String get vendorName => vendorId != null ? 'Vendor $vendorId' : 'N/A';

  String get payerDisplayName {
    if (laborName != null && laborName!.isNotEmpty) {
      return '$laborName${laborRole != null ? ' ($laborRole)' : ''}';
    } else if (vendorId != null) {
      return 'Vendor';
    } else if (saleId != null) {
      return 'Sale Payment';
    } else if (orderId != null) {
      return 'Order Payment';
    }
    return payerType;
  }

  // Payment method display properties
  IconData get paymentMethodIcon {
    switch (paymentMethod.toUpperCase()) {
      case 'CASH':
        return Icons.money;
      case 'BANK_TRANSFER':
        return Icons.account_balance;
      case 'MOBILE_PAYMENT':
        return Icons.phone_android;
      case 'CHECK':
        return Icons.receipt;
      case 'CARD':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color get paymentMethodColor {
    switch (paymentMethod.toUpperCase()) {
      case 'CASH':
        return Colors.green;
      case 'BANK_TRANSFER':
        return Colors.blue;
      case 'MOBILE_PAYMENT':
        return Colors.orange;
      case 'CHECK':
        return Colors.purple;
      case 'CARD':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Factory constructor from JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      laborId: json['labor'] as String?,
      vendorId: json['vendor'] as String?,
      orderId: json['order'] as String?,
      saleId: json['sale'] as String?,
      payerType: json['payer_type'] as String,
      payerId: json['payer_id'] as String?,
      laborName: json['labor_name'] as String?,
      laborPhone: json['labor_phone'] as String?,
      laborRole: json['labor_role'] as String?,
      amountPaid: json['amount_paid'] is String ? double.parse(json['amount_paid'] as String) : (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      bonus: json['bonus'] is String ? double.parse(json['bonus'] as String) : (json['bonus'] as num?)?.toDouble() ?? 0.0,
      deduction: json['deduction'] is String ? double.parse(json['deduction'] as String) : (json['deduction'] as num?)?.toDouble() ?? 0.0,
      paymentMonth: DateTime.parse(json['payment_month'] as String),
      isFinalPayment: json['is_final_payment'] as bool? ?? false,
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      time: _parseTime(json['time'] as String? ?? '00:00:00'),
      receiptImagePath: json['receipt_image_path'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  // Helper method to parse time in different formats
  static DateTime _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return DateTime.now();
    }
    
    try {
      // Try parsing as full ISO datetime first (for backward compatibility)
      if (timeString.contains('T') || timeString.contains('-')) {
        return DateTime.parse(timeString);
      }
      
      // Parse as time-only format (HH:mm:ss)
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final second = parts.length > 2 ? int.parse(parts[2]) : 0;
        
        // Create DateTime with today's date and the parsed time
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute, second);
      }
      
      // Fallback to current time if parsing fails
      return DateTime.now();
    } catch (e) {
      // Fallback to current time if any error occurs
      return DateTime.now();
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'labor': laborId,
      'vendor': vendorId,
      'order': orderId,
      'sale': saleId,
      'payer_type': payerType,
      'payer_id': payerId,
      'labor_name': laborName,
      'labor_phone': laborPhone,
      'labor_role': laborRole,
      'amount_paid': amountPaid.toString(),
      'bonus': bonus.toString(),
      'deduction': deduction.toString(),
      'payment_month': paymentMonth.toIso8601String(),
      'is_final_payment': isFinalPayment,
      'payment_method': paymentMethod,
      'description': description,
      'date': date.toIso8601String(),
      'time': time.toIso8601String(),
      'receipt_image_path': receiptImagePath,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  // Copy with method
  PaymentModel copyWith({
    String? id,
    String? laborId,
    String? vendorId,
    String? orderId,
    String? saleId,
    String? payerType,
    String? payerId,
    String? laborName,
    String? laborPhone,
    String? laborRole,
    double? amountPaid,
    double? bonus,
    double? deduction,
    DateTime? paymentMonth,
    bool? isFinalPayment,
    String? paymentMethod,
    String? description,
    DateTime? date,
    DateTime? time,
    String? receiptImagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      laborId: laborId ?? this.laborId,
      vendorId: vendorId ?? this.vendorId,
      orderId: orderId ?? this.orderId,
      saleId: saleId ?? this.saleId,
      payerType: payerType ?? this.payerType,
      payerId: payerId ?? this.payerId,
      laborName: laborName ?? this.laborName,
      laborPhone: laborPhone ?? this.laborPhone,
      laborRole: laborRole ?? this.laborRole,
      amountPaid: amountPaid ?? this.amountPaid,
      bonus: bonus ?? this.bonus,
      deduction: deduction ?? this.deduction,
      paymentMonth: paymentMonth ?? this.paymentMonth,
      isFinalPayment: isFinalPayment ?? this.isFinalPayment,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Equality and hash code
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PaymentModel(id: $id, payerType: $payerType, amountPaid: $amountPaid, date: $date)';
  }
}

// Payment types and methods
class PaymentTypes {
  static const String labor = 'LABOR';
  static const String vendor = 'VENDOR';
  static const String customer = 'CUSTOMER';
  static const String other = 'OTHER';
}

class PaymentMethods {
  static const String cash = 'CASH';
  static const String bankTransfer = 'BANK_TRANSFER';
  static const String mobilePayment = 'MOBILE_PAYMENT';
  static const String check = 'CHECK';
  static const String card = 'CARD';
  static const String other = 'OTHER';
}

// Alias for backward compatibility
class Payment extends PaymentModel {
  Payment({
    required super.id,
    super.laborId,
    super.vendorId,
    super.orderId,
    super.saleId,
    required super.payerType,
    super.payerId,
    super.laborName,
    super.laborPhone,
    super.laborRole,
    required super.amountPaid,
    super.bonus = 0.0,
    super.deduction = 0.0,
    required super.paymentMonth,
    super.isFinalPayment = false,
    required super.paymentMethod,
    super.description,
    required super.date,
    required super.time,
    super.receiptImagePath,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.createdBy,
  });
}

// Payment Labor model for dropdown selection
class PaymentLabor {
  final String id;
  final String name;
  final String role;
  final double remainingAmount;
  final String? phone;

  PaymentLabor({required this.id, required this.name, required this.role, required this.remainingAmount, this.phone});

  factory PaymentLabor.fromJson(Map<String, dynamic> json) {
    return PaymentLabor(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role, 'remaining_amount': remainingAmount, 'phone': phone};
  }

  @override
  String toString() {
    return 'PaymentLabor(id: $id, name: $name, role: $role, remainingAmount: $remainingAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentLabor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
