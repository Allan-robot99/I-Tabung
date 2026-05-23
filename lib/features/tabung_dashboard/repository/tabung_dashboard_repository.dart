import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:i_tabung/features/tabung_dashboard/model/tabung_dashboard_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tabungDashboardRepositoryProvider = Provider<TabungDashboardRepository>((ref) {
  return SupabaseTabungDashboardRepository(ref.watch(supabaseClientProvider));
});

final tabungDashboardProvider =
    FutureProvider.autoDispose.family<TabungDashboardData, String>((ref, tabungId) async {
  return ref.watch(tabungDashboardRepositoryProvider).fetchTabungDashboard(tabungId);
});

abstract class TabungDashboardRepository {
  Future<TabungDashboardData> fetchTabungDashboard(String tabungId);
}

class SupabaseTabungDashboardRepository implements TabungDashboardRepository {
  SupabaseTabungDashboardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TabungDashboardData> fetchTabungDashboard(String tabungId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      throw Exception('User must be logged in.');
    }

    final tabungRows = await _client
        .from('tabung_goals')
        .select(
          'id, tabung_name, tabung_type, description, status, goal_amount, current_amount, recurring_amount, recurring_period, child_contribution_amount, parent_contribution_amount, child_contribution_percentage, parent_contribution_percentage, child_id, ai_plan_summary',
        )
        .eq('id', tabungId)
        .limit(1);

    if (tabungRows.isEmpty) {
      throw Exception('Tabung not found.');
    }

    final row = tabungRows.first;
    final profileRows = await _client.from('profiles').select('role').eq('id', currentUserId).limit(1);
    final currentUserRole = profileRows.isNotEmpty
        ? profileRows.first['role']?.toString() ?? ''
        : ((row['child_id']?.toString() == currentUserId) ? 'child' : 'parent');

    final milestoneRows = await _client
        .from('milestones')
        .select('milestone_amount, milestone_label, milestone_description, reward_description')
        .eq('tabung_id', tabungId)
        .order('milestone_amount', ascending: true);

    final milestones = milestoneRows
        .map(
          (milestone) => TabungDashboardMilestone(
            amount: (milestone['milestone_amount'] as num?)?.toDouble() ?? 0,
            label: milestone['milestone_label']?.toString() ?? 'Milestone',
            rewardDescription: milestone['reward_description']?.toString() ?? 'Reward coming soon',
            description: milestone['milestone_description']?.toString() ?? '',
          ),
        )
        .toList(growable: false);

    final contributionRows = await _client
        .from('savings_entries')
        .select('amount')
        .eq('tabung_id', tabungId)
        .eq('user_id', currentUserId);

    final periodRows = await _client
        .from('savings_entries')
        .select('amount')
        .eq('tabung_id', tabungId)
        .eq('user_id', currentUserId)
        .gte(
          'saved_at',
          _currentPeriodStart(row['recurring_period']?.toString() ?? 'monthly').toIso8601String(),
        );

    final txRows = await _client
        .from('payment_transactions')
        .select('purpose, amount, impact_warning, budget_health_tip')
        .eq('tabung_id', tabungId)
        .eq('status', 'confirmed')
        .order('created_at', ascending: false)
        .limit(1);

    final latestTransaction = txRows.isEmpty
        ? null
        : TabungDashboardTransaction(
            purpose: txRows.first['purpose']?.toString() ?? 'Recent spending',
            amount: (txRows.first['amount'] as num?)?.toDouble() ?? 0,
            impactWarning: txRows.first['impact_warning']?.toString() ?? '',
            recommendation: txRows.first['budget_health_tip']?.toString() ?? '',
          );

    final recurringAmount = (row['recurring_amount'] as num?)?.toDouble() ?? 0;
    final childContributionPercentage = (row['child_contribution_percentage'] as num?)?.toDouble() ?? 0;
    final parentContributionPercentage = (row['parent_contribution_percentage'] as num?)?.toDouble() ?? 0;
    final childContributionAmount = (row['child_contribution_amount'] as num?)?.toDouble() ?? 0;
    final parentContributionAmount = (row['parent_contribution_amount'] as num?)?.toDouble() ?? 0;
    final isChild = currentUserRole == 'child';
    final userContributionPercentage = isChild ? childContributionPercentage : parentContributionPercentage;
    final userContributionTargetAmount = isChild ? childContributionAmount : parentContributionAmount;
    final userRecurringTargetAmount =
        recurringAmount <= 0 ? 0.0 : (recurringAmount * (userContributionPercentage / 100)).toDouble();

    return TabungDashboardData(
      id: row['id'] as String,
      name: row['tabung_name']?.toString() ?? 'Tabung',
      type: row['tabung_type']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      status: row['status']?.toString() ?? 'active',
      goalAmount: (row['goal_amount'] as num?)?.toDouble() ?? 0,
      currentAmount: (row['current_amount'] as num?)?.toDouble() ?? 0,
      recurringAmount: recurringAmount,
      recurringPeriod: row['recurring_period']?.toString() ?? 'monthly',
      childContributionPercentage: childContributionPercentage,
      parentContributionPercentage: parentContributionPercentage,
      currentUserRole: currentUserRole,
      userContributionTargetAmount: userContributionTargetAmount,
      userContributionPercentage: userContributionPercentage,
      userTotalContributionAmount: _sumAmounts(contributionRows),
      userRecurringTargetAmount: userRecurringTargetAmount,
      currentPeriodContributionAmount: _sumAmounts(periodRows),
      currentPeriodContributionLabel:
          _currentPeriodContributionLabel(row['recurring_period']?.toString() ?? 'monthly'),
      summary: row['ai_plan_summary']?.toString() ?? '',
      milestones: milestones,
      latestTransaction: latestTransaction,
    );
  }

  static double _sumAmounts(List<dynamic> rows) {
    return rows.fold<double>(
      0,
      (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
    );
  }

  static DateTime _currentPeriodStart(String recurringPeriod) {
    final now = DateTime.now();
    switch (recurringPeriod) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - DateTime.monday));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  static String _currentPeriodContributionLabel(String recurringPeriod) {
    switch (recurringPeriod) {
      case 'daily':
        return 'Today Contributed';
      case 'weekly':
        return 'This Week Contributed';
      default:
        return 'This Month Contributed';
    }
  }
}
