import 'package:flutter/material.dart';
import 'app_card.dart';
 
class DaysLeftCard extends StatelessWidget {
  final int daysLeft;
  const DaysLeftCard({super.key, required this.daysLeft});
 
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.timer_outlined, color: Color(0xFFE85D3A), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF333333), height: 1.5),
                children: [
                  const TextSpan(text: 'You have exactly '),
                  TextSpan(
                    text: '$daysLeft days left',
                    style: const TextStyle(
                      color: Color(0xFFE85D3A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: " to reach your final goal. Don't let time run out!",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
