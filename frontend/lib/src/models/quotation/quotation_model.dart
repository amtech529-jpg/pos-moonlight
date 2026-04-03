import 'dart:convert';

class QuotationModel {
  final String id;
  final String quotationNumber;
  final String? customer;
  final String? companyName;
  final String customerName;
  final String? customerPhone;
  final String eventName;
  final String? eventLocation;
  final DateTime? eventDate;
  final DateTime? returnDate;
  final DateTime validUntil;
  final String status;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? specialNotes;
  final List<QuotationItemModel> items;
  final DateTime createdAt;
  final String? createdByName;

  QuotationModel({
    required this.id,
    required this.quotationNumber,
    this.customer,
    this.companyName,
    required this.customerName,
    this.customerPhone,
    required this.eventName,
    this.eventLocation,
    this.eventDate,
    this.returnDate,
    required this.validUntil,
    required this.status,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    this.specialNotes,
    required this.items,
    required this.createdAt,
    this.createdByName,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'],
      quotationNumber: json['quotation_number'] ?? '',
      customer: json['customer'],
      companyName: json['company_name'],
      customerName: json['customer_name'] ?? 'Unknown',
      customerPhone: json['customer_phone'],
      eventName: json['event_name'] ?? 'General Event',
      eventLocation: json['event_location'],
      eventDate: json['event_date'] != null ? DateTime.parse(json['event_date']) : null,
      returnDate: json['return_date'] != null ? DateTime.parse(json['return_date']) : null,
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      finalAmount: double.tryParse(json['final_amount']?.toString() ?? '0') ?? 0.0,
      specialNotes: json['special_notes'],
      items: (json['items'] as List?)
              ?.map((i) => QuotationItemModel.fromJson(i))
              .toList() ??
          [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      createdByName: json['created_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer': customer,
      'company_name': companyName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'event_name': eventName,
      'event_location': eventLocation,
      'event_date': eventDate?.toIso8601String().split('T')[0],
      'return_date': returnDate?.toIso8601String().split('T')[0],
      'valid_until': validUntil.toIso8601String().split('T')[0],
      'status': status,
      'discount_amount': discountAmount,
      'special_notes': specialNotes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class QuotationItemModel {
  final String? id;
  final String? product;  // Made nullable for manual entries
  final String? productName;
  final int quantity;
  final double rate;
  final int days;
  final String pricingType;
  final double total;
  final bool rentedFromPartner;
  final String? partner;
  final double? partnerRate;

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'product_name': productName,
      'quantity': quantity,
      'rate': rate,
      'days': days,
      'pricing_type': pricingType,
      'rented_from_partner': rentedFromPartner,
      'partner': partner,
      'partner_rate': partnerRate,
    };
  }

  // UI Only field - Not persisted to DB
  final int? availableStock;

  QuotationItemModel({
    this.id,
    this.product,
    this.productName,
    required this.quantity,
    required this.rate,
    required this.days,
    this.pricingType = 'PER_DAY',
    required this.total,
    this.rentedFromPartner = false,
    this.partner,
    this.partnerRate,
    this.availableStock,
  });

  factory QuotationItemModel.fromJson(Map<String, dynamic> json) {
    return QuotationItemModel(
      id: json['id'],
      product: json['product'],
      productName: json['product_name'],
      quantity: json['quantity'] ?? 0,
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0.0,
      days: json['days'] ?? 1,
      pricingType: json['pricing_type'] ?? 'PER_DAY',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      rentedFromPartner: json['rented_from_partner'] ?? false,
      partner: json['partner'],
      partnerRate: double.tryParse(json['partner_rate']?.toString() ?? '0') ?? 0.0,
    );
  }
}
