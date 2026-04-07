import 'package:frontend/src/models/product/product_model.dart';
import 'package:frontend/src/models/vendor/vendor_model.dart';

class PurchaseModel {
  final String? id;
  final String? vendor;
  final String? vendorName; // ✅ Added to capture 'vendor_name' from API
  final VendorModel? vendorDetail;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final double subtotal;
  final double tax;
  final double total;
  final String status;
  final List<PurchaseItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PurchaseModel({
    this.id,
    this.vendor,
    this.vendorName,
    this.vendorDetail,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id']?.toString(),
      vendor: json['vendor']?.toString(),
      // Robust vendor name parsing with multiple fallbacks
      vendorName: json['vendor_name']?.toString() ?? 
                  json['vendor_detail']?['name']?.toString() ?? 
                  json['vendor_info']?['name']?.toString() ?? 
                  (json['vendor'] is String ? null : null), // Don't use ID as name
      vendorDetail: json['vendor_detail'] != null
          ? VendorModel.fromJson(json['vendor_detail'])
          : null,
      // Robust invoice number parsing
      invoiceNumber: json['invoice_number']?.toString() ?? 
                     json['invoice_no']?.toString() ?? 
                     json['bill_no']?.toString() ?? 
                     '',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : DateTime.now(),
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0.0') ?? 0.0,
      tax: double.tryParse(json['tax']?.toString() ?? '0.0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0,
      status: json['status'] ?? 'draft',
      items: (json['items'] as List?)
          ?.map((item) => PurchaseItemModel.fromJson(item))
          .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vendor': vendor,
      'invoice_number': invoiceNumber,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      // Send numbers as Strings to ensure Backend DecimalFields accept them strictly
      'subtotal': subtotal.toStringAsFixed(2),
      'tax': tax.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  PurchaseModel copyWith({
    String? id,
    String? vendor,
    String? vendorName,
    String? invoiceNumber,
    DateTime? purchaseDate,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
    List<PurchaseItemModel>? items,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      vendor: vendor ?? this.vendor,
      vendorName: vendorName ?? this.vendorName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PurchaseItemModel {
  final String? id;
  final String? product;
  final String? productName; // ✅ Added
  final String? categoryName; // ✅ Added
  final String? categoryId; // ✅ Added
  final ProductModel? productDetail;
  final double quantity;
  final double unitCost;
  final double totalPrice;
  final String? description; // ✅ Added field

  PurchaseItemModel({
    this.id,
    this.product,
    this.productName,
    this.categoryName,
    this.categoryId,
    this.productDetail,
    required this.quantity,
    required this.unitCost,
    required this.totalPrice,
    this.description, // ✅ Added to constructor
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id']?.toString(),
      product: json['product']?.toString(),
      productName: json['product_name']?.toString(),
      categoryName: json['category_name']?.toString(),
      productDetail: json['product_detail'] != null
          ? ProductModel.fromJson(json['product_detail'])
          : null,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0.0') ?? 0.0,
      unitCost: double.tryParse(json['unit_cost']?.toString() ?? '0.0') ?? 0.0,
      // Check 'total_cost' (API standard) first, fallback to 'total_price'
      totalPrice: double.tryParse(json['total_cost']?.toString() ?? json['total_price']?.toString() ?? '0.0') ?? 0.0,
      description: json['description']?.toString(), // ✅ Added fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product': product,
      // Send as String for DecimalField safety
      'quantity': quantity.toStringAsFixed(2),
      'unit_cost': unitCost.toStringAsFixed(2),
      // ✅ REQUIRED KEY matches Backend Serializer
      'total_cost': totalPrice.toStringAsFixed(2),
      'description': description, // ✅ Added toJson
    };
  }

  PurchaseItemModel copyWith({
    String? id,
    String? product,
    String? productName,
    String? categoryName,
    String? categoryId,
    ProductModel? productDetail,
    double? quantity,
    double? unitCost,
    double? totalPrice,
    String? description, // ✅ Added description
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      productName: productName ?? this.productName,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      productDetail: productDetail ?? this.productDetail,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalPrice: totalPrice ?? this.totalPrice,
      description: description ?? this.description, // ✅ Added description
    );
  }
}