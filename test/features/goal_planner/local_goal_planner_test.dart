import 'package:flutter_test/flutter_test.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/service/local_goal_planner.dart';

void main() {
  final planner = LocalGoalPlanner();

  GoalPlannerInput input({
    required TabungType type,
    required String name,
    required String description,
    UserRole role = UserRole.child,
  }) {
    return GoalPlannerInput(
      userRole: role,
      tabungType: type,
      tabungName: name,
      tabungDescription: description,
    );
  }

  test('ratio for electronic device goal adapts for parent-created device goals', () {
    final result = planner.generate(
      input(
        type: TabungType.electronicDevice,
        name: 'Laptop Fund',
        description: 'Need a device for personal projects and hobbies.',
        role: UserRole.parent,
      ),
    );
    expect(result.contributionRatioSuggestion.childContributionPercentage, 60);
    expect(result.contributionRatioSuggestion.parentContributionPercentage, 40);
  });

  test('large travel goals extend to a longer period', () {
    final result = planner.generate(
      input(
        type: TabungType.travel,
        name: 'Japan Trip',
        description: 'Overseas family travel to Japan next year.',
      ),
    );
    expect(result.endPeriodSuggestion.durationUnit, 'months');
    expect(result.endPeriodSuggestion.durationValue, greaterThanOrEqualTo(9));
  });

  test('milestones include 25/50/80/100 percent points', () {
    final result = planner.generate(
      input(
        type: TabungType.personalGrowth,
        name: 'Future Fund',
        description: 'Saving for future education and university costs.',
      ),
    );
    final amounts = result.milestoneRewardSuggestions.map((m) => m.targetAmount).toList();
    expect(amounts, containsAll(<double>[375, 750, 1200, 1500]));
  });

  test('small food goals use child-friendly daily or weekly recurring targets', () {
    final result = planner.generate(
      input(
        type: TabungType.food,
        name: 'Lunch Budget',
        description: 'Save for lunch meals and snacks.',
      ),
    );
    expect(
      {RecurringPeriod.daily, RecurringPeriod.weekly}.contains(result.recurringTargetSuggestion.recurringType),
      isTrue,
    );
  });
}
