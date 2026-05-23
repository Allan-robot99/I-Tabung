import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/repository/goal_planner_contracts.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:i_tabung/features/parent_home/service/parent_approval_service.dart';

class ParentPendingRequestsPage extends ConsumerStatefulWidget {
  const ParentPendingRequestsPage({super.key});

  @override
  ConsumerState<ParentPendingRequestsPage> createState() => _ParentPendingRequestsPageState();
}

class _ParentPendingRequestsPageState extends ConsumerState<ParentPendingRequestsPage> {
  bool _isMutating = false;

  @override
  Widget build(BuildContext context) {
    final userContextRepo = ref.watch(userContextRepositoryProvider);
    final requestRepo = ref.watch(tabungRequestRepositoryProvider);
    final tabungRepo = ref.watch(tabungRepositoryProvider);
    final approvalService = ParentApprovalService(
      userContextRepository: userContextRepo,
      tabungRequestRepository: requestRepo,
      tabungRepository: tabungRepo,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Tabung Requests')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadPending(requestRepo, userContextRepo),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load requests: ${snapshot.error}'));
          }

          final data = snapshot.data ?? const [];
          if (data.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final row = data[index];
                final tabungName = row['tabung_goals']?['tabung_name']?.toString() ?? 'Tabung Request';
                final goalAmount = row['tabung_goals']?['goal_amount']?.toString() ?? '-';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tabungName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Goal Amount: RM$goalAmount'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isMutating
                                    ? null
                                    : () async {
                                        await _approve(row, approvalService);
                                      },
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: _isMutating
                                    ? null
                                    : () async {
                                        await _reject(row, approvalService);
                                      },
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadPending(
    TabungRequestRepository requestRepo,
    UserContextRepository userContextRepo,
  ) async {
    final role = await userContextRepo.getCurrentUserRole();
    if (role != UserRole.parent) {
      return const [];
    }
    final submissionContext = await userContextRepo.resolveSubmissionContext(UserRole.parent);
    return requestRepo.fetchPendingForParent(submissionContext.userId);
  }

  Future<void> _approve(Map<String, dynamic> row, ParentApprovalService approvalService) async {
    setState(() => _isMutating = true);
    try {
      await approvalService.approve(requestId: row['id'] as String, tabungId: row['tabung_id'] as String);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved.')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _reject(Map<String, dynamic> row, ParentApprovalService approvalService) async {
    setState(() => _isMutating = true);
    try {
      const reason = 'Rejected by parent';
      await approvalService.reject(requestId: row['id'] as String, tabungId: row['tabung_id'] as String, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }
}
