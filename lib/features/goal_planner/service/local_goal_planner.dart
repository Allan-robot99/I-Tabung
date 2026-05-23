import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';

class LocalGoalPlanner {
  GoalPlannerOutput generate(GoalPlannerInput input) {
    final goalAmount = _inferGoalAmount(input);
    final ratio = _inferContributionRatio(input);
    final childAmount = _roundRm(goalAmount * (ratio.$1 / 100));
    final parentAmount = goalAmount - childAmount;
    final endPeriod = _inferEndPeriod(input.tabungType, goalAmount);
    final recurring = _inferRecurring(goalAmount, endPeriod);

    return GoalPlannerOutput(
      suggestedGoalAmount: SuggestedGoalAmount(
        amount: goalAmount.toDouble(),
        reason: 'Suggested from the selected tabung type and description.',
      ),
      recurringTargetSuggestion: recurring,
      milestoneRewardSuggestions: _buildMilestones(goalAmount.toDouble()),
      endPeriodSuggestion: endPeriod,
      contributionRatioSuggestion: ContributionRatioSuggestion(
        childContributionAmount: childAmount.toDouble(),
        parentContributionAmount: parentAmount.toDouble(),
        childContributionPercentage: ratio.$1.toDouble(),
        parentContributionPercentage: ratio.$2.toDouble(),
        reason: 'Suggested to balance child ownership with practical parent support.',
      ),
      summary:
          'For ${input.tabungName}, aim for RM$goalAmount with a ${recurring.recurringType.name} saving plan and shared family support.',
    );
  }

  int _inferGoalAmount(GoalPlannerInput input) {
    final text = '${input.tabungName} ${input.tabungDescription}'.toLowerCase();
    var amount = switch (input.tabungType) {
      TabungType.electronicDevice => 2500,
      TabungType.food => 300,
      TabungType.personalGrowth => 1000,
      TabungType.sportArt => 800,
      TabungType.travel => 1500,
    };

    if (input.tabungType == TabungType.electronicDevice) {
      if (RegExp(r'laptop|computer|macbook').hasMatch(text)) amount = 3500;
      if (RegExp(r'phone|tablet').hasMatch(text)) amount = 2200;
    }
    if (input.tabungType == TabungType.travel) {
      if (RegExp(r'overseas|japan|korea|europe').hasMatch(text)) amount = 4000;
      if (RegExp(r'local|melaka|penang|langkawi').hasMatch(text)) amount = 1500;
    }
    if (input.tabungType == TabungType.sportArt && RegExp(r'class|lesson|competition|equipment').hasMatch(text)) {
      amount = 900;
    }
    if (input.tabungType == TabungType.food && RegExp(r'lunch|meal|snacks').hasMatch(text)) {
      amount = 300;
    }
    if (input.tabungType == TabungType.personalGrowth &&
        RegExp(r'future|investment|education|university').hasMatch(text)) {
      amount = 1500;
    }

    return amount;
  }

  (int, int) _inferContributionRatio(GoalPlannerInput input) {
    final text = input.tabungDescription.toLowerCase();
    var childPercentage = switch (input.tabungType) {
      TabungType.electronicDevice => 70,
      TabungType.food => 60,
      TabungType.personalGrowth => 40,
      TabungType.sportArt => 60,
      TabungType.travel => 40,
    };

    if (input.userRole == UserRole.parent && input.tabungType == TabungType.electronicDevice) {
      childPercentage = 60;
    }
    if (RegExp(r'family|school|study|emergency|education').hasMatch(text)) {
      childPercentage = (childPercentage - 10).clamp(30, 90);
    }

    final parentPercentage = 100 - childPercentage;
    return (childPercentage, parentPercentage);
  }

