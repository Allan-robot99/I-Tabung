class GoalModel {
  final String id;
  final String name;
  final String type;
  final double targetAmount;
  final double savedAmount;
  final double periodTarget;
  final double periodSaved;
  final String periodLabel;
  final String recurringPeriod;
  final int daysLeft;
  final String? deadlineText;
  final bool reminderEnabled;
  final CatchUpPlan? catchUpPlan;
  final CalendarSync? calendarSync;
 
  GoalModel({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.savedAmount,
    required this.periodTarget,
    required this.periodSaved,
    required this.periodLabel,
    required this.recurringPeriod,
    required this.daysLeft,
    this.deadlineText,
    this.reminderEnabled = false,
    this.catchUpPlan,
    this.calendarSync,
  });
 
  double get progressPercentage => targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);
  double get remainingForPeriod => (periodTarget - periodSaved).clamp(0.0, double.infinity);
  bool get isOnTrack => periodTarget <= 0 ? true : periodSaved >= periodTarget;
 
  String get formattedSaved => 'RM${savedAmount.toStringAsFixed(0)}';
  String get formattedTarget => 'RM${targetAmount.toStringAsFixed(0)}';
  String get formattedRemaining => 'RM${remainingForPeriod.toStringAsFixed(0)}';
}
 
class CatchUpPlan {
  final double dailyAmount;
  final int days;
  bool isAccepted;
 
  CatchUpPlan({
    required this.dailyAmount,
    required this.days,
    this.isAccepted = false,
  });
 
  String get formattedDaily => 'RM${dailyAmount.toStringAsFixed(0)}';
}
 
class CalendarSync {
  final String platform;
  final String eventTitle;
  final String eventDescription;
  final String syncStatus;
  final String timezone;
  final String? googleEventId;
 
  const CalendarSync({
    required this.platform,
    required this.eventTitle,
    required this.eventDescription,
    required this.syncStatus,
    required this.timezone,
    this.googleEventId,
  });
}
