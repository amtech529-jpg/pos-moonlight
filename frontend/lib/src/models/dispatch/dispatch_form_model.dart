import 'package:frontend/src/models/order/order_model.dart';

class DispatchFormModel {
  final String id;
  final String orderId;
  final OrderModel? orderDetails;
  final String driverName;
  final String vehicleNumber;
  final String staffName;
  final DateTime createdAt;
  final String? createdBy;
  final String? createdByName;

  DispatchFormModel({
    required this.id,
    required this.orderId,
    this.orderDetails,
    required this.driverName,
    required this.vehicleNumber,
    required this.staffName,
    required this.createdAt,
    this.createdBy,
    this.createdByName,
  });

  factory DispatchFormModel.fromJson(Map<String, dynamic> json) {
    return DispatchFormModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order']?.toString() ?? '',
      orderDetails: json['order_details'] != null ? OrderModel.fromJson(json['order_details']) : null,
      driverName: json['driver_name']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      createdBy: json['created_by']?.toString(),
      createdByName: json['created_by_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': orderId,
      'driver_name': driverName,
      'vehicle_number': vehicleNumber,
      'staff_name': staffName,
    };
  }

  DispatchFormModel copyWith({
    String? id,
    String? orderId,
    OrderModel? orderDetails,
    String? driverName,
    String? vehicleNumber,
    String? staffName,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
  }) {
    return DispatchFormModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderDetails: orderDetails ?? this.orderDetails,
      driverName: driverName ?? this.driverName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      staffName: staffName ?? this.staffName,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}

