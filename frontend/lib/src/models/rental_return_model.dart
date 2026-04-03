import 'package:flutter/material.dart';

class RentalReturnModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final DateTime returnDate;
  final String status;
  final String responsibility;
  final double damageCharges;
  final double damageRecovered;
  final bool isStockRestored;
  final int totalItemsDamaged;
  final int totalItemsMissing;
  final int totalItemsReturned;
  final int totalItemsSent;
  final String? notes;
  final List<RentalReturnItemModel> items;

  RentalReturnModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.returnDate,
    required this.status,
    required this.responsibility,
    required this.damageCharges,
    this.damageRecovered = 0.0,
    this.isStockRestored = false,
    this.totalItemsDamaged = 0,
    this.totalItemsMissing = 0,
    this.totalItemsReturned = 0,
    this.totalItemsSent = 0,
    this.notes,
    required this.items,
  });

  factory RentalReturnModel.fromJson(Map<String, dynamic> json) {
    return RentalReturnModel(
      id: json['id'] ?? '',
      orderId: json['order'] ?? '',
      orderNumber: json['order_number'] ?? '',
      customerName: json['customer_name'] ?? 'Unknown Customer',
      returnDate: DateTime.parse(json['return_date']),
      status: json['status'] ?? 'PENDING',
      responsibility: json['responsibility'] ?? 'NONE',
      damageCharges: double.tryParse(json['damage_charges']?.toString() ?? '0') ?? 0.0,
      damageRecovered: double.tryParse(json['damage_recovered']?.toString() ?? '0') ?? 0.0,
      isStockRestored: json['is_stock_restored'] ?? false,
      totalItemsDamaged: json['total_items_damaged'] ?? 0,
      totalItemsMissing: json['total_items_missing'] ?? 0,
      totalItemsReturned: json['total_items_returned'] ?? 0,
      totalItemsSent: json['total_items_sent'] ?? 0,
      notes: json['notes'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => RentalReturnItemModel.fromJson(item))
          .toList() ?? [],
    );
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PARTIAL':
        return Colors.blue;
      case 'COMPLETE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get itemsSummary {
    if (items.isEmpty) return 'No items';
    final partnerCount = items.where((i) => i.isPartnerItem).length;
    final partnerText = partnerCount > 0 ? ' ($partnerCount Partner)' : '';
    if (items.length == 1) return items.first.productName + partnerText;
    return '${items.length} items$partnerText';
  }
  
  int get totalDamaged => totalItemsDamaged > 0 
      ? totalItemsDamaged 
      : items.fold(0, (sum, item) => sum + item.qtyDamaged);
  int get totalMissing => totalItemsMissing > 0 
      ? totalItemsMissing 
      : items.fold(0, (sum, item) => sum + item.qtyMissing);

  double get recoveryBalance => damageCharges - damageRecovered;
  bool get isFullyRecovered => damageRecovered >= damageCharges;
}

class RentalReturnItemModel {
  final String id;
  final String productId;
  final String productName;
  final int qtySent;
  final int qtyReturned;
  final int qtyDamaged;
  final int qtyMissing;
  final double damageCharge;
  final String? conditionNotes;
  final bool isPartnerItem;

  RentalReturnItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qtySent,
    required this.qtyReturned,
    required this.qtyDamaged,
    required this.qtyMissing,
    required this.damageCharge,
    this.conditionNotes,
    this.isPartnerItem = false,
  });

  factory RentalReturnItemModel.fromJson(Map<String, dynamic> json) {
    return RentalReturnItemModel(
      id: json['id'] ?? '',
      productId: json['product'] ?? '',
      productName: json['product_name'] ?? 'Unknown Product',
      qtySent: json['qty_sent'] ?? 0,
      qtyReturned: json['qty_returned'] ?? 0,
      qtyDamaged: json['qty_damaged'] ?? 0,
      qtyMissing: json['qty_missing'] ?? 0,
      damageCharge: double.tryParse(json['damage_charge']?.toString() ?? '0') ?? 0.0,
      conditionNotes: json['condition_notes'],
      isPartnerItem: json['is_partner_item'] as bool? ?? false,
    );
  }
}
