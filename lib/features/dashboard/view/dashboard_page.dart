import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/core/utils/app_bottom_nav_bar.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/dashboard/model/dashboard_models.dart';
import 'package:i_tabung/features/dashboard/model/dashboard_state.dart';
import 'package:i_tabung/features/dashboard/view_model/dashboard_view_model.dart';
import 'package:i_tabung/features/goaldashboard/view/goal_tabung_picker_page.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/view/tabung_setup_page.dart';
import 'package:i_tabung/features/parent_home/view/parent_pending_requests_page.dart';
import 'package:i_tabung/features/tabung_dashboard/view/tabung_dashboard_page.dart';
import 'package:i_tabung/features/transactions/model/transaction_flow_type.dart';
import 'package:i_tabung/features/transactions/view/tabung_action_picker_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider(widget.role));
    final vm = ref.read(dashboardViewModelProvider(widget.role).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      bottomNavigationBar: state.isLoading || state.error != null
          ? null
          : AppBottomNavBar(
              currentIndex: 0,
              onTap: (index) => _handleBottomNavTap(
                index: index,
                vm: vm,
                tabungs: state.data?.tabungs ?? const [],
              ),
            ),
      body: MaxWidthContainer(
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text('Failed to load dashboard: ${state.error}'))
                  : _buildContent(context, state, vm),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardState state, DashboardViewModel vm) {
    final data = state.data ?? DashboardData.empty();
    final tabungs = data.tabungs;
    final name = data.fullName.trim().isEmpty ? 'User' : data.fullName;
    final initials = _initials(name);

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                _HeaderBand(
                  name: name,
                  initials: initials,
                  role: widget.role,
                  onNotificationTap: widget.role == UserRole.parent
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ParentPendingRequestsPage()),
                          );
                        }
                      : null,
                  onLogoutTap: () async {
                    await vm.signOut();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.fromLTRB(20, 0, 20, 110),
                        content: Text('Signed out successfully.'),
                      ),
                    );
                  },
                ),
                if (widget.role == UserRole.parent && data.familyCode != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.groups_2_outlined, size: 18, color: Color(0xFF292929)),
                          const SizedBox(width: 8),
                          const Text(
                            'FAMILY CODE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2A2A2A),
                            ),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: data.familyCode!));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Family code copied.')),
                              );
                            },
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.copy_rounded, size: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FEATURES',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF232323),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _HeroCarousel(
                        tabungs: tabungs,
                        currentIndex: state.selectedIndex,
                        onPageChanged: vm.selectTabungIndex,
                        onAddTabung: () => _goToAddTabung(vm),
                        onTabungTap: _openTabungDashboard,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _FeatureBubble(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Deposit',
                              onTap: () => _openTransactionFlow(
                                flowType: TransactionFlowType.deposit,
                                tabungs: tabungs,
                                vm: vm,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FeatureBubble(
                              icon: Icons.volunteer_activism_outlined,
                              label: 'Add\nTabung',
                              onTap: () => _goToAddTabung(vm),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FeatureBubble(
                              icon: Icons.account_balance_outlined,
                              label: 'Spend',
                              onTap: () => _openTransactionFlow(
                                flowType: TransactionFlowType.spend,
                                tabungs: tabungs,
                                vm: vm,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _JourneyBanner(onTap: () => _openGoalsScreen(tabungs)),
                      const SizedBox(height: 22),
                      const Text(
                        'RECENT TABUNG',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF232323),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (tabungs.isNotEmpty)
                        _RecentTabungStrip(
                          tabungs: tabungs,
                          onTap: _openTabungDashboard,
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'IT';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _goToAddTabung(DashboardViewModel vm) {
    if (!vm.canCreateTabung()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(20, 0, 20, 110),
          content: Text(
            widget.role == UserRole.child
                ? 'Only parent accounts can create a tabung. Please ask your parent to create it for you.'
                : 'Add a child into your family group before creating a Tabung.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TabungSetupPage(role: widget.role)));
  }

  void _openGoalsScreen(List<DashboardTabungSummary> tabungs) {
    final activeTabungs = tabungs.where((tabung) => tabung.status == 'active').toList(growable: false);
    if (activeTabungs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create and activate a tabung before opening Goal Summary.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalTabungPickerPage(role: widget.role, tabungs: activeTabungs),
      ),
    );
  }

  void _openTabungDashboard(String tabungId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabungDashboardPage(tabungId: tabungId),
      ),
    );
  }

  Future<void> _openTransactionFlow({
    required TransactionFlowType flowType,
    required List<DashboardTabungSummary> tabungs,
    required DashboardViewModel vm,
  }) async {
    if (tabungs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          content: Text(
            flowType == TransactionFlowType.deposit
                ? 'Create a tabung before making a deposit.'
                : 'Create a tabung before recording spending.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabungActionPickerPage(
          flowType: flowType,
          tabungs: tabungs,
        ),
      ),
    );
    if (!mounted) return;
    await vm.refresh();
  }

  void _handleBottomNavTap({
    required int index,
    required DashboardViewModel vm,
    required List<DashboardTabungSummary> tabungs,
  }) {
    switch (index) {
      case 0:
        return;
      case 1:
        if (tabungs.isNotEmpty) {
          _openTabungDashboard(tabungs.first.id);
        }
        return;
      case 2:
        _goToAddTabung(vm);
        return;
      case 3:
        _openTransactionFlow(
          flowType: TransactionFlowType.spend,
          tabungs: tabungs,
          vm: vm,
        );
        return;
      case 4:
        vm.signOut();
        return;
    }
  }
}

class _HeaderBand extends StatelessWidget {
  const _HeaderBand({
    required this.name,
    required this.initials,
    required this.role,
    required this.onNotificationTap,
    required this.onLogoutTap,
  });

  final String name;
  final String initials;
  final UserRole role;
  final VoidCallback? onNotificationTap;
  final Future<void> Function() onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C1C).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1AE2A),
                  border: Border.all(color: const Color(0xFFEFBB57), width: 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3C2A11),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Hello,\n',
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2A2A2A),
                        ),
                      ),
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2A2A2A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onNotificationTap,
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      size: 32,
                      color: onNotificationTap == null ? const Color(0xFFBBB8D6) : Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: onLogoutTap,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 26,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.tabungs,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onAddTabung,
    required this.onTabungTap,
  });

  final List<DashboardTabungSummary> tabungs;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAddTabung;
  final ValueChanged<String> onTabungTap;

  @override
  Widget build(BuildContext context) {
    final hasTabung = tabungs.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2FB49E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 152,
            child: hasTabung
                ? PageView.builder(
                    itemCount: tabungs.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) => _SavingsHeroCard(
                      tabung: tabungs[index],
                      onTap: () => onTabungTap(tabungs[index].id),
                    ),
                  )
                : _EmptyHeroCard(onTap: onAddTabung),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              hasTabung ? tabungs.length.clamp(1, 3) : 3,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == currentIndex ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsHeroCard extends StatelessWidget {
  const _SavingsHeroCard({
    required this.tabung,
    required this.onTap,
  });

  final DashboardTabungSummary tabung;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = tabung.goalAmount <= 0 ? 0.0 : (tabung.currentAmount / tabung.goalAmount).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.volunteer_activism_outlined, size: 44, color: Colors.black),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tabung.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${tabung.currentAmount.toStringAsFixed(2)} / RM ${tabung.goalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.28),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE7C33D)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tabung.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTabungStrip extends StatelessWidget {
  const _RecentTabungStrip({
    required this.tabungs,
    required this.onTap,
  });

  final List<DashboardTabungSummary> tabungs;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabungs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tabung = tabungs[index];
          final progress = tabung.goalAmount <= 0 ? 0.0 : (tabung.currentAmount / tabung.goalAmount).clamp(0.0, 1.0);
          return SizedBox(
            width: 220,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => onTap(tabung.id),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tabung.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D2A3A),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF8D98AA)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Saved ${tabung.currentAmount.toStringAsFixed(0)} / ${tabung.goalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF607082),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          backgroundColor: const Color(0xFFE1E8F4),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2FB49E)),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tabung.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2FB49E),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.volunteer_activism_outlined, size: 46, color: Colors.black),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Goal Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 172,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3BD3A),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'VIEW GOALS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureBubble extends StatelessWidget {
  const _FeatureBubble({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F1FB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 36, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202020),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyBanner extends StatelessWidget {
  const _JourneyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF005A57),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goal Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review your progress, weekly target, and catch-up plan in one place.',
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 152,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5C442),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'VIEW GOALS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
