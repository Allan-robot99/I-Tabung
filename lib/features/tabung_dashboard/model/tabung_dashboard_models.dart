class TabungDashboardData {
  const TabungDashboardData({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.status,
    required this.goalAmount,
    required this.currentAmount,
    required this.recurringAmount,
    required this.recurringPeriod,
    required this.childContributionPercentage,
    required this.parentContributionPercentage,
    required this.currentUserRole,
    required this.userContributionTargetAmount,
    required this.userContributionPercentage,
    required this.userTotalContributionAmount,
    required this.userRecurringTargetAmount,
    required this.currentPeriodContributionAmount,
    required this.currentPeriodContributionLabel,
    required this.summary,
    required this.milestones,
    this.latestTransaction,
  });

  final String id;
  final String name;
  final String type;
  final String description;
  final String status;
  final double goalAmount;
  final double currentAmount;
  final double recurringAmount;
  final String recurringPeriod;
  final double childContributionPercentage;
  final double parentContributionPercentage;
  final String currentUserRole;
  final double userContributionTargetAmount;
  final double userContributionPercentage;
  final double userTotalContributionAmount;
  final double userRecurringTargetAmount;
  final double currentPeriodContributionAmount;
  final String currentPeriodContributionLabel;
  final String summary;
  final List<TabungDashboardMilestone> milestones;
  final TabungDashboardTransaction? latestTransaction;
}

class TabungDashboardMilestone {
  const TabungDashboardMilestone({
    required this.amount,
    required this.label,
    required this.rewardDescription,
    required this.description,
  });

  final double amount;
  final String label;
  final String rewardDescription;
  final String description;
}

class TabungDashboardTransaction {
  const TabungDashboardTransaction({
    required this.purpose,
    required this.amount,
    required this.impactWarning,
    required this.recommendation,
  });

  final String purpose;
  final double amount;
  final String impactWarning;
  final String recommendation;
}
