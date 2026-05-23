import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/tabung_dashboard/model/tabung_dashboard_models.dart';
import 'package:i_tabung/features/tabung_dashboard/repository/tabung_dashboard_repository.dart';

class TabungDashboardPage extends ConsumerWidget {
  const TabungDashboardPage({
    super.key,
    required this.tabungId,
  });

  final String tabungId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabungAsync = ref.watch(tabungDashboardProvider(tabungId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FD),
      body: MaxWidthContainer(
        child: SafeArea(
          child: tabungAsync.when(
            data: (data) => _TabungDashboardView(data: data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load tabung dashboard.\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E3B4E),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabungDashboardView extends StatelessWidget {
  const _TabungDashboardView({required this.data});

  final TabungDashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = _TabungVisualTheme.fromData(data);
    final progress = data.goalAmount <= 0 ? 0.0 : (data.currentAmount / data.goalAmount).clamp(0.0, 1.0);
    final contributionProgress = data.userContributionTargetAmount <= 0
        ? 0.0
        : (data.userTotalContributionAmount / data.userContributionTargetAmount).clamp(0.0, 1.0);
    final contributionRoleLabel = data.currentUserRole == 'child' ? 'Child' : 'Parent';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 30, color: Color(0xFF172638)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172638),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA5B2), size: 28),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
            ),
            child: Container(
              height: 292,
              decoration: BoxDecoration(
                color: theme.heroColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 18,
                    top: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _tabungTypeLabel(data.type),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF294242),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    right: 24,
                    child: _StatusPill(status: data.status),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 40, 26, 22),
                      child: Image.asset(theme.assetPath, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.accentColor, width: 2),
                  ),
                  child: Icon(Icons.account_balance_wallet_outlined, color: theme.accentColor, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'CURRENT AMOUNT',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF43505E),
                              ),
                            ),
                          ),
                          Text(
                            CurrencyUtils.asRm(data.currentAmount),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: theme.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: const Color(0xFFDDE8FA),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.progressColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Target: ${CurrencyUtils.asRm(data.goalAmount)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF667487),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.handshake_outlined, color: theme.accentColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '$contributionRoleLabel Contribution',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172638),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _InfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Your Share Target',
                  value:
                      '${CurrencyUtils.asRm(data.userContributionTargetAmount)} (${data.userContributionPercentage.toStringAsFixed(0)}%)',
                ),
                const Divider(height: 26, color: Color(0xFFE4EDF8)),
                _InfoRow(
                  icon: Icons.savings_outlined,
                  label: 'Total Contributed',
                  value: CurrencyUtils.asRm(data.userTotalContributionAmount),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: contributionProgress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFDDE8FA),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.progressColor),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    contributionProgress >= 1
                        ? 'Your contribution target is complete'
                        : '${CurrencyUtils.asRm((data.userContributionTargetAmount - data.userTotalContributionAmount).clamp(0, double.infinity))} remaining for your share',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667487),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF71D4C5), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Tabung Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172638),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _InfoRow(
                  icon: Icons.adjust_outlined,
                  label: 'Target Amount',
                  value: CurrencyUtils.asRm(data.goalAmount),
                ),
                const Divider(height: 26, color: Color(0xFFE4EDF8)),
                _InfoRow(
                  icon: Icons.sync_rounded,
                  label: 'Recurring Target',
                  value: '${CurrencyUtils.asRm(data.recurringAmount)} / ${_periodLabel(data.recurringPeriod)}',
                ),
                const Divider(height: 26, color: Color(0xFFE4EDF8)),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Your Recurring Target',
                  value: '${CurrencyUtils.asRm(data.userRecurringTargetAmount)} / ${_periodLabel(data.recurringPeriod)}',
                ),
                const Divider(height: 26, color: Color(0xFFE4EDF8)),
                _InfoRow(
                  icon: Icons.today_outlined,
                  label: data.currentPeriodContributionLabel,
                  value: CurrencyUtils.asRm(data.currentPeriodContributionAmount),
                  caption: data.userRecurringTargetAmount > 0
                      ? 'Goal: ${CurrencyUtils.asRm(data.userRecurringTargetAmount)} this ${_periodLabel(data.recurringPeriod)}'
                      : null,
                ),
                const Divider(height: 26, color: Color(0xFFE4EDF8)),
                _RatioRow(
                  childPercentage: data.childContributionPercentage,
                  parentPercentage: data.parentContributionPercentage,
                ),
              ],
            ),
          ),
          if (data.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF9F4), Color(0xFFF5FCFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                data.summary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF42605B),
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (data.latestTransaction != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: Color(0xFF0A615B), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Latest Spending Result',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172638),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${data.latestTransaction!.purpose} • ${CurrencyUtils.asRm(data.latestTransaction!.amount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172638),
                    ),
                  ),
                  if (data.latestTransaction!.impactWarning.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      data.latestTransaction!.impactWarning,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF5D6A79),
                      ),
                    ),
                  ],
                  if (data.latestTransaction!.recommendation.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      data.latestTransaction!.recommendation,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B5D56),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          const Row(
            children: [
              Icon(Icons.route_rounded, color: Color(0xFF0A615B), size: 24),
              SizedBox(width: 8),
              Text(
                'Milestone Journey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF172638),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MilestoneJourney(
            milestones: data.milestones,
            currentAmount: data.currentAmount,
            accentColor: theme.accentColor,
          ),
        ],
      ),
    );
  }

  static String _periodLabel(String recurringPeriod) {
    return switch (recurringPeriod) {
      'daily' => 'day',
      'weekly' => 'week',
      _ => 'month',
    };
  }

  static String _tabungTypeLabel(String type) {
    if (type.trim().isEmpty) {
      return 'TABUNG';
    }

    return type
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPending ? 'Pending Approval' : 'Active Goal',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isPending ? const Color(0xFFA66A21) : const Color(0xFF0A615B),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF77869A), size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF223041),
                ),
              ),
              if (caption != null && caption!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  caption!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF708094),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172638),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatioRow extends StatelessWidget {
  const _RatioRow({
    required this.childPercentage,
    required this.parentPercentage,
  });

  final double childPercentage;
  final double parentPercentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF77869A), size: 21),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Shared Ratio',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF223041),
            ),
          ),
        ),
        _RatioPill(label: 'Child', value: '${childPercentage.toStringAsFixed(0)}%'),
        const SizedBox(width: 8),
        _RatioPill(
          label: 'Parent',
          value: '${parentPercentage.toStringAsFixed(0)}%',
          muted: true,
        ),
      ],
    );
  }
}

