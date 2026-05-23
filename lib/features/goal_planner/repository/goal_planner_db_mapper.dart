import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_confirmed_plan.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';

class GoalPlannerDbMapper {
  Map<String, dynamic> toTabungGoalColumns({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
    required String status,
  }) {
    return {
      'family_id': familyId,
      'child_id': childId,
      'created_by': createdBy,
      'tabung_type': input.tabungType.apiWireValue(),
      'tabung_name': input.tabungName,
      'description': input.tabungDescription,
      'reason': input.tabungDescription,
      'goal_amount': CurrencyUtils.roundToCents(confirmedPlan.targetAmount),
      'current_amount': 0,
      'initial_savings': 0,
      'desired_deadline': confirmedPlan.deadline.toIso8601String().split('T').first,
      'deadline': confirmedPlan.deadline.toIso8601String().split('T').first,
      'preferred_period_months': confirmedPlan.endPeriodUnit == EndPeriodUnit.months ? confirmedPlan.endPeriodValue : null,
      'status': status,
      'child_monthly_allowance': 0,
      'child_possible_monthly_saving': 0,
      'parent_support_needed': true,
      'parent_preferred_contribution': CurrencyUtils.roundToCents(confirmedPlan.parentContributionAmount),
      'recurring_amount': CurrencyUtils.roundToCents(output.recurringTargetSuggestion.amount),
      'recurring_period': output.recurringTargetSuggestion.recurringType.name,
      'recurring_start_date': confirmedPlan.recurringStartDate.toIso8601String().split('T').first,
      'recurring_reason': output.recurringTargetSuggestion.reason,
      'child_contribution_amount': CurrencyUtils.roundToCents(output.contributionRatioSuggestion.childContributionAmount),
      'parent_contribution_amount': CurrencyUtils.roundToCents(output.contributionRatioSuggestion.parentContributionAmount),
      'child_contribution_percentage': CurrencyUtils.roundToCents(output.contributionRatioSuggestion.childContributionPercentage),
      'parent_contribution_percentage': CurrencyUtils.roundToCents(output.contributionRatioSuggestion.parentContributionPercentage),
      'contribution_ratio_reason': output.contributionRatioSuggestion.reason,
      'period_suggestion_months': output.endPeriodSuggestion.durationUnit == 'months'
          ? output.endPeriodSuggestion.durationValue
          : null,
      'suggested_deadline': confirmedPlan.deadline.toIso8601String().split('T').first,
      'period_suggestion_reason': output.endPeriodSuggestion.reason,
      'difficulty_level': null,
      'ai_plan': output.toJson(),
      'ai_plan_summary': output.summary,
    };
  }
}
