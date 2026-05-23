import 'package:flutter/material.dart';
import 'package:i_tabung/features/goaldashboard/models/goal_model.dart';
import 'app_card.dart';
 
class CatchUpPlanCard extends StatelessWidget {
  final CatchUpPlan plan;
  final VoidCallback onAccept;
 
  const CatchUpPlanCard({super.key, required this.plan, required this.onAccept});
 
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATCH-UP PLAN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF4CAF9A), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A), height: 1.5),
                    children: [
                      const TextSpan(text: 'Try saving '),
                      TextSpan(
                        text: '${plan.formattedDaily} per day',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' for the next ${plan.days} days.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          plan.isAccepted ? _acceptedState() : _acceptButton(),
        ],
      ),
    );
  }
 
  Widget _acceptButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Accept Plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF9A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
        ),
      );
 
  Widget _acceptedState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5F1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF9A), size: 18),
            SizedBox(width: 8),
            Text('Plan Accepted!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF4CAF9A))),
          ],
        ),
      );
}
