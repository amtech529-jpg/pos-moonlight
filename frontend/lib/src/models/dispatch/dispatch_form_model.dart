import 'package:frontend/src/models/order/order_model.dart';

class DispatchItemModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final bool isExtra;

  DispatchItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.isExtra = false,
  });

  factory DispatchItemModel.fromJson(Map<String, dynamic> json) {
    return DispatchItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      quantity: json['quantity'] is int ? json['quantity'] : (int.tryParse(json['quantity']?.toString() ?? '0') ?? 0),
      isExtra: json['is_extra'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'product': productId,
      'product_name': productName,
      'quantity': quantity,
      'is_extra': isExtra,
    };
    if (id.isNotEmpty && !id.startsWith('temp_')) {
      data['id'] = id;
    }
    return data;
  }

  DispatchItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    bool? isExtra,
  }) {
    return DispatchItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      isExtra: isExtra ?? this.isExtra,
    );
  }
}

class DispatchFormModel {
  final String id;
  final String? orderId;
  final OrderModel? orderDetails;
  final String? customerId;
  final Map<String, dynamic>? customerDetails;
  final String driverName;
  final String vehicleNumber;
  final String? vehicleType;
  final String staffName;
  final String? eventName;
  final String? eventLocation;
  final DateTime createdAt;
  final String? createdBy;
  final String? createdByName;
  final DateTime? eventDate;
  final DateTime? dispatchDate;
  final DateTime? returnDate;
  final List<DispatchItemModel> items;

  DispatchFormModel({
    required this.id,
    this.orderId,
    this.orderDetails,
    this.customerId,
    this.customerDetails,
    required this.driverName,
    required this.vehicleNumber,
    this.vehicleType,
    required this.staffName,
    this.eventName,
    this.eventLocation,
    required this.createdAt,
    this.createdBy,
    this.createdByName,
    this.eventDate,
    this.dispatchDate,
    this.returnDate,
    this.items = const [],
  });

  factory DispatchFormModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return DispatchFormModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order']?.toString(),
      orderDetails: json['order_details'] != null ? OrderModel.fromJson(json['order_details']) : null,
      customerId: json['customer']?.toString(),
      customerDetails: json['customer_details'] as Map<String, dynamic>?,
      driverName: json['driver_name']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString(),
      staffName: json['staff_name']?.toString() ?? '',
      eventName: json['event_name']?.toString(),
      eventLocation: json['event_location']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      createdBy: json['created_by']?.toString(),
      createdByName: json['created_by_name']?.toString(),
      eventDate: json['event_date'] != null ? DateTime.tryParse(json['event_date'].toString()) : null,
      dispatchDate: json['dispatch_date'] != null ? DateTime.tryParse(json['dispatch_date'].toString()) : null,
      returnDate: json['return_date'] != null ? DateTime.tryParse(json['return_date'].toString()) : null,
      items: itemsList.map((i) => DispatchItemModel.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (orderId != null) 'order': orderId,
      if (customerId != null) 'customer': customerId,
      'driver_name': driverName,
      'vehicle_number': vehicleNumber,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      'staff_name': staffName,
      if (eventName != null) 'event_name': eventName,
      if (eventLocation != null) 'event_location': eventLocation,
      'event_date': eventDate?.toIso8601String().split('T')[0],
      'dispatch_date': dispatchDate?.toIso8601String().split('T')[0],
      'return_date': returnDate?.toIso8601String().split('T')[0],
      'items': items.where((i) => i.productId.isNotEmpty).map((i) => i.toJson()).toList(),
    };
  }

  DispatchFormModel copyWith({
    String? id,
    String? orderId,
    OrderModel? orderDetails,
    String? customerId,
    Map<String, dynamic>? customerDetails,
    String? driverName,
    String? vehicleNumber,
    String? vehicleType,
    String? staffName,
    String? eventName,
    String? eventLocation,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    DateTime? eventDate,
    DateTime? dispatchDate,
    DateTime? returnDate,
    List<DispatchItemModel>? items,
  }) {
    return DispatchFormModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderDetails: orderDetails ?? this.orderDetails,
      customerId: customerId ?? this.customerId,
      customerDetails: customerDetails ?? this.customerDetails,
      driverName: driverName ?? this.driverName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      staffName: staffName ?? this.staffName,
      eventName: eventName ?? this.eventName,
      eventLocation: eventLocation ?? this.eventLocation,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      eventDate: eventDate ?? this.eventDate,
      dispatchDate: dispatchDate ?? this.dispatchDate,
      returnDate: returnDate ?? this.returnDate,
      items: items ?? this.items,
    );
  }
}
