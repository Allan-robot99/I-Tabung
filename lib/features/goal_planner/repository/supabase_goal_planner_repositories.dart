import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_confirmed_plan.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';
import 'package:i_tabung/features/goal_planner/repository/goal_planner_contracts.dart';
import 'package:i_tabung/features/goal_planner/repository/goal_planner_db_mapper.dart';
import 'package:i_tabung/features/goal_planner/service/goal_planner_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    const url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://localhost:54321');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'demo-anon-key');
    return SupabaseClient(url, anonKey);
  }
});

final goalPlannerRepositoryProvider = Provider<GoalPlannerRepository>((ref) {
  return SupabaseGoalPlannerRepository(ref.watch(supabaseClientProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return SupabaseAnalyticsRepository(ref.watch(supabaseClientProvider));
});

final userContextRepositoryProvider = Provider<UserContextRepository>((ref) {
  return SupabaseUserContextRepository(ref.watch(supabaseClientProvider));
});

final tabungRepositoryProvider = Provider<TabungRepository>((ref) {
  return SupabaseTabungRepository(ref.watch(supabaseClientProvider));
});

final milestoneRepositoryProvider = Provider<MilestoneRepository>((ref) {
  return SupabaseMilestoneRepository(ref.watch(supabaseClientProvider));
});

final tabungRequestRepositoryProvider = Provider<TabungRequestRepository>((ref) {
  return SupabaseTabungRequestRepository(ref.watch(supabaseClientProvider));
});

class SupabaseGoalPlannerRepository implements GoalPlannerRepository {
  SupabaseGoalPlannerRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<GoalPlannerOutput> generatePlan(GoalPlannerInput input) async {
    try {
      final response = await _client.functions.invoke(
        'goal-planner-agent',
        body: {
          ...input.toJson(),
        },
      );
      final data = response.data;
      if (response.status >= 200 && response.status < 300 && data is Map<String, dynamic>) {
        return GoalPlannerOutput.fromJson(data);
      }

      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          throw GoalPlannerException(
            error['code']?.toString() ?? 'service_unavailable',
            error['message']?.toString() ?? 'Planner call failed.',
          );
        }
      }

      throw const GoalPlannerException('schema_invalid', 'Invalid planner response format.');
    } on GoalPlannerException {
      rethrow;
    } catch (_) {
      throw const GoalPlannerException('service_unavailable', 'Planner service unavailable.');
    }
  }
}

class SupabaseAnalyticsRepository implements AnalyticsRepository {
  SupabaseAnalyticsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> trackEvent({
    required String name,
    required Map<String, dynamic> properties,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('ai_logs').insert({
      'user_id': userId,
      'agent_type': 'goal_planner',
      'prompt': name,
      'structured_response': properties,
      'response': 'analytics_event',
    });
  }
}

class SupabaseUserContextRepository implements UserContextRepository {
  SupabaseUserContextRepository(this._client);

  final SupabaseClient _client;

  String _currentUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw const GoalPlannerException('invalid_input', 'User must be logged in.');
    }
    return id;
  }

  @override
  Future<UserRole> getCurrentUserRole() async {
    final userId = _currentUserId();
    final rows = await _client.from('profiles').select('role').eq('id', userId).limit(1);
    final role = (rows as List).first['role']?.toString();
    if (role == 'parent') return UserRole.parent;
    return UserRole.child;
  }

  Future<String?> _findFamilyMemberByRole({
    required String familyId,
    required String role,
    String? excludeUserId,
  }) async {
    final memberRows = await _client.from('family_members').select('user_id').eq('family_id', familyId);
    final memberIds = (memberRows as List)
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .where((id) => excludeUserId == null || id != excludeUserId)
        .toList(growable: false);

    if (memberIds.isEmpty) {
      return null;
    }

    final profileRows = await _client
        .from('profiles')
        .select('id, role')
        .inFilter('id', memberIds)
        .eq('role', role)
        .limit(1);

    if ((profileRows as List).isEmpty) {
      return memberIds.isNotEmpty ? memberIds.first : null;
    }

    return profileRows.first['id']?.toString();
  }

  @override
  Future<SubmissionContext> resolveSubmissionContext(UserRole creatorRole) async {
    final userId = _currentUserId();

    final familyRows = await _client.from('family_members').select('family_id').eq('user_id', userId).limit(1);
    if ((familyRows as List).isEmpty) {
      throw const GoalPlannerException('invalid_input', 'No family membership found for user.');
    }

    final familyId = familyRows.first['family_id'] as String;

    if (creatorRole == UserRole.child) {
      final parentId = await _findFamilyMemberByRole(
        familyId: familyId,
        role: 'parent',
        excludeUserId: userId,
      );
      return SubmissionContext(userId: userId, familyId: familyId, childId: userId, parentId: parentId);
    }

    final childId = await _findFamilyMemberByRole(
      familyId: familyId,
      role: 'child',
      excludeUserId: userId,
    );

    if (childId == null) {
      throw const GoalPlannerException('invalid_input', 'No child account found in this family for parent-created goal.');
    }

    return SubmissionContext(userId: userId, familyId: familyId, childId: childId, parentId: userId);
  }
}

