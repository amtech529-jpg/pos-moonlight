import 'package:flutter/material.dart';

enum OrderStatus { PENDING, CONFIRMED, READY, DELIVERED, RETURNED, CANCELLED }

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final double advancePayment;
  final double totalAmount;
  final double remainingAmount;
  final bool isFullyPaid;
  final DateTime dateOrdered;
  final DateTime? expectedDeliveryDate;
  final String description;
  final OrderStatus status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int? createdById;
  
  // Event Details for Rental Business
  final String? eventName;
  final String? eventLocation;
  final DateTime? eventDate;
  final DateTime? returnDate;

  // Enhanced Sales Integration Fields
  final String conversionStatus;
  final double convertedSalesAmount;
  final DateTime? conversionDate;

  // Computed fields
  final int daysSinceOrdered;
  final int? daysUntilDelivery;
  final bool isOverdue;
  final double paymentPercentage;
  final Map<String, dynamic> orderSummary;
  final String deliveryStatus;
  final String returnStatus;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.advancePayment,
    required this.totalAmount,
    required this.remainingAmount,
    required this.isFullyPaid,
    required this.dateOrdered,
    this.expectedDeliveryDate,
    required this.description,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.createdById,
    required this.conversionStatus,
    required this.convertedSalesAmount,
    this.conversionDate,
    required this.daysSinceOrdered,
    this.daysUntilDelivery,
    required this.isOverdue,
    required this.paymentPercentage,
    required this.orderSummary,
    required this.deliveryStatus,
    required this.returnStatus,
    this.eventName,
    this.eventLocation,
    this.eventDate,
    this.returnDate,
  });

  // ✅ ADDED: orderNumber getter (Derived from ID for display)
  String get orderNumber => "ORD-${id.substring(0, 8).toUpperCase()}";

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      customerEmail: json['customer_email'] as String? ?? '',
      advancePayment: _parseDouble(json['advance_payment']),
      totalAmount: _parseDouble(json['total_amount']),
      remainingAmount: _parseDouble(json['remaining_amount']),
      isFullyPaid: json['is_fully_paid'] as bool? ?? false,
      dateOrdered: DateTime.parse(json['date_ordered'] as String),
      expectedDeliveryDate: json['expected_delivery_date'] != null ? DateTime.parse(json['expected_delivery_date'] as String) : null,
      description: json['description'] as String? ?? '',
      status: _parseOrderStatus(json['status'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      createdById: json['created_by_id'] as int?,
      conversionStatus: json['conversion_status'] as String? ?? 'NOT_CONVERTED',
      convertedSalesAmount: _parseDouble(json['converted_sales_amount']),
      conversionDate: json['conversion_date'] != null ? DateTime.parse(json['conversion_date'] as String) : null,
      daysSinceOrdered: json['days_since_ordered'] as int? ?? 0,
      daysUntilDelivery: json['days_until_delivery'] as int?,
      isOverdue: json['is_overdue'] as bool? ?? false,
      paymentPercentage: _parseDouble(json['payment_percentage']),
      orderSummary: json['order_summary'] as Map<String, dynamic>? ?? {},
      deliveryStatus: json['delivery_status'] as String? ?? 'No delivery date set',
      returnStatus: json['return_status'] as String? ?? 'NOT_STARTED',
      eventName: json['event_name'] as String?,
      eventLocation: json['event_location'] as String?,
      eventDate: json['event_date'] != null ? DateTime.parse(json['event_date'] as String) : null,
      returnDate: json['return_date'] != null ? DateTime.parse(json['return_date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'advance_payment': advancePayment,
      'total_amount': totalAmount,
      'remaining_amount': remainingAmount,
      'is_fully_paid': isFullyPaid,
      'date_ordered': dateOrdered.toIso8601String().split('T')[0],
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String().split('T')[0],
      'description': description,
      'status': status.name.toUpperCase(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'created_by_id': createdById,
      'conversion_status': conversionStatus,
      'converted_sales_amount': convertedSalesAmount,
      'conversion_date': conversionDate?.toIso8601String().split('T')[0],
      'days_since_ordered': daysSinceOrdered,
      'days_until_delivery': daysUntilDelivery,
      'is_overdue': isOverdue,
      'payment_percentage': paymentPercentage,
      'order_summary': orderSummary,
      'delivery_status': deliveryStatus,
      'return_status': returnStatus,
      'event_name': eventName,
      'event_location': eventLocation,
      'event_date': eventDate?.toIso8601String().split('T')[0],
      'return_date': returnDate?.toIso8601String().split('T')[0],
    };
  }

  // Helper method to parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to parse order status
  static OrderStatus _parseOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.PENDING;
      case 'CONFIRMED':
        return OrderStatus.CONFIRMED;
      case 'READY':
        return OrderStatus.READY;
      case 'DELIVERED':
        return OrderStatus.DELIVERED;
      case 'RETURNED':
        return OrderStatus.RETURNED;
      case 'CANCELLED':
        return OrderStatus.CANCELLED;
      default:
        return OrderStatus.PENDING;
    }
  }

  // Copy with method for updates
  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    double? advancePayment,
    double? totalAmount,
    double? remainingAmount,
    bool? isFullyPaid,
    DateTime? dateOrdered,
    DateTime? expectedDeliveryDate,
    String? description,
    OrderStatus? status,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? createdById,
    String? conversionStatus,
    double? convertedSalesAmount,
    DateTime? conversionDate,
    int? daysSinceOrdered,
    int? daysUntilDelivery,
    bool? isOverdue,
    double? paymentPercentage,
    Map<String, dynamic>? orderSummary,
    String? deliveryStatus,
    String? returnStatus,
    String? eventName,
    String? eventLocation,
    DateTime? eventDate,
    DateTime? returnDate,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      advancePayment: advancePayment ?? this.advancePayment,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      isFullyPaid: isFullyPaid ?? this.isFullyPaid,
      dateOrdered: dateOrdered ?? this.dateOrdered,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      description: description ?? this.description,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      conversionStatus: conversionStatus ?? this.conversionStatus,
      convertedSalesAmount: convertedSalesAmount ?? this.convertedSalesAmount,
      conversionDate: conversionDate ?? this.conversionDate,
      daysSinceOrdered: daysSinceOrdered ?? this.daysSinceOrdered,
      daysUntilDelivery: daysUntilDelivery ?? this.daysUntilDelivery,
      isOverdue: isOverdue ?? this.isOverdue,
      paymentPercentage: paymentPercentage ?? this.paymentPercentage,
      orderSummary: orderSummary ?? this.orderSummary,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      returnStatus: returnStatus ?? this.returnStatus,
      eventName: eventName ?? this.eventName,
      eventLocation: eventLocation ?? this.eventLocation,
      eventDate: eventDate ?? this.eventDate,
      returnDate: returnDate ?? this.returnDate,
    );
  }

  // Helper getters
  String get statusText {
    switch (status) {
      case OrderStatus.PENDING:
        return 'Pending';
      case OrderStatus.CONFIRMED:
        return 'Confirmed';
      case OrderStatus.READY:
        return 'Ready for Delivery';
      case OrderStatus.DELIVERED:
        return 'Delivered';
      case OrderStatus.RETURNED:
        return 'Returned';
      case OrderStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case OrderStatus.PENDING:
        return Colors.orange;
      case OrderStatus.CONFIRMED:
        return Colors.blue;
      case OrderStatus.READY:
        return Colors.purple;
      case OrderStatus.DELIVERED:
        return Colors.green;
      case OrderStatus.RETURNED:
        return Colors.teal;
      case OrderStatus.CANCELLED:
        return Colors.red;
    }
  }

  String get formattedTotalAmount => 'PKR ${totalAmount.toStringAsFixed(0)}';
  String get formattedAdvancePayment => 'PKR ${advancePayment.toStringAsFixed(0)}';
  String get formattedRemainingAmount => 'PKR ${remainingAmount.toStringAsFixed(0)}';
  String get formattedPaymentPercentage => '${paymentPercentage.toStringAsFixed(1)}%';

  String get formattedDateOrdered {
    return '${dateOrdered.day.toString().padLeft(2, '0')}/${dateOrdered.month.toString().padLeft(2, '0')}/${dateOrdered.year}';
  }

  String get formattedExpectedDeliveryDate {
    if (expectedDeliveryDate == null) return 'Not set';
    return '${expectedDeliveryDate!.day.toString().padLeft(2, '0')}/${expectedDeliveryDate!.month.toString().padLeft(2, '0')}/${expectedDeliveryDate!.year}';
  }

  String get relativeDateOrdered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(dateOrdered.year, dateOrdered.month, dateOrdered.day);
    final difference = today.difference(orderDate).inDays;
    return _getRelativeDateString(difference);
  }

  String _getRelativeDateString(int difference) {
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, customerName: $customerName, status: $status, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}