import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/core/utils/app_bottom_nav_bar.dart';
import 'package:i_tabung/core/utils/calendar_sync_card.dart';
import 'package:i_tabung/core/utils/days_left_card.dart';
import 'package:i_tabung/core/utils/goal_summary_card.dart';
import 'package:i_tabung/core/utils/greeting_banner.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/dashboard/view/dashboard_page.dart';
import 'package:i_tabung/features/goaldashboard/models/goal_model.dart';
import 'package:i_tabung/features/goaldashboard/repository/goal_summary_repository.dart';
import 'package:i_tabung/features/goaldashboard/viewmodel/goal_viewmodel.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/view/tabung_setup_page.dart';
import 'package:i_tabung/features/recurring_reminder/view/reminder_setup_page.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({
    super.key,
    required this.tabungId,
    this.role = UserRole.parent,
  });

  final String tabungId;
  final UserRole role;

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  late final GoalViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GoalViewModel(ref.read(goalSummaryRepositoryProvider));
    _viewModel.load(widget.tabungId);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: _buildAppBar(),
          body: MaxWidthContainer(child: _buildBody(context)),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: 1,
            onTap: _handleBottomNavTap,
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _viewModel.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final goal = _viewModel.goal!;
    final canEnableReminder = goal.calendarSync == null || goal.calendarSync!.syncStatus != 'synced';

    return RefreshIndicator(
      onRefresh: () => _viewModel.load(widget.tabungId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            GreetingBanner(
              message: _viewModel.greetingMessage,
              periodSaved: goal.periodSaved,
              periodTarget: goal.periodTarget,
              periodLabel: goal.periodLabel,
            ),
            const SizedBox(height: 12),
            DaysLeftCard(daysLeft: goal.daysLeft),
            const SizedBox(height: 12),
            GoalSummaryCard(goal: goal),
            const SizedBox(height: 12),
            if (canEnableReminder)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _openReminderSetup(goal),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B7A63),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text(
                    'Enable Goal Reminder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (goal.calendarSync != null) ...[
              const SizedBox(height: 12),
              CalendarSyncCard(
                calendarSync: goal.calendarSync!,
                onViewInCalendar: _viewModel.viewInCalendar,
              ),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF7F8FA),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Color(0xFF333333),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Goal Summary',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A1A),
        ),
      ),
      centerTitle: true,
    );
  }

  Future<void> _openReminderSetup(GoalModel goal) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReminderSetupPage(goal: goal)),
    );
    if (created == true) {
      await _viewModel.load(widget.tabungId);
    }
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardPage(role: widget.role)),
          (route) => false,
        );
        return;
      case 1:
        return;
      case 2:
        if (widget.role == UserRole.child) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only parent accounts can create a tabung. Please ask your parent to create it for you.'),
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TabungSetupPage(role: widget.role)),
        );
        return;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open spending from the dashboard tabung actions.')),
        );
        return;
      case 4:
        Navigator.maybePop(context);
        return;
    }
  }
}
