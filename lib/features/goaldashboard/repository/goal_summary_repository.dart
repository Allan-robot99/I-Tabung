import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:i_tabung/features/goaldashboard/models/goal_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final goalSummaryRepositoryProvider = Provider<GoalSummaryRepository>((ref) {
  return SupabaseGoalSummaryRepository(ref.watch(supabaseClientProvider));
});

abstract class GoalSummaryRepository {
  Future<GoalModel> loadGoal(String tabungId);
}

class SupabaseGoalSummaryRepository implements GoalSummaryRepository {
  SupabaseGoalSummaryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<GoalModel> loadGoal(String tabungId) async {
    final tabungRows = await _client
        .from('tabung_goals')
        .select(
          'id, tabung_name, tabung_type, goal_amount, current_amount, recurring_amount, recurring_period, deadline, reminder_enabled',
        )
        .eq('id', tabungId)
        .limit(1);

    if ((tabungRows as List).isEmpty) {
      throw Exception('Selected tabung could not be found.');
    }

    final row = tabungRows.first;
    final recurringPeriod = row['recurring_period']?.toString() ?? 'monthly';
    final periodStart = _periodStart(recurringPeriod);

    final savingsRows = await _client
        .from('savings_entries')
        .select('amount')
        .eq('tabung_id', tabungId)
        .gte('saved_at', periodStart.toIso8601String());

    final periodSaved = (savingsRows as List).fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
    );

    final calendarRows = await _client
        .from('calendar_events')
        .select('title, description, google_event_id, sync_status, timezone')
        .eq('tabung_id', tabungId)
        .eq('event_type', 'recurring_target')
        .order('created_at', ascending: false)
        .limit(1);

    final calendarSync = (calendarRows as List).isEmpty
        ? null
        : CalendarSync(
            platform: 'Google Calendar',
            eventTitle: calendarRows.first['title']?.toString() ?? 'I-Tabung reminder',
            eventDescription: calendarRows.first['description']?.toString() ?? '',
            syncStatus: calendarRows.first['sync_status']?.toString() ?? 'pending',
            timezone: calendarRows.first['timezone']?.toString() ?? 'Asia/Kuala_Lumpur',
            googleEventId: calendarRows.first['google_event_id']?.toString(),
          );

    final deadlineText = row['deadline']?.toString();
    final deadline = deadlineText == null ? null : DateTime.tryParse(deadlineText);
    final daysLeft = deadline == null ? 0 : deadline.difference(DateTime.now()).inDays.clamp(0, 100000);

    return GoalModel(
      id: row['id'] as String,
      name: row['tabung_name']?.toString() ?? 'Tabung',
      type: row['tabung_type']?.toString() ?? '',
      targetAmount: (row['goal_amount'] as num?)?.toDouble() ?? 0,
      savedAmount: (row['current_amount'] as num?)?.toDouble() ?? 0,
      periodTarget: (row['recurring_amount'] as num?)?.toDouble() ?? 0,
      periodSaved: periodSaved,
      periodLabel: _periodLabel(recurringPeriod),
      recurringPeriod: recurringPeriod,
      daysLeft: daysLeft,
      deadlineText: deadlineText,
      reminderEnabled: row['reminder_enabled'] as bool? ?? false,
      calendarSync: calendarSync,
    );
  }

  static DateTime _periodStart(String recurringPeriod) {
    final now = DateTime.now();
    switch (recurringPeriod) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - DateTime.monday));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  static String _periodLabel(String recurringPeriod) {
    switch (recurringPeriod) {
      case 'daily':
        return 'day';
      case 'weekly':
        return 'week';
      default:
        return 'month';
    }
  }
}