class _RatioPill extends StatelessWidget {
  const _RatioPill({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFEFF3F5) : const Color(0xFF6DD1BF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label  $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: muted ? const Color(0xFF687789) : Colors.white,
        ),
      ),
    );
  }
}

class _MilestoneJourney extends StatelessWidget {
  const _MilestoneJourney({
    required this.milestones,
    required this.currentAmount,
    required this.accentColor,
  });

  final List<TabungDashboardMilestone> milestones;
  final double currentAmount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const Text(
        'No milestones yet for this tabung.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF687789),
        ),
      );
    }

    final activeIndex = milestones.indexWhere((milestone) => currentAmount < milestone.amount);
    final currentIndex = activeIndex == -1 ? milestones.length - 1 : activeIndex;

    return Column(
      children: List.generate(milestones.length, (index) {
        final milestone = milestones[index];
        final isCompleted = currentAmount >= milestone.amount;
        final isCurrent = !isCompleted && index == currentIndex;
        final isLast = index == milestones.length - 1;
        final icon = isCompleted
            ? Icons.check_rounded
            : isCurrent
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted || isCurrent ? accentColor.withValues(alpha: isCompleted ? 1 : 0.14) : Colors.white,
                      border: Border.all(
                        color: isCompleted || isCurrent ? accentColor : const Color(0xFFD5E3FA),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isCompleted ? Colors.white : accentColor,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 4,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            isCompleted ? accentColor : const Color(0xFFD5E3FA),
                            (isCompleted || isCurrent) ? accentColor.withValues(alpha: 0.25) : const Color(0xFFD5E3FA),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                child: _MilestoneCard(
                  milestone: milestone,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  accentColor: accentColor,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.isCompleted,
    required this.isCurrent,
    required this.accentColor,
  });

  final TabungDashboardMilestone milestone;
  final bool isCompleted;
  final bool isCurrent;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCompleted || isCurrent ? accentColor.withValues(alpha: isCompleted ? 0.28 : 0.45) : const Color(0xFFE2E8F3);
    final backgroundColor = isCompleted
        ? Colors.white
        : isCurrent
            ? accentColor.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.76);
    final title = isCompleted
        ? milestone.rewardDescription
        : isCurrent
            ? 'Next Reward: ${milestone.rewardDescription}'
            : 'Final Goal: ${milestone.rewardDescription}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyUtils.asRm(milestone.amount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isCompleted || isCurrent ? const Color(0xFF172638) : const Color(0xFFA8AFB9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isCurrent ? const Color(0xFF42605B) : const Color(0xFFA8AFB9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            _milestoneIcon(milestone),
            color: isCompleted || isCurrent ? accentColor : const Color(0xFFB9C0C9),
            size: 28,
          ),
        ],
      ),
    );
  }

  static IconData _milestoneIcon(TabungDashboardMilestone milestone) {
    final text = '${milestone.label} ${milestone.rewardDescription}'.toLowerCase();
    if (text.contains('sticker') || text.contains('tag')) return Icons.sell_outlined;
    if (text.contains('mouse')) return Icons.mouse_outlined;
    if (text.contains('laptop') || text.contains('computer')) return Icons.laptop_chromebook_outlined;
    if (text.contains('travel') || text.contains('trip')) return Icons.flight_takeoff_rounded;
    return Icons.emoji_events_outlined;
  }
}

