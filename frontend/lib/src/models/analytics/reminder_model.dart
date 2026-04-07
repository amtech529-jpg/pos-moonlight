class ReminderModel {
  final String id;
  final String type; // DISPATCH, RETURN, EVENT, DUE
  final String title;
  final String subtitle;
  final String date;
  final String priority; // CRITICAL, HIGH, MEDIUM, LOW
  final String? customerId;   // ✅ for Business Name resolution
  final String? customerName; // ✅ raw name from backend

  ReminderModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.priority,
    this.customerId,
    this.customerName,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      date: json['date'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'date': date,
      'priority': priority,
      'customer_id': customerId,
      'customer_name': customerName,
    };
  }
}
