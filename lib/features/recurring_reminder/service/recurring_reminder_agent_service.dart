import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:i_tabung/features/recurring_reminder/model/reminder_setup_request.dart';
import 'package:i_tabung/features/recurring_reminder/model/reminder_setup_response.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final recurringReminderAgentServiceProvider = Provider<RecurringReminderAgentService>((ref) {
  return SupabaseRecurringReminderAgentService(ref.watch(supabaseClientProvider));
});

abstract class RecurringReminderAgentService {
  Future<ReminderSetupResponse> createPreview(ReminderSetupRequest request);
  Future<ReminderSetupResponse> createReminder(ReminderSetupRequest request);
}

class SupabaseRecurringReminderAgentService implements RecurringReminderAgentService {
  SupabaseRecurringReminderAgentService(this._client);

  final SupabaseClient _client;

  @override
  Future<ReminderSetupResponse> createPreview(ReminderSetupRequest request) {
    return _invoke(request);
  }

  @override
  Future<ReminderSetupResponse> createReminder(ReminderSetupRequest request) {
    return _invoke(request);
  }

  Future<ReminderSetupResponse> _invoke(ReminderSetupRequest request) async {
    final response = await _client.functions.invoke(
      'recurring-goal-reminder-agent',
      body: request.toJson(),
    );
    final data = response.data;
    if (response.status >= 200 && response.status < 300 && data is Map<String, dynamic>) {
      return ReminderSetupResponse.fromJson(data);
    }
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        throw Exception(error['message']?.toString() ?? 'Recurring reminder request failed.');
      }
    }
    throw Exception('Invalid recurring reminder response.');
  }
}