class SupabaseTabungRepository implements TabungRepository {
  SupabaseTabungRepository(this._client) : _mapper = GoalPlannerDbMapper();

  final SupabaseClient _client;
  final GoalPlannerDbMapper _mapper;

  @override
  Future<String> createPendingTabungWithPlan({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
  }) async {
    final rows = await _client
        .from('tabung_goals')
        .insert(_mapper.toTabungGoalColumns(
          input: input,
          output: output,
          confirmedPlan: confirmedPlan,
          familyId: familyId,
          childId: childId,
          createdBy: createdBy,
          status: 'pending',
        ))
        .select('id');
    return rows.first['id'] as String;
  }

  @override
  Future<String> activateParentCreatedTabung({
    required GoalPlannerInput input,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
    required String familyId,
    required String childId,
    required String createdBy,
  }) async {
    final rows = await _client
        .from('tabung_goals')
        .insert(_mapper.toTabungGoalColumns(
          input: input,
          output: output,
          confirmedPlan: confirmedPlan,
          familyId: familyId,
          childId: childId,
          createdBy: createdBy,
          status: 'active',
        ))
        .select('id');
    return rows.first['id'] as String;
  }

  @override
  Future<void> approveTabung({required String tabungId, required String parentId, String? parentResponse}) async {
    await _client.from('tabung_goals').update({
      'status': 'active',
      'approved_by': parentId,
      'approved_at': DateTime.now().toIso8601String(),
      if (parentResponse != null && parentResponse.trim().isNotEmpty) 'description': parentResponse.trim(),
    }).eq('id', tabungId);
  }

  @override
  Future<void> rejectTabung({required String tabungId, required String rejectedReason}) async {
    await _client.from('tabung_goals').update({
      'status': 'rejected',
      'rejected_reason': rejectedReason,
    }).eq('id', tabungId);
  }
}

class SupabaseMilestoneRepository implements MilestoneRepository {
  SupabaseMilestoneRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> insertSuggestedMilestones({
    required String tabungId,
    required List<MilestoneSuggestion> milestones,
  }) async {
    await _client.from('milestones').insert(
          milestones
              .map(
                (m) => {
                  'tabung_id': tabungId,
                  'milestone_amount': m.amount,
                  'milestone_label': m.label,
                  'milestone_description': m.description,
                  'reward_description': m.rewardDescription,
                },
              )
              .toList(growable: false),
        );
  }
}

class SupabaseTabungRequestRepository implements TabungRequestRepository {
  SupabaseTabungRequestRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> createRequest({
    required String tabungId,
    required String requestedBy,
    required String familyId,
    String? parentId,
  }) async {
    await _client.from('tabung_requests').insert({
      'tabung_id': tabungId,
      'requested_by': requestedBy,
      'family_id': familyId,
      'parent_id': parentId,
      'status': 'pending',
    });
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPendingForParent(String parentId) async {
    final rows = await _client
        .from('tabung_requests')
        .select('id,status,tabung_id,created_at,tabung_goals(tabung_name,goal_amount)')
        .eq('parent_id', parentId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> approveRequest({required String requestId, String? parentResponse}) async {
    await _client.from('tabung_requests').update({
      'status': 'approved',
      'parent_response': parentResponse,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  @override
  Future<void> rejectRequest({required String requestId, required String parentResponse}) async {
    await _client.from('tabung_requests').update({
      'status': 'rejected',
      'parent_response': parentResponse,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
}

