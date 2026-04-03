import 'package:flutter/material.dart';

class AdvancePayment {
  final String id;
  final String laborId;
  final String laborName;
  final String laborPhone;
  final String laborRole;
  final double amount;
  final String description;
  final DateTime date;
  final String time; // HH:MM format from API
  final String? receiptImagePath;
  final double remainingSalary;
  final double totalSalary;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdById;
  final String? createdByName;

  AdvancePayment({
    required this.id,
    required this.laborId,
    required this.laborName,
    required this.laborPhone,
    required this.laborRole,
    required this.amount,
    required this.description,
    required this.date,
    required this.time,
    this.receiptImagePath,
    required this.remainingSalary,
    required this.totalSalary,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdById,
    this.createdByName,
  });

  // Convert TimeOfDay to string for API
  String get timeText => time;

  // Convert string time to TimeOfDay for UI
  TimeOfDay get timeOfDay {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String get dateTimeText => '${date.day}/${date.month}/${date.year} at $timeText';

  bool get hasReceipt => receiptImagePath != null && receiptImagePath!.isNotEmpty;

  double get advancePercentage => totalSalary > 0 ? (amount / totalSalary * 100) : 0;

  Color get statusColor {
    if (remainingSalary <= 0) return Colors.red;
    if (advancePercentage >= 80) return Colors.orange;
    if (advancePercentage >= 50) return Colors.yellow[700]!;
    return Colors.green;
  }

  String get statusText {
    if (remainingSalary <= 0) return 'Salary Exhausted';
    if (advancePercentage >= 80) return 'High Advance';
    if (advancePercentage >= 50) return 'Medium Advance';
    return 'Low Advance';
  }

  String get formattedAmount => 'PKR ${amount.toStringAsFixed(2)}';
  String get formattedRemainingSalary => 'PKR ${remainingSalary.toStringAsFixed(2)}';
  String get formattedTotalSalary => 'PKR ${totalSalary.toStringAsFixed(2)}';

  // JSON serialization
  factory AdvancePayment.fromJson(Map<String, dynamic> json) {
    try {
      return AdvancePayment(
        id: json['id'] ?? '',
        // Handle both labor_id (from create response) and labor (from list response)
        laborId: json['labor_id'] ?? json['labor'] ?? '',
        laborName: json['labor_name'] ?? '',
        laborPhone: json['labor_phone'] ?? '',
        laborRole: json['labor_role'] ?? '',
        amount: (json['amount'] is String) ? double.parse(json['amount']) : (json['amount'] ?? 0.0),
        description: json['description'] ?? '',
        date: DateTime.parse(json['date']),
        time: json['time'] ?? '00:00',
        receiptImagePath: json['receipt_image_path'],
        remainingSalary: (json['remaining_salary'] is String) ? double.parse(json['remaining_salary']) : (json['remaining_salary'] ?? 0.0),
        totalSalary: (json['total_salary'] is String) ? double.parse(json['total_salary']) : (json['total_salary'] ?? 0.0),
        isActive: json['is_active'] ?? true,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
        // Fix: Handle both created_by_email (string) and created_by (object) cases safely
        createdById:
            json['created_by_email'] ??
            (json['created_by'] is Map<String, dynamic> ? json['created_by']['id']?.toString() : json['created_by_id']?.toString()),
        createdByName:
            json['created_by_email'] ?? (json['created_by'] is Map<String, dynamic> ? json['created_by']['name'] : json['created_by_name']),
      );
    } catch (e) {
      // Log the error and return a default object to prevent crashes
      print('Error parsing AdvancePayment from JSON: $e');
      print('JSON data: $json');

      // Return a default object with safe values
      return AdvancePayment(
        id: json['id']?.toString() ?? '',
        laborId: json['labor_id']?.toString() ?? json['labor']?.toString() ?? '',
        laborName: json['labor_name']?.toString() ?? 'Unknown',
        laborPhone: json['labor_phone']?.toString() ?? '',
        laborRole: json['labor_role']?.toString() ?? '',
        amount: 0.0,
        description: json['description']?.toString() ?? '',
        date: DateTime.now(),
        time: '00:00',
        receiptImagePath: json['receipt_image_path']?.toString(),
        remainingSalary: 0.0,
        totalSalary: 0.0,
        isActive: json['is_active'] ?? true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdById: null,
        createdByName: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'labor_id': laborId,
      'labor_name': laborName,
      'labor_phone': laborPhone,
      'labor_role': laborRole,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'receipt_image_path': receiptImagePath,
      'remaining_salary': remainingSalary,
      'total_salary': totalSalary,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by_id': createdById,
      'created_by_name': createdByName,
    };
  }

  // Copy with method
  AdvancePayment copyWith({
    String? id,
    String? laborId,
    String? laborName,
    String? laborPhone,
    String? laborRole,
    double? amount,
    String? description,
    DateTime? date,
    String? time,
    String? receiptImagePath,
    double? remainingSalary,
    double? totalSalary,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdById,
    String? createdByName,
  }) {
    return AdvancePayment(
      id: id ?? this.id,
      laborId: laborId ?? this.laborId,
      laborName: laborName ?? this.laborName,
      laborPhone: laborPhone ?? this.laborPhone,
      laborRole: laborRole ?? this.laborRole,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      remainingSalary: remainingSalary ?? this.remainingSalary,
      totalSalary: totalSalary ?? this.totalSalary,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvancePayment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AdvancePayment(id: $id, laborName: $laborName, amount: $amount, date: $date)';
  }
}

// Labor model for dropdown selection
class Labor {
  final String id;
  final String name;
  final String phone;
  final String role;
  final double monthlySalary;
  final double totalAdvancesTaken;

  Labor({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.monthlySalary,
    required this.totalAdvancesTaken,
  });

  double get remainingSalary => monthlySalary - totalAdvancesTaken;

  factory Labor.fromJson(Map<String, dynamic> json) {
    return Labor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone_number'] ?? json['phone'] ?? '',
      role: json['designation'] ?? json['role'] ?? '',
      monthlySalary: (json['salary'] is String) ? double.parse(json['salary']) : (json['salary'] ?? 0.0),
      totalAdvancesTaken: (json['total_advances_taken'] is String)
          ? double.parse(json['total_advances_taken'])
          : (json['total_advances_taken'] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone_number': phone, 'designation': role, 'salary': monthlySalary, 'total_advances_taken': totalAdvancesTaken};
  }
}
