import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 84,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Dashboard
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Dashboard',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),

              // Tabung
              _NavItem(
                customIcon: Image.asset(
                  'assets/images/tabung/tabung_icon.png',
                  width: 28,
                  height: 28,
                  color: currentIndex == 1
                      ? const Color(0xFF2B7A6F)
                      : const Color(0xFFAAAAAA),
                ),
                label: 'Tabung',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),

              // Centre FAB — Create Tabung
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5EC4B0), Color(0xFF3A9E8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF9A).withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: currentIndex == 2
                              ? const Color(0xFF4CAF9A)
                              : const Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // Spend
              _NavItem(
                icon: Icons.payments_outlined,
                activeIcon: Icons.payments_rounded,
                label: 'Spend',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),

              // Leave
              _NavItem(
                icon: Icons.logout_rounded,
                activeIcon: Icons.logout_rounded,
                label: 'Leave',
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final IconData? activeIcon;
  final Widget? customIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    this.icon,
    this.activeIcon,
    this.customIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? const Color(0xFF2B7A6F) : const Color(0xFFAAAAAA);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Icon — either custom image or Material icon
            customIcon ??
                Icon(
                  isSelected ? (activeIcon ?? icon!) : icon!,
                  size: 26,
                  color: color,
                ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
