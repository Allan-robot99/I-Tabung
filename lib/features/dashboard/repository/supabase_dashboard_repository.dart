import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/dashboard/model/dashboard_models.dart';
import 'package:i_tabung/features/dashboard/repository/dashboard_repository.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return SupabaseDashboardRepository(ref.watch(supabaseClientProvider));
});

class SupabaseDashboardRepository implements DashboardRepository {
  SupabaseDashboardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<DashboardData> loadDashboard(UserRole role) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return DashboardData.empty();
    }
    final userId = currentUser.id;

    final familyMemberRows = await _client.from('family_members').select('family_id').eq('user_id', userId).limit(1);
    if ((familyMemberRows as List).isEmpty) {
      return DashboardData.empty();
    }
    final familyId = familyMemberRows.first['family_id'] as String;

    final profileRows = await _client.from('profiles').select('full_name').eq('id', userId).limit(1);
    final fullName = (profileRows as List).isNotEmpty ? (profileRows.first['full_name']?.toString() ?? 'User') : 'User';

    String? familyCode;
    if (role == UserRole.parent) {
      final familyRows = await _client.from('families').select('invite_code').eq('id', familyId).limit(1);
      if ((familyRows as List).isNotEmpty) {
        familyCode = familyRows.first['invite_code']?.toString();
      }
    }

    final memberRows = await _client.from('family_members').select('user_id').eq('family_id', familyId);
    final memberIds = (memberRows as List)
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .where((id) => id != userId)
        .toList(growable: false);

    final childProfileRows = memberIds.isEmpty
        ? const []
        : await _client.from('profiles').select('id').inFilter('id', memberIds).eq('role', 'child').limit(1);
    final hasChildInFamily = childProfileRows.isNotEmpty || memberIds.isNotEmpty;

    final tabungRows = await _client
        .from('tabung_goals')
        .select('id,tabung_name,goal_amount,current_amount,status,tabung_type')
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .limit(10);

    final txRows = await _client
        .from('payment_transactions')
        .select('purpose,amount')
        .eq('family_id', familyId)
        .eq('status', 'confirmed')
        .order('created_at', ascending: false)
        .limit(5);

    final tabungs = (tabungRows as List)
        .map(
          (e) => DashboardTabungSummary(
            id: e['id'] as String,
            name: e['tabung_name']?.toString() ?? 'Tabung',
            goalAmount: (e['goal_amount'] as num?)?.toDouble() ?? 0,
            currentAmount: (e['current_amount'] as num?)?.toDouble() ?? 0,
            status: e['status']?.toString() ?? '',
            type: e['tabung_type']?.toString() ?? '',
          ),
        )
        .toList(growable: false);

    final transactions = (txRows as List)
        .map(
          (e) => DashboardTransactionSummary(
            purpose: e['purpose']?.toString() ?? 'Payment details',
            amount: (e['amount'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList(growable: false);

    return DashboardData(
      fullName: fullName,
      familyCode: familyCode,
      hasChildInFamily: hasChildInFamily,
      tabungs: tabungs,
      transactions: transactions,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
