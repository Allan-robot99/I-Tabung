import 'package:flutter/material.dart';
import 'package:i_tabung/features/goaldashboard/models/goal_model.dart';
import 'app_card.dart';
 
class CalendarSyncCard extends StatelessWidget {
  final CalendarSync calendarSync;
  final VoidCallback onViewInCalendar;
 
  const CalendarSyncCard({super.key, required this.calendarSync, required this.onViewInCalendar});
 
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(width: 8),
              Text('${calendarSync.syncStatus[0].toUpperCase()}${calendarSync.syncStatus.substring(1)} with ${calendarSync.platform}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            ],
          ),
          const SizedBox(height: 12),
          Text(calendarSync.eventTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text(calendarSync.eventDescription,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewInCalendar,
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text('View in Calendar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
