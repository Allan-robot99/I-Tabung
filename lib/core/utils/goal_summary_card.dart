import 'package:flutter/material.dart';
import 'package:i_tabung/features/goaldashboard/models/goal_model.dart';
import 'app_card.dart';
 
class GoalSummaryCard extends StatelessWidget {
  final GoalModel goal;
  const GoalSummaryCard({super.key, required this.goal});
 
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GOAL SUMMARY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF999999),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.laptop_mac_outlined, size: 18, color: Color(0xFF666666)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            goal.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: goal.formattedSaved,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    TextSpan(
                      text: ' / ${goal.formattedTarget}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: goal.progressPercentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8E8E8),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF9A)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recurring this ${goal.periodLabel}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
              Text(
                'RM${goal.periodSaved.toStringAsFixed(0)} / RM${goal.periodTarget.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
