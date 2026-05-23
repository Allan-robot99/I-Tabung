import 'package:flutter/material.dart';
 
class TabungHeroCard extends StatelessWidget {
  const TabungHeroCard({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF5B9E96),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Center(child: _JarIllustration()),
        ],
      ),
    );
    // TIP: Replace the _JarIllustration() with:
    // Image.asset('assets/images/jar.png', fit: BoxFit.contain)
    // after adding your asset to pubspec.yaml
  }
}
 
class _JarIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 110,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              ),
            ),
          ),
          Positioned(
            top: 8,
            child: Container(
              width: 70,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 20, height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_money, size: 18, color: Colors.amber),
                SizedBox(width: 4),
                Icon(Icons.airplanemode_active, size: 18, color: Colors.white),
                SizedBox(width: 4),
                Icon(Icons.luggage, size: 18, color: Colors.white70),
              ],
            ),
          ),
          Positioned(
            right: 4, bottom: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A96A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('✈', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}