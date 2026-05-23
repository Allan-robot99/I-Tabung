import 'package:flutter/material.dart';

class GreetingBanner extends StatelessWidget {
  final String message;
  final double periodSaved;
  final double periodTarget;
  final String periodLabel;

  const GreetingBanner({
    super.key,
    required this.message,
    required this.periodSaved,
    required this.periodTarget,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (periodTarget - periodSaved).clamp(0, double.infinity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF9A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'IT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2A6F66),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hey there!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              children: [
                TextSpan(
                  text: 'You planned to save RM${periodTarget.toStringAsFixed(0)} this $periodLabel, '
                      'and you\'ve saved RM${periodSaved.toStringAsFixed(0)}. You only need ',
                ),
                TextSpan(
                  text: 'RM${remaining.toStringAsFixed(0)} more!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
