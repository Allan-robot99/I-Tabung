class ReminderSettings {
  const ReminderSettings({
    required this.reminderTime,
    this.reminderDayOfWeek,
    this.reminderDayOfMonth,
    this.calendarProvider = 'google',
    this.googleCalendarId = 'primary',
  });

  final String reminderTime;
  final String? reminderDayOfWeek;
  final int? reminderDayOfMonth;
  final String calendarProvider;
  final String googleCalendarId;

  Map<String, dynamic> toJson() => {
        'reminderTime': reminderTime,
        if (reminderDayOfWeek != null) 'reminderDayOfWeek': reminderDayOfWeek,
        if (reminderDayOfMonth != null) 'reminderDayOfMonth': reminderDayOfMonth,
        'calendarProvider': calendarProvider,
        'googleCalendarId': googleCalendarId,
      };
}

class ReminderSetupRequest {
  const ReminderSetupRequest({
    required this.mode,
    required this.userId,
    required this.familyId,
    required this.tabungId,
    required this.timezone,
    required this.reminderSettings,
  });

  final String mode;
  final String userId;
  final String familyId;
  final String tabungId;
  final String timezone;
  final ReminderSettings reminderSettings;

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'userId': userId,
        'familyId': familyId,
        'tabungId': tabungId,
        'timezone': timezone,
        'reminderSettings': reminderSettings.toJson(),
      };
}
