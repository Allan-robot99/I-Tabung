import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_confirmed_plan.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';

class SubmissionContext {
  const SubmissionContext({
    required this.userId,
    required this.familyId,
    required this.childId,
    this.parentId,
  });

  final String userId;
  final String familyId;
  final String childId;
  final String? parentId;
}

abstract class GoalPlannerRepository {
  Future<GoalPlannerOutput> generatePlan(GoalPlannerInput input);
}

abstract class AnalyticsRepository {
  Future<void> trackEvent({
    required String name,
    required Map<String, dynamic> properties,
  });
}

abstract class UserContextRepository {
  Future<SubmissionContext> resolveSubmissionContext(UserRole creatorRole);
  Future<UserRole> getCurrentUserRole();
}

abstract class TabungRepository {
  Future<String> createPendingTabungWithPlan({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
  });

  Future<String> activateParentCreatedTabung({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
  });

  Future<void> approveTabung({required String tabungId, required String parentId, String? parentResponse});

  Future<void> rejectTabung({required String tabungId, required String rejectedReason});
}

abstract class MilestoneRepository {
  Future<void> insertSuggestedMilestones({
    required String tabungId,
    required List<MilestoneSuggestion> milestones,
  });
}

abstract class TabungRequestRepository {
  Future<void> createRequest({
    required String tabungId,
    required String requestedBy,
    required String familyId,
    String? parentId,
  });

  Future<List<Map<String, dynamic>>> fetchPendingForParent(String parentId);

  Future<void> approveRequest({required String requestId, String? parentResponse});

  Future<void> rejectRequest({required String requestId, required String parentResponse});
}
