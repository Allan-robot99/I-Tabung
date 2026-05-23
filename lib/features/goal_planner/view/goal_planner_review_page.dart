import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/core/utils/app_bottom_nav_bar.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/dashboard/view/dashboard_page.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_confirmed_plan.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';
import 'package:i_tabung/features/goal_planner/view/goal_planner_section_input_page.dart';
import 'package:i_tabung/features/goal_planner/view_model/goal_planner_view_model.dart';
import 'package:i_tabung/features/goal_planner/view_model/tabung_creation_coordinator_view_model.dart';
import 'package:i_tabung/features/parent_home/view/parent_pending_requests_page.dart';
import 'package:i_tabung/features/tabung_dashboard/view/tabung_dashboard_page.dart';

class GoalPlannerReviewPage extends ConsumerWidget {
  const GoalPlannerReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalPlannerViewModelProvider);
    final vm = ref.read(goalPlannerViewModelProvider.notifier);
    final role = ref.watch(tabungCreationCoordinatorProvider).creatorRole;
    final output = state.output;
    final confirmedPlan = state.confirmedPlan;

    if (output == null || confirmedPlan == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No plan generated yet.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (index) => _handleBottomNavTap(
          context: context,
          ref: ref,
          vm: vm,
          role: role,
          index: index,
        ),
      ),
      body: MaxWidthContainer(
        child: SafeArea(
          child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0A7B73), size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'I-TABUNG GOAL PLANNER',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF213248),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/goal_planner/planner_agent.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF69D1B6), Color(0xFF8EE0C4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -24,
                                right: -22,
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -30,
                                right: 26,
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'YOUR JOURNEY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1D4E4B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    role == UserRole.parent ? 'Parent & Child Shared Goal' : 'Child Goal Pending Parent Review',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2A6660),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _PlannerInfoCard(
                    title: 'Target Amount',
                    value: 'Set Target Amount',
                    detail: CurrencyUtils.asRm(confirmedPlan.targetAmount),
                    icon: Icons.generating_tokens_outlined,
                    onTap: () => _openSection(
                      context: context,
                      ref: ref,
                      section: GoalPlannerSectionType.targetAmount,
                      output: output,
                      confirmedPlan: confirmedPlan,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlannerInfoCard(
                    title: 'Contribution Ratio',
                    value: 'Set Parent & Child Split',
                    detail:
                        'Child ${confirmedPlan.childContributionPercentage.toStringAsFixed(0)}%  |  Parent ${confirmedPlan.parentContributionPercentage.toStringAsFixed(0)}%',
                    icon: Icons.pie_chart_outline_rounded,
                    onTap: () => _openSection(
                      context: context,
                      ref: ref,
                      section: GoalPlannerSectionType.contributionRatio,
                      output: output,
                      confirmedPlan: confirmedPlan,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlannerInfoCard(
                    title: 'Recurring Target',
                    value: 'Set Monthly Target',
                    detail:
                        '${CurrencyUtils.asRm(confirmedPlan.recurringAmount)} ${confirmedPlan.recurringPeriod.name}',
                    icon: Icons.sync_rounded,
                    onTap: () => _openSection(
                      context: context,
                      ref: ref,
                      section: GoalPlannerSectionType.recurringPlan,
                      output: output,
                      confirmedPlan: confirmedPlan,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlannerInfoCard(
                    title: 'Milestones & Awards',
                    value: 'Add Milestones & Awards',
                    detail: _milestoneSummary(confirmedPlan.milestones),
                    icon: Icons.emoji_events_outlined,
                    onTap: () => _openSection(
                      context: context,
                      ref: ref,
                      section: GoalPlannerSectionType.milestones,
                      output: output,
                      confirmedPlan: confirmedPlan,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _GenerateTabungBubble(
                    isLoading: state.isSubmitting,
                    onTap: () => _submitAndContinue(
                      context: context,
                      ref: ref,
                      vm: vm,
                      role: role,
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFC9C9)),
                      ),
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFAD3131),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (state.isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  static String _milestoneSummary(List<GoalPlannerConfirmedMilestone> milestones) {
    if (milestones.isEmpty) return 'No milestones yet';
    return milestones.map((m) => m.label).take(2).join('  |  ');
  }

  static Future<void> _openSection({
    required BuildContext context,
    required WidgetRef ref,
    required GoalPlannerSectionType section,
    required GoalPlannerOutput output,
    required GoalPlannerConfirmedPlan confirmedPlan,
  }) async {
    final updatedPlan = await Navigator.of(context).push<GoalPlannerConfirmedPlan>(
      MaterialPageRoute(
        builder: (_) => GoalPlannerSectionInputPage(
          section: section,
          output: output,
          confirmedPlan: confirmedPlan,
        ),
      ),
    );
    if (updatedPlan == null) return;
    ref.read(goalPlannerViewModelProvider.notifier).updateConfirmedPlan(updatedPlan);
  }

  static Future<void> _submitAndContinue({
    required BuildContext context,
    required WidgetRef ref,
    required GoalPlannerViewModel vm,
    required UserRole role,
  }) async {
    await vm.submitPlan();
    if (!context.mounted) return;
    final nextState = ref.read(goalPlannerViewModelProvider);
    final nextMessage = nextState.successMessage;
    if (nextMessage == null || nextMessage.trim().isEmpty) {
      return;
    }
    final createdTabungId = nextState.createdTabungId;
    await _showSuccessDialog(
      context: context,
      role: role,
      message: nextMessage,
    );
    if (!context.mounted) return;
    if (createdTabungId != null && createdTabungId.trim().isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TabungDashboardPage(tabungId: createdTabungId),
        ),
      );
    } else if (role == UserRole.child) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ParentPendingRequestsPage()),
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardPage(role: UserRole.parent)),
        (route) => route.isFirst,
      );
    }
  }

  static Future<void> _showSuccessDialog({
    required BuildContext context,
    required UserRole role,
    required String message,
  }) {
    final title = role == UserRole.parent ? 'Tabung Created' : 'Request Sent';
    final buttonLabel = role == UserRole.parent ? 'OK, View Tabung' : 'OK';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF203247),
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF425466),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0A615B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(buttonLabel),
            ),
          ],
        );
      },
    );
  }

  static void _handleBottomNavTap({
    required BuildContext context,
    required WidgetRef ref,
    required GoalPlannerViewModel vm,
    required UserRole role,
    required int index,
  }) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardPage(role: role)),
          (route) => route.isFirst,
        );
        return;
      case 1:
        final createdTabungId = ref.read(goalPlannerViewModelProvider).createdTabungId;
        if (createdTabungId != null && createdTabungId.trim().isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabungDashboardPage(tabungId: createdTabungId),
            ),
          );
        }
        return;
      case 2:
        if (!ref.read(goalPlannerViewModelProvider).isSubmitting) {
          _submitAndContinue(
            context: context,
            ref: ref,
            vm: vm,
            role: role,
          );
        }
        return;
      case 3:
        final createdTabungId = ref.read(goalPlannerViewModelProvider).createdTabungId;
        if (createdTabungId != null && createdTabungId.trim().isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabungDashboardPage(tabungId: createdTabungId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create the tabung first before recording spending.'),
            ),
          );
        }
        return;
      case 4:
        Navigator.of(context).maybePop();
        return;
    }
  }
}

class _GenerateTabungBubble extends StatelessWidget {
  const _GenerateTabungBubble({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD8F5EE), Color(0xFFBDEDE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A615B).withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A615B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A615B).withValues(alpha: 0.24),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isLoading ? Icons.hourglass_top_rounded : Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Generate Tabung',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF203247),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoading
                            ? 'Creating your tabung from the confirmed plan...'
                            : 'Once everything looks right, tap here to confirm and create this tabung.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF45605E),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isLoading ? 'Generating...' : 'Generate',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A615B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlannerInfoCard extends StatelessWidget {
  const _PlannerInfoCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 2,
      shadowColor: const Color(0xFFCCD6EC).withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF707D93),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF203247),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F7A73),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: const Color(0xFF0F7A73), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
