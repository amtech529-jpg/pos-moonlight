class ReminderModel {
  final String id;
  final String type; // DISPATCH, RETURN, EVENT, DUE
  final String title;
  final String subtitle;
  final String date;
  final String priority; // CRITICAL, HIGH, MEDIUM, LOW

  ReminderModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.priority,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      date: json['date'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
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
    };
  }
}
