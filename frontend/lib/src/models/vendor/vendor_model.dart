import 'package:intl/intl.dart';

class VendorModel {
  final String id;
  final String name;
  final String businessName;
  final String displayName;
  final String initials;
  final String? cnic; // Make nullable
  final String phone;
  final String city;
  final String area;
  final String fullAddress;
  final bool isNewVendor;
  final int paymentsCount;
  final double totalPaymentsAmount;
  final bool isActive;
  final DateTime createdAt;
  final String? createdByEmail;

  const VendorModel({
    required this.id,
    required this.name,
    required this.businessName,
    required this.displayName,
    required this.initials,
    this.cnic, // Make nullable
    required this.phone,
    required this.city,
    required this.area,
    required this.fullAddress,
    required this.isNewVendor,
    required this.paymentsCount,
    required this.totalPaymentsAmount,
    required this.isActive,
    required this.createdAt,
    this.createdByEmail,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      businessName: json['business_name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '${json['business_name'] ?? ''} (${json['name']})',
      initials: json['initials'] as String? ?? _generateInitials(json['name'] as String),
      cnic: json['cnic'] as String?, // Handle null CNIC
      phone: json['phone'] as String,
      city: json['city'] as String? ?? '',
      area: json['area'] as String? ?? '',
      fullAddress: json['full_address'] as String? ?? '',
      isNewVendor: json['is_new_vendor'] as bool? ?? false,
      paymentsCount: json['payments_count'] as int? ?? 0,
      totalPaymentsAmount: (json['total_payments_amount'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdByEmail: json['created_by_email'] as String? ?? json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'business_name': businessName,
      'display_name': displayName,
      'initials': initials,
      'cnic': cnic, // Can be null
      'phone': phone,
      'city': city,
      'area': area,
      'full_address': fullAddress,
      'is_new_vendor': isNewVendor,
      'payments_count': paymentsCount,
      'total_payments_amount': totalPaymentsAmount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'created_by_email': createdByEmail,
    };
  }

  // Helper methods for formatting
  String get formattedPhone {
    if (phone.startsWith('+92')) {
      // Format: +92-XXX-XXXXXXX
      final cleanPhone = phone.replaceAll('+92', '').replaceAll('-', '');
      if (cleanPhone.length >= 10) {
        return '+92-${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3)}';
      }
    }
    return phone;
  }

  String get formattedCreatedAt {
    return DateFormat('MMM dd, yyyy').format(createdAt);
  }

  String get relativeCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  int get vendorAgeDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  String get statusDisplayName {
    return isActive ? 'Active' : 'Inactive';
  }

  VendorModel copyWith({
    String? id,
    String? name,
    String? businessName,
    String? displayName,
    String? initials,
    String? cnic,
    String? phone,
    String? city,
    String? area,
    String? fullAddress,
    bool? isNewVendor,
    int? paymentsCount,
    double? totalPaymentsAmount,
    bool? isActive,
    DateTime? createdAt,
    String? createdByEmail,
  }) {
    return VendorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      displayName: displayName ?? this.displayName,
      initials: initials ?? this.initials,
      cnic: cnic ?? this.cnic,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      area: area ?? this.area,
      fullAddress: fullAddress ?? this.fullAddress,
      isNewVendor: isNewVendor ?? this.isNewVendor,
      paymentsCount: paymentsCount ?? this.paymentsCount,
      totalPaymentsAmount: totalPaymentsAmount ?? this.totalPaymentsAmount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdByEmail: createdByEmail ?? this.createdByEmail,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VendorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VendorModel(id: $id, name: $name, businessName: $businessName, isActive: $isActive)';
  }

  // Fixed: Made this method static
  static String _generateInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'V';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
  }
}