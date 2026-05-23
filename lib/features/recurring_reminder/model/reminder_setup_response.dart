import 'package:i_tabung/features/recurring_reminder/model/calendar_event_model.dart';

class ReminderPlanModel {
  const ReminderPlanModel({
    required this.title,
    required this.description,
    required this.recurringAmount,
    required this.recurringPeriod,
    required this.startDate,
    required this.endDate,
    required this.suggestedReminderDay,
    required this.suggestedReminderTime,
    required this.timezone,
  });

  final String title;
  final String description;
  final double recurringAmount;
  final String recurringPeriod;
  final String startDate;
  final String endDate;
  final String suggestedReminderDay;
  final String suggestedReminderTime;
  final String timezone;
}

class ReminderSetupResponse {
  const ReminderSetupResponse({
    required this.reminderPlan,
    required this.googleCalendarEvent,
    required this.userMessage,
    this.promptVersion,
  });

  final ReminderPlanModel reminderPlan;
  final CalendarEventModel googleCalendarEvent;
  final String userMessage;
  final String? promptVersion;

  factory ReminderSetupResponse.fromJson(Map<String, dynamic> json) {
    final reminderPlan = Map<String, dynamic>.from(json['reminderPlan'] as Map? ?? const {});
    final event = Map<String, dynamic>.from(json['googleCalendarEvent'] as Map? ?? const {});
    return ReminderSetupResponse(
      reminderPlan: ReminderPlanModel(
        title: reminderPlan['title']?.toString() ?? '',
        description: reminderPlan['description']?.toString() ?? '',
        recurringAmount: (reminderPlan['recurringAmount'] as num?)?.toDouble() ?? 0,
        recurringPeriod: reminderPlan['recurringPeriod']?.toString() ?? 'monthly',
        startDate: reminderPlan['startDate']?.toString() ?? '',
        endDate: reminderPlan['endDate']?.toString() ?? '',
        suggestedReminderDay: reminderPlan['suggestedReminderDay']?.toString() ?? '',
        suggestedReminderTime: reminderPlan['suggestedReminderTime']?.toString() ?? '',
        timezone: reminderPlan['timezone']?.toString() ?? 'Asia/Kuala_Lumpur',
      ),
      googleCalendarEvent: CalendarEventModel(
        summary: event['summary']?.toString() ?? '',
        description: event['description']?.toString() ?? '',
        startDateTime: event['startDateTime']?.toString() ?? '',
        endDateTime: event['endDateTime']?.toString() ?? '',
        recurrenceRule: event['recurrenceRule']?.toString() ?? '',
        googleEventId: event['googleEventId']?.toString(),
        syncStatus: event['syncStatus']?.toString(),
      ),
      userMessage: json['userMessage']?.toString() ?? '',
      promptVersion: json['promptVersion']?.toString(),
    );
  }
}
