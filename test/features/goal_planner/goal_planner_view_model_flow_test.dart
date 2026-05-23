import 'package:flutter_test/flutter_test.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_confirmed_plan.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';
import 'package:i_tabung/features/goal_planner/repository/goal_planner_contracts.dart';
import 'package:i_tabung/features/goal_planner/service/goal_planner_exception.dart';
import 'package:i_tabung/features/goal_planner/view_model/goal_planner_view_model.dart';

class _FakePlannerRepo implements GoalPlannerRepository {
  _FakePlannerRepo(this.output, {this.throwOnce});

  final GoalPlannerOutput output;
  final GoalPlannerException? throwOnce;
  int _calls = 0;
  GoalPlannerInput? lastInput;

  @override
  Future<GoalPlannerOutput> generatePlan(GoalPlannerInput input) async {
    _calls += 1;
    lastInput = input;
    if (throwOnce != null && _calls == 1) {
      throw throwOnce!;
    }
    return output;
  }
}

class _FakeAnalyticsRepo implements AnalyticsRepository {
  final List<String> events = [];

  @override
  Future<void> trackEvent({required String name, required Map<String, dynamic> properties}) async {
    events.add(name);
  }
}

class _FakeUserContextRepo implements UserContextRepository {
  _FakeUserContextRepo(this.role);
  final UserRole role;

  @override
  Future<UserRole> getCurrentUserRole() async => role;

  @override
  Future<SubmissionContext> resolveSubmissionContext(UserRole creatorRole) async {
    return const SubmissionContext(
      userId: 'user-1',
      familyId: 'family-1',
      childId: 'child-1',
      parentId: 'parent-1',
    );
  }
}

class _FakeTabungRepo implements TabungRepository {
  int pendingCalls = 0;
  int activeCalls = 0;

  @override
  Future<String> activateParentCreatedTabung({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
  }) async {
    activeCalls += 1;
    return 'tabung-active-1';
  }

  @override
  Future<void> approveTabung({required String tabungId, required String parentId, String? parentResponse}) async {}

  @override
  Future<String> createPendingTabungWithPlan({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
  }) async {
    pendingCalls += 1;
    return 'tabung-pending-1';
  }

  @override
  Future<void> rejectTabung({required String tabungId, required String rejectedReason}) async {}
}

class _FakeMilestoneRepo implements MilestoneRepository {
  int calls = 0;

  @override
  Future<void> insertSuggestedMilestones({required String tabungId, required List<MilestoneSuggestion> milestones}) async {
    calls += 1;
  }
}

class _FakeRequestRepo implements TabungRequestRepository {
  int createCalls = 0;

  @override
  Future<void> approveRequest({required String requestId, String? parentResponse}) async {}

  @override
  Future<void> createRequest({required String tabungId, required String requestedBy, required String familyId, String? parentId}) async {
    createCalls += 1;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPendingForParent(String parentId) async => [];

  @override
  Future<void> rejectRequest({required String requestId, required String parentResponse}) async {}
}

GoalPlannerOutput _output() {
  return GoalPlannerOutput(
    suggestedGoalAmount: const SuggestedGoalAmount(amount: 5000, reason: 'ok'),
    recurringTargetSuggestion: const RecurringTargetSuggestion(
      recurringType: RecurringPeriod.weekly,
      amount: 100,
      reason: 'ok',
    ),
    milestoneRewardSuggestions: const [
      MilestoneSuggestion(
        targetAmount: 1000,
        milestoneLabel: 'A',
        rewardSuggestion: 'Reward',
        reason: 'B',
      ),
    ],
    endPeriodSuggestion: const EndPeriodSuggestion(
      durationValue: 6,
      durationUnit: 'months',
      reason: 'ok',
    ),
    contributionRatioSuggestion: const ContributionRatioSuggestion(
      childContributionAmount: 3000,
      parentContributionAmount: 2000,
      childContributionPercentage: 60,
      parentContributionPercentage: 40,
      reason: 'ok',
    ),
    summary: 'summary',
  );
}

GoalPlannerInput _input(UserRole role) {
  return GoalPlannerInput(
    userRole: role,
    tabungType: TabungType.electronicDevice,
    tabungName: 'Laptop Fund',
    tabungDescription: 'Need a laptop for study and school projects.',
  );
}

void main() {
  test('child submit path creates pending tabung + request', () async {
    final planner = _FakePlannerRepo(_output());
    final analytics = _FakeAnalyticsRepo();
    final tabung = _FakeTabungRepo();
    final milestones = _FakeMilestoneRepo();
    final requests = _FakeRequestRepo();
    final vm = GoalPlannerViewModel(planner, analytics, _FakeUserContextRepo(UserRole.child), tabung, milestones, requests);

    await vm.generatePlan(_input(UserRole.child));
    await vm.submitPlan();

    expect(tabung.pendingCalls, 1);
    expect(requests.createCalls, 1);
    expect(tabung.activeCalls, 0);
  });

  test('parent-created path activates directly', () async {
    final planner = _FakePlannerRepo(_output());
    final analytics = _FakeAnalyticsRepo();
    final tabung = _FakeTabungRepo();
    final milestones = _FakeMilestoneRepo();
    final requests = _FakeRequestRepo();
    final vm = GoalPlannerViewModel(planner, analytics, _FakeUserContextRepo(UserRole.parent), tabung, milestones, requests);

    await vm.generatePlan(_input(UserRole.parent));
    await vm.submitPlan();

    expect(tabung.pendingCalls, 0);
    expect(tabung.activeCalls, 1);
    expect(requests.createCalls, 0);
  });

  test('retry preserves idempotency key after timeout-style failure', () async {
    final planner = _FakePlannerRepo(
      _output(),
      throwOnce: const GoalPlannerException('agent_timeout', 'timeout'),
    );
    final analytics = _FakeAnalyticsRepo();
    final tabung = _FakeTabungRepo();
    final milestones = _FakeMilestoneRepo();
    final requests = _FakeRequestRepo();
    final vm = GoalPlannerViewModel(planner, analytics, _FakeUserContextRepo(UserRole.child), tabung, milestones, requests);

    await vm.generatePlan(_input(UserRole.child));
    final firstKey = vm.state.idempotencyKey;
    await vm.generatePlan(_input(UserRole.child));
    final secondKey = vm.state.idempotencyKey;

    expect(firstKey, isNotNull);
    expect(secondKey, equals(firstKey));
  });
}