class _TabungVisualTheme {
  const _TabungVisualTheme({
    required this.assetPath,
    required this.heroColor,
    required this.accentColor,
    required this.progressColor,
  });

  final String assetPath;
  final Color heroColor;
  final Color accentColor;
  final Color progressColor;

  factory _TabungVisualTheme.fromData(TabungDashboardData data) {
    final text = '${data.type} ${data.name} ${data.description}'.toLowerCase();

    if (text.contains('travel')) {
      return const _TabungVisualTheme(
        assetPath: 'assets/images/tabung/travel_jar.png',
        heroColor: Color(0xFF709A97),
        accentColor: Color(0xFF0A746D),
        progressColor: Color(0xFF78D0C0),
      );
    }
    if (text.contains('gadget') || text.contains('electronic') || text.contains('laptop') || text.contains('phone')) {
      return const _TabungVisualTheme(
        assetPath: 'assets/images/tabung/electronicdevice_jar.png',
        heroColor: Color(0xFF759A96),
        accentColor: Color(0xFF0A746D),
        progressColor: Color(0xFF7BD0BF),
      );
    }
    if (text.contains('food') || text.contains('meal') || text.contains('snack') || text.contains('omakase')) {
      return const _TabungVisualTheme(
        assetPath: 'assets/images/tabung/food_jar.png',
        heroColor: Color(0xFF9E9070),
        accentColor: Color(0xFF9E7A2A),
        progressColor: Color(0xFFD5B86D),
      );
    }
    if (text.contains('education') || text.contains('growth') || text.contains('study') || text.contains('university')) {
      return const _TabungVisualTheme(
        assetPath: 'assets/images/tabung/personal_growth_jar.png',
        heroColor: Color(0xFF85A688),
        accentColor: Color(0xFF4C8F66),
        progressColor: Color(0xFF71C998),
      );
    }
    if (text.contains('sport') || text.contains('art') || text.contains('class') || text.contains('competition')) {
      return const _TabungVisualTheme(
        assetPath: 'assets/images/tabung/sport_art_jar.png',
        heroColor: Color(0xFF9A9488),
        accentColor: Color(0xFFB07D3C),
        progressColor: Color(0xFFD5AE75),
      );
    }

    return const _TabungVisualTheme(
      assetPath: 'assets/images/tabung/travel_jar.png',
      heroColor: Color(0xFF709A97),
      accentColor: Color(0xFF0A746D),
      progressColor: Color(0xFF78D0C0),
    );
  }
}
