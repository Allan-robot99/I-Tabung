import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';

enum EndPeriodUnit { days, weeks, months }

class GoalPlannerConfirmedMilestone {
  const GoalPlannerConfirmedMilestone({
    required this.amount,
    required this.label,
    required this.rewardDescription,
    required this.description,
  });

  final double amount;
  final String label;
  final String rewardDescription;
  final String description;

  GoalPlannerConfirmedMilestone copyWith({
    double? amount,
    String? label,
    String? rewardDescription,
    String? description,
  }) {
    return GoalPlannerConfirmedMilestone(
      amount: amount ?? this.amount,
      label: label ?? this.label,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      description: description ?? this.description,
    );
  }
}

class GoalPlannerConfirmedPlan {
  const GoalPlannerConfirmedPlan({
    required this.targetAmount,
    required this.childContributionPercentage,
    required this.parentContributionPercentage,
    required this.childContributionAmount,
    required this.parentContributionAmount,
    required this.recurringPeriod,
    required this.recurringAmount,
    required this.recurringStartDate,
    required this.endPeriodValue,
    required this.endPeriodUnit,
    required this.deadline,
    required this.milestones,
  });

  final double targetAmount;
  final double childContributionPercentage;
  final double parentContributionPercentage;
  final double childContributionAmount;
  final double parentContributionAmount;
  final RecurringPeriod recurringPeriod;
  final double recurringAmount;
  final DateTime recurringStartDate;
  final int endPeriodValue;
  final EndPeriodUnit endPeriodUnit;
  final DateTime deadline;
  final List<GoalPlannerConfirmedMilestone> milestones;

  factory GoalPlannerConfirmedPlan.fromPlan({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
  }) {
    final now = DateTime.now();
    final recurringStartDate = DateTime(now.year, now.month, now.day);
    final deadline = _deadlineFromDuration(
      startDate: recurringStartDate,
      durationValue: output.endPeriodSuggestion.durationValue,
      durationUnit: output.endPeriodSuggestion.durationUnit,
    );
    return GoalPlannerConfirmedPlan(
      targetAmount: output.suggestedGoalAmount.amount,
      childContributionPercentage: output.contributionRatioSuggestion.childContributionPercentage,
      parentContributionPercentage: output.contributionRatioSuggestion.parentContributionPercentage,
      childContributionAmount: output.contributionRatioSuggestion.childContributionAmount,
      parentContributionAmount: output.contributionRatioSuggestion.parentContributionAmount,
      recurringPeriod: output.recurringTargetSuggestion.recurringType,
      recurringAmount: output.recurringTargetSuggestion.amount,
      recurringStartDate: recurringStartDate,
      endPeriodValue: output.endPeriodSuggestion.durationValue,
      endPeriodUnit: _unitFromWire(output.endPeriodSuggestion.durationUnit),
      deadline: deadline,
      milestones: output.milestoneRewardSuggestions
          .map(
            (m) => GoalPlannerConfirmedMilestone(
              amount: m.targetAmount,
              label: m.milestoneLabel,
              rewardDescription: m.rewardSuggestion,
              description: m.reason,
            ),
          )
          .toList(growable: false),
    );
  }

  GoalPlannerConfirmedPlan copyWith({
    double? targetAmount,
    double? childContributionPercentage,
    double? parentContributionPercentage,
    double? childContributionAmount,
    double? parentContributionAmount,
    RecurringPeriod? recurringPeriod,
    double? recurringAmount,
    DateTime? recurringStartDate,
    int? endPeriodValue,
    EndPeriodUnit? endPeriodUnit,
    DateTime? deadline,
    List<GoalPlannerConfirmedMilestone>? milestones,
  }) {
    return GoalPlannerConfirmedPlan(
      targetAmount: targetAmount ?? this.targetAmount,
      childContributionPercentage: childContributionPercentage ?? this.childContributionPercentage,
      parentContributionPercentage: parentContributionPercentage ?? this.parentContributionPercentage,
      childContributionAmount: childContributionAmount ?? this.childContributionAmount,
      parentContributionAmount: parentContributionAmount ?? this.parentContributionAmount,
      recurringPeriod: recurringPeriod ?? this.recurringPeriod,
      recurringAmount: recurringAmount ?? this.recurringAmount,
      recurringStartDate: recurringStartDate ?? this.recurringStartDate,
      endPeriodValue: endPeriodValue ?? this.endPeriodValue,
      endPeriodUnit: endPeriodUnit ?? this.endPeriodUnit,
      deadline: deadline ?? this.deadline,
      milestones: milestones ?? this.milestones,
    );
  }
  static EndPeriodUnit _unitFromWire(String value) {
    return switch (value) {
      'days' => EndPeriodUnit.days,
      'weeks' => EndPeriodUnit.weeks,
      _ => EndPeriodUnit.months,
    };
  }

  static DateTime _deadlineFromDuration({
    required DateTime startDate,
    required int durationValue,
    required String durationUnit,
  }) {
    return switch (durationUnit) {
      'days' => startDate.add(Duration(days: durationValue)),
      'weeks' => startDate.add(Duration(days: durationValue * 7)),
      _ => DateTime(startDate.year, startDate.month + durationValue, startDate.day),
    };
  }
}
