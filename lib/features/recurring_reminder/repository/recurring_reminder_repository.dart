import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:i_tabung/features/recurring_reminder/model/reminder_setup_request.dart';
import 'package:i_tabung/features/recurring_reminder/model/reminder_setup_response.dart';
import 'package:i_tabung/features/recurring_reminder/service/google_calendar_auth_service.dart';
import 'package:i_tabung/features/recurring_reminder/service/recurring_reminder_agent_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final recurringReminderRepositoryProvider = Provider<RecurringReminderRepository>((ref) {
  return SupabaseRecurringReminderRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(recurringReminderAgentServiceProvider),
    ref.watch(googleCalendarAuthServiceProvider),
  );
});

class ReminderContext {
  const ReminderContext({
    required this.userId,
    required this.familyId,
    required this.isCalendarConnected,
    required this.googleCalendarId,
  });

  final String userId;
  final String familyId;
  final bool isCalendarConnected;
  final String googleCalendarId;
}

abstract class RecurringReminderRepository {
  Future<ReminderContext> loadContext();
  Future<void> connectGoogleCalendar();
  Future<ReminderSetupResponse> previewReminder(ReminderSetupRequest request);
  Future<ReminderSetupResponse> createReminder(ReminderSetupRequest request);
}

class SupabaseRecurringReminderRepository implements RecurringReminderRepository {
  SupabaseRecurringReminderRepository(this._client, this._agentService, this._authService);

  final SupabaseClient _client;
  final RecurringReminderAgentService _agentService;
  final GoogleCalendarAuthService _authService;

  @override
  Future<ReminderContext> loadContext() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('User must be logged in.');
    }

    final familyRows = await _client.from('family_members').select('family_id').eq('user_id', userId).limit(1);
    if ((familyRows as List).isEmpty) {
      throw Exception('No family membership found for the current user.');
    }

    final connectionRows = await _client
        .from('calendar_connections')
        .select('is_connected, google_calendar_id')
        .eq('user_id', userId)
        .eq('provider', 'google')
        .limit(1);

    return ReminderContext(
      userId: userId,
      familyId: familyRows.first['family_id'] as String,
      isCalendarConnected: (connectionRows as List).isNotEmpty
          ? (connectionRows.first['is_connected'] as bool? ?? false)
          : false,
      googleCalendarId: (connectionRows as List).isNotEmpty
          ? (connectionRows.first['google_calendar_id']?.toString() ?? 'primary')
          : 'primary',
    );
  }

  @override
  Future<void> connectGoogleCalendar() => _authService.connectGoogleCalendar();

  @override
  Future<ReminderSetupResponse> previewReminder(ReminderSetupRequest request) {
    return _agentService.createPreview(request);
  }

  @override
  Future<ReminderSetupResponse> createReminder(ReminderSetupRequest request) {
    return _agentService.createReminder(request);
  }
}
