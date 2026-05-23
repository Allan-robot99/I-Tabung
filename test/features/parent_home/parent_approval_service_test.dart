import 'package:flutter_test/flutter_test.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_confirmed_plan.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';
import 'package:i_tabung/features/goal_planner/repository/goal_planner_contracts.dart';
import 'package:i_tabung/features/parent_home/service/parent_approval_service.dart';

class _FakeUserContextRepo implements UserContextRepository {
  @override
  Future<UserRole> getCurrentUserRole() async => UserRole.parent;

  @override
  Future<SubmissionContext> resolveSubmissionContext(UserRole creatorRole) async {
    return const SubmissionContext(userId: 'parent-1', familyId: 'family-1', childId: 'child-1', parentId: 'parent-1');
  }
}

class _FakeRequestRepo implements TabungRequestRepository {
  String? approvedRequestId;
  String? rejectedRequestId;

  @override
  Future<void> approveRequest({required String requestId, String? parentResponse}) async {
    approvedRequestId = requestId;
  }

  @override
  Future<void> rejectRequest({required String requestId, required String parentResponse}) async {
    rejectedRequestId = requestId;
  }

  @override
  Future<void> createRequest({required String tabungId, required String requestedBy, required String familyId, String? parentId}) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchPendingForParent(String parentId) async => [];
}

class _FakeTabungRepo implements TabungRepository {
  String? approvedTabungId;
  String? rejectedTabungId;

  @override
  Future<void> approveTabung({required String tabungId, required String parentId, String? parentResponse}) async {
    approvedTabungId = tabungId;
  }

  @override
  Future<void> rejectTabung({required String tabungId, required String rejectedReason}) async {
    rejectedTabungId = tabungId;
  }

  @override
  Future<String> activateParentCreatedTabung({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
  }) async => 'x';

  @override
  Future<String> createPendingTabungWithPlan({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
  }) async => 'x';
}

void main() {
  test('approve updates request and tabung', () async {
    final req = _FakeRequestRepo();
    final tab = _FakeTabungRepo();

    final service = ParentApprovalService(
      userContextRepository: _FakeUserContextRepo(),
      tabungRequestRepository: req,
      tabungRepository: tab,
    );

    await service.approve(requestId: 'req-1', tabungId: 'tab-1');
    expect(req.approvedRequestId, 'req-1');
    expect(tab.approvedTabungId, 'tab-1');
  });

  test('reject updates request and tabung', () async {
    final req = _FakeRequestRepo();
    final tab = _FakeTabungRepo();

    final service = ParentApprovalService(
      userContextRepository: _FakeUserContextRepo(),
      tabungRequestRepository: req,
      tabungRepository: tab,
    );

    await service.reject(requestId: 'req-2', tabungId: 'tab-2', reason: 'No');
    expect(req.rejectedRequestId, 'req-2');
    expect(tab.rejectedTabungId, 'tab-2');
  });
}
