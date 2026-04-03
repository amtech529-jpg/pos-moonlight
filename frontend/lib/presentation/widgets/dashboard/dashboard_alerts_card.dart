import 'package:flutter/material.dart';
import 'package:frontend/src/models/analytics/reminder_model.dart';
import 'package:intl/intl.dart';

class DashboardAlertsCard extends StatelessWidget {
  final List<ReminderModel> reminders;

  const DashboardAlertsCard({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: Color(0xFFBD0D1D), size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Action Needed & Reminders",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFBD0D1D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${reminders.length} Alerts",
                  style: const TextStyle(
                    color: Color(0xFFBD0D1D),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reminders.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return _buildReminderTile(reminder);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(ReminderModel reminder) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _buildIconBox(reminder),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPriorityBadge(reminder.priority),
              const SizedBox(height: 6),
              Text(
                _formatDate(reminder.date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBox(ReminderModel reminder) {
    IconData icon;
    Color color;

    switch (reminder.type) {
      case 'DISPATCH':
        icon = Icons.local_shipping_outlined;
        color = const Color(0xFF1976D2);
        break;
      case 'RETURN':
        icon = Icons.assignment_return_outlined;
        color = const Color(0xFF388E3C);
        break;
      case 'EVENT':
        icon = Icons.event_outlined;
        color = const Color(0xFF7B1FA2);
        break;
      case 'DUE':
        icon = Icons.priority_high_rounded;
        color = const Color(0xFFD32F2F);
        break;
      default:
        icon = Icons.notifications_none_outlined;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'CRITICAL':
        color = const Color(0xFFD32F2F);
        break;
      case 'HIGH':
        color = const Color(0xFFF57C00);
        break;
      case 'MEDIUM':
        color = const Color(0xFF1976D2);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reminderDate = DateTime(date.year, date.month, date.day);

      if (reminderDate == today) return "Today";
      if (reminderDate == today.add(const Duration(days: 1))) return "Tomorrow";
      
      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
