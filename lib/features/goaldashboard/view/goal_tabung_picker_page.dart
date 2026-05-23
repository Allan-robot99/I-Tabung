import 'package:flutter/material.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/dashboard/model/dashboard_models.dart';
import 'package:i_tabung/features/goaldashboard/view/goals_screen.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';

class GoalTabungPickerPage extends StatelessWidget {
  const GoalTabungPickerPage({
    super.key,
    required this.role,
    required this.tabungs,
  });

  final UserRole role;
  final List<DashboardTabungSummary> tabungs;

  @override
  Widget build(BuildContext context) {
    final activeTabungs = tabungs.where((tabung) => tabung.status == 'active').toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Choose a Tabung',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
        ),
        centerTitle: true,
      ),
      body: MaxWidthContainer(
        child: activeTabungs.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No active tabung is ready for Goal Summary yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: activeTabungs.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tabung = activeTabungs[index];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GoalsScreen(
                              tabungId: tabung.id,
                              role: role,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEAF7F3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.savings_outlined, color: Color(0xFF0B7A63)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tabung.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF172638),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${CurrencyUtils.asRm(tabung.currentAmount)} / ${CurrencyUtils.asRm(tabung.goalAmount)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF667487),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF7A8798)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
