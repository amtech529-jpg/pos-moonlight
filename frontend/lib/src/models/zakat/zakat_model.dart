import 'package:flutter/material.dart';

class Zakat {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final double amount;
  final String beneficiaryName;
  final String? beneficiaryContact;
  final String? notes;
  final String authorizedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByEmail;
  final bool? isActive;
  final bool? isVerified;
  final bool? isArchived;

  Zakat({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.time,
    required this.amount,
    required this.beneficiaryName,
    this.beneficiaryContact,
    this.notes,
    required this.authorizedBy,
    required this.createdAt,
    required this.updatedAt,
    this.createdByEmail,
    this.isActive = true,
    this.isVerified = false,
    this.isArchived = false,
  });

  // Formatted date for display
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formatted time for display
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Relative date (e.g., "Today", "Yesterday", "2 days ago")
  String get relativeDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(recordDate).inDays;

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

  // Combined date and time for sorting
  DateTime get dateTime {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Formatted amount for display
  String get formattedAmount {
    return 'PKR ${amount.toStringAsFixed(2)}';
  }

  // Beneficiary summary with contact if available
  String get beneficiarySummary {
    if (beneficiaryContact != null && beneficiaryContact!.isNotEmpty) {
      return '$beneficiaryName ($beneficiaryContact)';
    }
    return beneficiaryName;
  }

  // Authority initials for display
  String get authorizedInitials {
    final nameParts = authorizedBy.split(' ');
    String initials = '';
    for (final part in nameParts) {
      if (part.startsWith(RegExp(r'(Mr\.?|Mrs\.?|Ms\.?|Sheikh)'))) {
        continue;
      }
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase(); // FIXED: changed .upper() → .toUpperCase()
      }
    }
    return initials.isNotEmpty ? initials : authorizedBy.substring(0, 2).toUpperCase();
  }

  // Zakat summary for display
  String get zakatSummary {
    final summary = name.length > 50 ? '${name.substring(0, 47)}...' : name;
    return '$summary - ${formattedAmount}';
  }

  // Age in days since creation
  int get zakatAgeDays {
    return DateTime.now().difference(date).inDays;
  }

  // Status for display
  String get statusDisplayName {
    if (isArchived == true) return 'Archived';
    if (isActive == false) return 'Inactive';
    if (isVerified == true) return 'Verified';
    return 'Active';
  }

  // Copy method for updates
  Zakat copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    double? amount,
    String? beneficiaryName,
    String? beneficiaryContact,
    String? notes,
    String? authorizedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByEmail,
    bool? isActive,
    bool? isVerified,
    bool? isArchived,
  }) {
    return Zakat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      amount: amount ?? this.amount,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      beneficiaryContact: beneficiaryContact ?? this.beneficiaryContact,
      notes: notes ?? this.notes,
      authorizedBy: authorizedBy ?? this.authorizedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'amount': amount,
      'beneficiary_name': beneficiaryName,
      'beneficiary_contact': beneficiaryContact,
      'notes': notes,
      'authorized_by': authorizedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by_email': createdByEmail,
      'is_active': isActive,
      'is_verified': isVerified,
      'is_archived': isArchived,
    };
  }

  // Create from JSON API response
  factory Zakat.fromJson(Map<String, dynamic> json) {
    // Parse time string (HH:MM or HH:MM:SS format)
    TimeOfDay parseTime(String timeStr) {
      try {
        if (timeStr.isEmpty) return TimeOfDay(hour: 0, minute: 0);
        final parts = timeStr.split(':');
        if (parts.length < 2 || parts.length > 3) return TimeOfDay(hour: 0, minute: 0);
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        return TimeOfDay(hour: 0, minute: 0);
      }
    }

    // Handle null values safely
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Extract numeric amount from formatted amount string (e.g., "PKR 1,600.00" -> 1600.0)
    double extractAmountFromFormatted(String formattedAmount) {
      try {
        // Remove "PKR " prefix and commas, then parse
        final cleanAmount = formattedAmount.replaceAll('PKR ', '').replaceAll(',', '');
        return double.tryParse(cleanAmount) ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    DateTime safeDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Zakat(
      id: safeString(json['id']),
      name: safeString(json['name'] ?? json['zakat_summary'] ?? ''),
      description: safeString(json['description'] ?? ''),
      date: safeDateTime(json['date']),
      time: parseTime(safeString(json['time'] ?? '00:00')),
      amount: safeDouble(json['amount']) ?? extractAmountFromFormatted(safeString(json['formatted_amount'] ?? '')),
      beneficiaryName: safeString(json['beneficiary_name'] ?? ''),
      beneficiaryContact: json['beneficiary_contact'] != null ? safeString(json['beneficiary_contact']) : null,
      notes: json['notes'] != null ? safeString(json['notes']) : null,
      authorizedBy: safeString(json['authorized_by'] ?? ''),
      createdAt: safeDateTime(json['created_at']),
      updatedAt: safeDateTime(json['updated_at'] ?? json['created_at']),
      createdByEmail: json['created_by_name'] != null ? safeString(json['created_by_name']) : null,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: false, // Default to false since this field doesn't exist in backend
      isArchived: false, // Default to false since this field doesn't exist in backend
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Zakat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Zakat(id: $id, name: $name, amount: $amount, beneficiary: $beneficiaryName)';
  }
}

// Helper class for authorization choices
class ZakatAuthorities {
  static const List<String> authorities = ['Mr. Shahzain Baloch', 'Mr Huzaifa'];

  static String getDisplayName(String authority) {
    return authority;
  }

  static String getInitials(String authority) {
    final nameParts = authority.split(' ');
    String initials = '';
    for (final part in nameParts) {
      if (part.startsWith(RegExp(r'(Mr\.?|Mrs\.?|Ms\.?|Sheikh)'))) {
        continue;
      }
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
    }
    return initials.isNotEmpty ? initials : authority.substring(0, 2).toUpperCase();
  }
}
