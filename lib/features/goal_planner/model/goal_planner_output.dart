import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';

class SuggestedGoalAmount {
  const SuggestedGoalAmount({
    required this.amount,
    required this.reason,
  });

  final double amount;
  final String reason;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'reason': reason,
      };

  factory SuggestedGoalAmount.fromJson(Map<String, dynamic> json) {
    return SuggestedGoalAmount(
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }
}

class RecurringTargetSuggestion {
  const RecurringTargetSuggestion({
    required this.recurringType,
    required this.amount,
    required this.reason,
  });

  final RecurringPeriod recurringType;
  final double amount;
  final String reason;

  RecurringPeriod get period => recurringType;

  Map<String, dynamic> toJson() => {
        'recurringType': recurringType.wireValue(),
        'amount': amount,
        'reason': reason,
      };

  factory RecurringTargetSuggestion.fromJson(Map<String, dynamic> json) {
    final recurringValue = (json['recurringType'] ?? json['period']) as String?;
    return RecurringTargetSuggestion(
      amount: (json['amount'] as num).toDouble(),
      recurringType: RecurringPeriod.values.firstWhere(
        (e) => e.name == recurringValue,
        orElse: () => RecurringPeriod.weekly,
      ),
      reason: json['reason'] as String,
    );
  }
}

class MilestoneSuggestion {
  const MilestoneSuggestion({
    required this.targetAmount,
    required this.milestoneLabel,
    required this.rewardSuggestion,
    required this.reason,
  });

  final double targetAmount;
  final String milestoneLabel;
  final String rewardSuggestion;
  final String reason;

  double get amount => targetAmount;
  String get label => milestoneLabel;
  String get description => reason;
  String get rewardDescription => rewardSuggestion;

  Map<String, dynamic> toJson() => {
        'targetAmount': targetAmount,
        'milestoneLabel': milestoneLabel,
        'rewardSuggestion': rewardSuggestion,
        'reason': reason,
      };

  factory MilestoneSuggestion.fromJson(Map<String, dynamic> json) {
    return MilestoneSuggestion(
      targetAmount: (json['targetAmount'] as num).toDouble(),
      milestoneLabel: json['milestoneLabel'] as String,
      rewardSuggestion: json['rewardSuggestion'] as String,
      reason: json['reason'] as String,
    );
  }
}

class EndPeriodSuggestion {
  const EndPeriodSuggestion({
    required this.durationValue,
    required this.durationUnit,
    required this.reason,
  });

  final int durationValue;
  final String durationUnit;
  final String reason;

  int get recommendedMonths => durationUnit == 'months' ? durationValue : 0;

  Map<String, dynamic> toJson() => {
        'durationValue': durationValue,
        'durationUnit': durationUnit,
        'reason': reason,
      };

  factory EndPeriodSuggestion.fromJson(Map<String, dynamic> json) {
    return EndPeriodSuggestion(
      durationValue: (json['durationValue'] as num).round(),
      durationUnit: json['durationUnit'] as String,
      reason: json['reason'] as String,
    );
  }
}

class ContributionRatioSuggestion {
  const ContributionRatioSuggestion({
    required this.childContributionAmount,
    required this.parentContributionAmount,
    required this.childContributionPercentage,
    required this.parentContributionPercentage,
    required this.reason,
  });

  final double childContributionAmount;
  final double parentContributionAmount;
  final double childContributionPercentage;
  final double parentContributionPercentage;
  final String reason;

  double get childPercentage => childContributionPercentage;
  double get parentPercentage => parentContributionPercentage;

  Map<String, dynamic> toJson() => {
        'childContributionAmount': childContributionAmount,
        'parentContributionAmount': parentContributionAmount,
        'childContributionPercentage': childContributionPercentage,
        'parentContributionPercentage': parentContributionPercentage,
        'reason': reason,
      };

  factory ContributionRatioSuggestion.fromJson(Map<String, dynamic> json) {
    return ContributionRatioSuggestion(
      childContributionAmount: (json['childContributionAmount'] as num).toDouble(),
      parentContributionAmount: (json['parentContributionAmount'] as num).toDouble(),
      childContributionPercentage: (json['childContributionPercentage'] as num).toDouble(),
      parentContributionPercentage: (json['parentContributionPercentage'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }
}

class GoalPlannerOutput {
  const GoalPlannerOutput({
    required this.suggestedGoalAmount,
    required this.recurringTargetSuggestion,
    required this.milestoneRewardSuggestions,
    required this.endPeriodSuggestion,
    required this.contributionRatioSuggestion,
    required this.summary,
  });

  final SuggestedGoalAmount suggestedGoalAmount;
  final RecurringTargetSuggestion recurringTargetSuggestion;
  final List<MilestoneSuggestion> milestoneRewardSuggestions;
  final EndPeriodSuggestion endPeriodSuggestion;
  final ContributionRatioSuggestion contributionRatioSuggestion;
  final String summary;

  List<MilestoneSuggestion> get milestoneSuggestions => milestoneRewardSuggestions;
  EndPeriodSuggestion get periodSuggestion => endPeriodSuggestion;

  factory GoalPlannerOutput.fromJson(Map<String, dynamic> json) {
    return GoalPlannerOutput(
      suggestedGoalAmount: SuggestedGoalAmount.fromJson(
        json['suggestedGoalAmount'] as Map<String, dynamic>,
      ),
      recurringTargetSuggestion: RecurringTargetSuggestion.fromJson(
        json['recurringTargetSuggestion'] as Map<String, dynamic>,
      ),
      milestoneRewardSuggestions: (json['milestoneRewardSuggestions'] as List)
          .map((e) => MilestoneSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      endPeriodSuggestion: EndPeriodSuggestion.fromJson(
        json['endPeriodSuggestion'] as Map<String, dynamic>,
      ),
      contributionRatioSuggestion: ContributionRatioSuggestion.fromJson(
        json['contributionRatioSuggestion'] as Map<String, dynamic>,
      ),
      summary: json['summary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestedGoalAmount': suggestedGoalAmount.toJson(),
      'recurringTargetSuggestion': recurringTargetSuggestion.toJson(),
      'milestoneRewardSuggestions': milestoneRewardSuggestions.map((e) => e.toJson()).toList(),
      'endPeriodSuggestion': endPeriodSuggestion.toJson(),
      'contributionRatioSuggestion': contributionRatioSuggestion.toJson(),
      'summary': summary,
    };
  }
}
