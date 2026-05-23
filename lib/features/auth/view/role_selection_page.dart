import 'package:flutter/material.dart';
import 'package:i_tabung/features/auth/view/sign_up_page.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  UserRole _selectedRole = UserRole.child;

  @override
  Widget build(BuildContext context) {
    final isChild = _selectedRole == UserRole.child;
    final background = isChild ? 'assets/images/auth/child_role.png' : 'assets/images/auth/parent_role.png';
    final leftSelected = _selectedRole == UserRole.parent;

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                child: Image.asset(background, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _roleToggle(leftSelected),
                            const SizedBox(height: 22),
                            Text(
                              isChild
                                  ? 'SAVE UP, HIT YOUR TARGETS,\nAND UNLOCK YOUR REWARDS!'
                                  : 'TEAM UP WITH YOUR CHILD TO\nSAVE, ACHIEVE GOALS, AND\nUNLOCK REWARDS.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                letterSpacing: 0.8,
                                color: Color(0xFF565656),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => SignUpPage(role: _selectedRole)),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005A57),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('START', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleToggle(bool leftSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFFFAFAFA),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = UserRole.parent),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: leftSelected ? const Color(0xFFFF3A3F) : const Color(0xFF5C54E8),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text('Parent', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = UserRole.child),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: leftSelected ? const Color(0xFF005A57) : const Color(0xFFFF3A3F),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text('Child', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