  EndPeriodSuggestion _inferEndPeriod(TabungType type, int goalAmount) {
    var durationValue = switch (type) {
      TabungType.food => 4,
      TabungType.sportArt => 3,
      TabungType.personalGrowth => 6,
      TabungType.electronicDevice => 6,
      TabungType.travel => 6,
    };
    var durationUnit = type == TabungType.food ? 'weeks' : 'months';

    if (goalAmount > 3000) {
      durationValue = goalAmount >= 4000 ? 12 : 9;
      durationUnit = 'months';
    }

    return EndPeriodSuggestion(
      durationValue: durationValue,
      durationUnit: durationUnit,
      reason: durationUnit == 'weeks'
          ? 'Shorter goals work better with a focused weekly timeline.'
          : 'This timeline keeps the goal achievable while maintaining steady family progress.',
    );
  }

  RecurringTargetSuggestion _inferRecurring(int goalAmount, EndPeriodSuggestion endPeriod) {
    var type = RecurringPeriod.weekly;
    if (goalAmount <= 500) {
      type = goalAmount <= 300 ? RecurringPeriod.daily : RecurringPeriod.weekly;
    } else if (goalAmount > 3000) {
      final months = endPeriod.durationUnit == 'months' ? endPeriod.durationValue : 6;
      final monthly = goalAmount / months;
      type = monthly <= 700 ? RecurringPeriod.monthly : RecurringPeriod.weekly;
    }

    final amount = switch (type) {
      RecurringPeriod.daily => _roundToStep(goalAmount / _durationToDays(endPeriod), goalAmount <= 100 ? 1 : 5),
      RecurringPeriod.weekly => _roundToStep(goalAmount / _durationToWeeks(endPeriod), goalAmount <= 100 ? 1 : 5),
      RecurringPeriod.monthly => _roundToStep(goalAmount / _durationToMonths(endPeriod), goalAmount <= 100 ? 1 : 5),
    };

    return RecurringTargetSuggestion(
      recurringType: type,
      amount: amount.toDouble(),
      reason: switch (type) {
        RecurringPeriod.daily => 'A small daily target is easy to build into a saving habit.',
        RecurringPeriod.weekly => 'Weekly saving feels practical for regular family tracking.',
        RecurringPeriod.monthly => 'Monthly saving suits a larger goal with steadier contributions.',
      },
    );
  }

  List<MilestoneSuggestion> _buildMilestones(double goalAmount) {
    final percentages = [0.25, 0.5, 0.8, 1.0];
    final labels = ['First Step', 'Halfway There', 'Almost There', 'Goal Completed'];
    final rewards = [
      'Choose a favourite snack or small outing.',
      'Enjoy a simple family treat or extra playtime.',
      'Pick a family activity for the weekend.',
      'Celebrate with a family meal or achievement photo.',
    ];
    final reasons = [
      'An early reward helps build momentum and excitement.',
      'Midway rewards keep the goal fun without being expensive.',
      'A meaningful but affordable reward keeps focus strong near the finish.',
      'The final reward should feel memorable and family-centered.',
    ];

    return List.generate(
      percentages.length,
      (index) => MilestoneSuggestion(
        targetAmount: _roundRm(goalAmount * percentages[index]).toDouble(),
        milestoneLabel: labels[index],
        rewardSuggestion: rewards[index],
        reason: reasons[index],
      ),
      growable: false,
    );
  }

  int _durationToDays(EndPeriodSuggestion suggestion) {
    return switch (suggestion.durationUnit) {
      'days' => suggestion.durationValue,
      'weeks' => suggestion.durationValue * 7,
      _ => suggestion.durationValue * 30,
    };
  }

  int _durationToWeeks(EndPeriodSuggestion suggestion) {
    return switch (suggestion.durationUnit) {
      'days' => (suggestion.durationValue / 7).round().clamp(1, 10000),
      'weeks' => suggestion.durationValue,
      _ => suggestion.durationValue * 4,
    };
  }

  int _durationToMonths(EndPeriodSuggestion suggestion) {
    return switch (suggestion.durationUnit) {
      'days' => (suggestion.durationValue / 30).round().clamp(1, 10000),
      'weeks' => (suggestion.durationValue / 4).round().clamp(1, 10000),
      _ => suggestion.durationValue,
    };
  }

  int _roundRm(num value) => value.round();

  int _roundToStep(num value, int step) => ((value / step).round() * step).clamp(step, 1000000000);
}
