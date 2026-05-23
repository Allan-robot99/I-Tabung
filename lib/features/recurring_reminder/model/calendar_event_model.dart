class CalendarEventModel {
  const CalendarEventModel({
    required this.summary,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.recurrenceRule,
    this.googleEventId,
    this.syncStatus,
  });

  final String summary;
  final String description;
  final String startDateTime;
  final String endDateTime;
  final String recurrenceRule;
  final String? googleEventId;
  final String? syncStatus;
}
