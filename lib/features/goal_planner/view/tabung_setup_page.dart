import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/view/goal_planner_review_page.dart';
import 'package:i_tabung/features/goal_planner/view_model/goal_planner_view_model.dart';
import 'package:i_tabung/features/goal_planner/view_model/tabung_creation_coordinator_view_model.dart';

class TabungSetupPage extends ConsumerStatefulWidget {
  const TabungSetupPage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<TabungSetupPage> createState() => _TabungSetupPageState();
}

class _TabungSetupPageState extends ConsumerState<TabungSetupPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController(viewportFraction: 0.9);

  final List<TabungType> _types = const [
    TabungType.electronicDevice,
    TabungType.food,
    TabungType.personalGrowth,
    TabungType.sportArt,
    TabungType.travel,
  ];

  int _selectedIndex = 0;

  TabungType get _selectedType => _types[_selectedIndex];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _selectedType.shortLabel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionText = widget.role == UserRole.parent ? 'CREATE' : 'REQUEST';
    final colorToken = _selectedType.colorToken;
    final plannerState = ref.watch(goalPlannerViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: MaxWidthContainer(
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 32, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Create Tabung',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF242424),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _goToNextType,
                    icon: const Icon(Icons.chevron_right_rounded, size: 30, color: Color(0xFFD7DCEF)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 340,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _types.length,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                      if (_nameController.text.trim().isEmpty || _nameController.text.trim() == _types[_selectedIndex].shortLabel) {
                        _nameController.text = _types[index].shortLabel;
                      }
                    });
                  },
                  itemBuilder: (context, index) {
                    final type = _types[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: EdgeInsets.only(right: index == _types.length - 1 ? 0 : 10),
                      decoration: BoxDecoration(
                        color: Color(type.colorToken.cardColorHex),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7182C5).withValues(alpha: 0.14),
                            blurRadius: 20,
                            offset: const Offset(8, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Image.asset(type.assetPath, fit: BoxFit.contain),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                            child: Text(
                              type.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2324),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _types.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _selectedIndex ? const Color(0xFF5D7FF0) : const Color(0xFFC8CEE6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Name',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D271C),
                ),
              ),
              const SizedBox(height: 6),
              _LinedInput(
                controller: _nameController,
                hintText: 'Enter tabung name',
                maxLines: 1,
              ),
              const SizedBox(height: 20),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D271C),
                ),
              ),
              const SizedBox(height: 6),
              _LinedInput(
                controller: _descriptionController,
                hintText: 'Describe what this tabung is for',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: ElevatedButton.styleFrom(
                          elevation: 10,
                          shadowColor: const Color(0xFFE6EAF6),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Icon(Icons.home_filled, size: 34),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 7,
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || plannerState.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 12,
                          shadowColor: Color(colorToken.buttonColorHex).withValues(alpha: 0.30),
                          backgroundColor: Color(colorToken.buttonColorHex),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(
                          _isSubmitting || plannerState.isLoading ? 'LOADING...' : actionText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _goToNextType() {
    final nextIndex = (_selectedIndex + 1) % _types.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    if (widget.role == UserRole.child) {
      _showMessage('Only parent accounts can create a tabung. Please ask your parent to create it for you.');
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter a tabung name.');
      return;
    }
    if (description.isEmpty) {
      _showMessage('Please enter a tabung description.');
      return;
    }

    setState(() => _isSubmitting = true);

    final coordinatorVm = ref.read(tabungCreationCoordinatorProvider.notifier);
    final plannerVm = ref.read(goalPlannerViewModelProvider.notifier);

    coordinatorVm.setCreatorRole(widget.role);
    coordinatorVm.moveToStep(1);

    await plannerVm.generatePlan(
      GoalPlannerInput(
        userRole: widget.role,
        tabungType: _selectedType,
        tabungName: name,
        tabungDescription: description,
      ),
    );

    if (!mounted) return;

    final plannerState = ref.read(goalPlannerViewModelProvider);
    setState(() => _isSubmitting = false);

    if (plannerState.error != null || plannerState.output == null || plannerState.confirmedPlan == null) {
      _showMessage(plannerState.error ?? 'Unable to generate the goal plan right now.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GoalPlannerReviewPage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        content: Text(message),
      ),
    );
  }
}

class _LinedInput extends StatelessWidget {
  const _LinedInput({
    required this.controller,
    required this.hintText,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFB0AFAF),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }
}

class TabungSetupDraft {
  const TabungSetupDraft({
    required this.type,
    required this.name,
    required this.description,
    required this.actionLabel,
  });

  final TabungType type;
  final String name;
  final String description;
  final String actionLabel;
}
