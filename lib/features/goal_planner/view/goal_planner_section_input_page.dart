import 'package:flutter/material.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/core/utils/max_width_container.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_confirmed_plan.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';

enum GoalPlannerSectionType {
  targetAmount,
  contributionRatio,
  recurringPlan,
  milestones,
}

class GoalPlannerSectionInputPage extends StatefulWidget {
  const GoalPlannerSectionInputPage({
    super.key,
    required this.section,
    required this.output,
    required this.confirmedPlan,
  });

  final GoalPlannerSectionType section;
  final GoalPlannerOutput output;
  final GoalPlannerConfirmedPlan confirmedPlan;

  @override
  State<GoalPlannerSectionInputPage> createState() => _GoalPlannerSectionInputPageState();
}

class _GoalPlannerSectionInputPageState extends State<GoalPlannerSectionInputPage> {
  late final TextEditingController _targetAmountController;
  late final TextEditingController _recurringAmountController;
  late final TextEditingController _endPeriodValueController;
  late DateTime _startDate;
  late String _recurringPeriodName;
  EndPeriodUnit _endPeriodUnit = EndPeriodUnit.months;
  double _childPercentage = 50;
  late List<_MilestoneDraft> _milestones;

  @override
  void initState() {
    super.initState();
    _targetAmountController = TextEditingController(text: widget.confirmedPlan.targetAmount.toStringAsFixed(0));
    _recurringAmountController = TextEditingController(
      text: widget.confirmedPlan.recurringAmount.toStringAsFixed(0),
    );
    _endPeriodValueController = TextEditingController(
      text: widget.confirmedPlan.endPeriodValue.toString(),
    );
    _startDate = widget.confirmedPlan.recurringStartDate;
    _recurringPeriodName = widget.confirmedPlan.recurringPeriod.name;
    _endPeriodUnit = widget.confirmedPlan.endPeriodUnit;
    _childPercentage = widget.confirmedPlan.childContributionPercentage.clamp(0, 100);
    _milestones = widget.confirmedPlan.milestones
        .map(
          (m) => _MilestoneDraft(
            amountController: TextEditingController(text: m.amount.toStringAsFixed(0)),
            labelController: TextEditingController(text: m.label),
            rewardController: TextEditingController(text: m.rewardDescription),
            descriptionController: TextEditingController(text: m.description),
          ),
        )
        .toList(growable: true);
  }

  @override
  void dispose() {
    _targetAmountController.dispose();
    _recurringAmountController.dispose();
    _endPeriodValueController.dispose();
    for (final milestone in _milestones) {
      milestone.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: MaxWidthContainer(
        child: SafeArea(
          child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 310),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0A7B73), size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _headerTitle(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF223349),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _questionTitle(),
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF202B3A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _questionSubtitle(),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF526173),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionInput(),
                ],
              ),
            ),
            _SuggestionSheet(
              title: _sheetTitle(),
              subtitle: _sheetSubtitle(),
              body: _buildSuggestionBody(),
              buttonLabel: _sheetButtonLabel(),
              onApply: () => Navigator.of(context).pop(_buildConfirmedPlan()),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSectionInput() {
    return switch (widget.section) {
      GoalPlannerSectionType.targetAmount => _buildTargetAmountInput(),
      GoalPlannerSectionType.contributionRatio => _buildContributionRatioInput(),
      GoalPlannerSectionType.recurringPlan => _buildRecurringPlanInput(),
      GoalPlannerSectionType.milestones => _buildMilestonesInput(),
    };
  }

  Widget _buildTargetAmountInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'RM',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A615B),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 150,
            child: TextField(
              controller: _targetAmountController,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: Color(0xFF9BA8A6),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: TextStyle(color: Color(0xFFAFB7B5)),
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _adjustAmount(50),
                icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF7F8997)),
              ),
              IconButton(
                onPressed: () => _adjustAmount(-50),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7F8997)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributionRatioInput() {
    final targetAmount = _targetAmountValue();
    final childAmount = targetAmount * (_childPercentage / 100);
    final parentPercentage = 100 - _childPercentage;
    final parentAmount = targetAmount - childAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Child Contribution ${_childPercentage.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF203247)),
          ),
          Slider(
            value: _childPercentage,
            min: 0,
            max: 100,
            activeColor: const Color(0xFF0A7B73),
            inactiveColor: const Color(0xFFCCD5E2),
            onChanged: (value) => setState(() => _childPercentage = value),
          ),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Child Amount',
                  CurrencyUtils.asRm(childAmount),
                  '${_childPercentage.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Parent Amount',
                  CurrencyUtils.asRm(parentAmount),
                  '${parentPercentage.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringPlanInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recurring Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF203247)),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Daily')),
              ButtonSegment(value: 'weekly', label: Text('Weekly')),
              ButtonSegment(value: 'monthly', label: Text('Monthly')),
            ],
            selected: {_recurringPeriodName},
            onSelectionChanged: (selection) {
              final next = selection.isEmpty ? null : selection.first;
              if (next == null) return;
              setState(() => _recurringPeriodName = next);
            },
          ),
          const SizedBox(height: 18),
          _label('Recurring Amount'),
          const SizedBox(height: 8),
          _boxedInput(
            controller: _recurringAmountController,
            prefix: 'RM',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          _label('Start Date'),
          const SizedBox(height: 8),
          _dateButton(),
          const SizedBox(height: 16),
          _label('End Period'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _boxedInput(
                  controller: _endPeriodValueController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<EndPeriodUnit>(
                  initialValue: _endPeriodUnit,
                  decoration: _dropdownDecoration(),
                  items: EndPeriodUnit.values
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _endPeriodUnit = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Estimated End Date'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _formattedDate(_estimatedDeadline()),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF203247)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesInput() {
    return Column(
      children: [
        ...List.generate(_milestones.length, (index) {
          final milestone = _milestones[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == _milestones.length - 1 ? 0 : 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Milestone ${index + 1}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF203247)),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _milestones.length == 1
                            ? null
                            : () {
                                setState(() {
                                  final removed = _milestones.removeAt(index);
                                  removed.dispose();
                                });
                              },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  _fieldLabel('Target Amount'),
                  _simpleField(milestone.amountController, prefix: 'RM', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  _fieldLabel('Label'),
                  _simpleField(milestone.labelController),
                  const SizedBox(height: 12),
                  _fieldLabel('Reward'),
                  _simpleField(milestone.rewardController),
                  const SizedBox(height: 12),
                  _fieldLabel('Description'),
                  _simpleField(milestone.descriptionController, maxLines: 2),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addMilestone,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Milestone'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionBody() {
    return switch (widget.section) {
      GoalPlannerSectionType.targetAmount => _targetSuggestionContent(),
      GoalPlannerSectionType.contributionRatio => _ratioSuggestionContent(),
      GoalPlannerSectionType.recurringPlan => _recurringSuggestionContent(),
      GoalPlannerSectionType.milestones => _milestoneSuggestionContent(),
    };
  }

  Widget _targetSuggestionContent() {
    final target = _suggestedTargetAmount();
    final durationValue = widget.output.endPeriodSuggestion.durationValue;
    final durationUnit = widget.output.endPeriodSuggestion.durationUnit;
    final perPeriod = widget.output.recurringTargetSuggestion.amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most users typically save around ${CurrencyUtils.asRm(target)} for this goal. A $durationValue-$durationUnit plan works well!',
          style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: Color(0xFF1B5751)),
        ),
        const SizedBox(height: 18),
        _suggestionHighlight(
          title: 'RECOMMENDED TIMELINE',
          headline: '$durationValue ${durationUnit[0].toUpperCase()}${durationUnit.substring(1)}',
          footer: '~${CurrencyUtils.asRm(perPeriod)}/${widget.output.recurringTargetSuggestion.recurringType.name}',
        ),
      ],
    );
  }

  Widget _ratioSuggestionContent() {
    final ratio = widget.output.contributionRatioSuggestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ratio.reason,
          style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: Color(0xFF1B5751)),
        ),
        const SizedBox(height: 18),
        _suggestionHighlight(
          title: 'RECOMMENDED SPLIT',
          headline:
              'Child ${ratio.childContributionPercentage.toStringAsFixed(0)}% / Parent ${ratio.parentContributionPercentage.toStringAsFixed(0)}%',
          footer: '${CurrencyUtils.asRm(ratio.childContributionAmount)} + ${CurrencyUtils.asRm(ratio.parentContributionAmount)}',
        ),
      ],
    );
  }

  Widget _recurringSuggestionContent() {
    final recurring = widget.output.recurringTargetSuggestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recurring.reason,
          style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: Color(0xFF1B5751)),
        ),
        const SizedBox(height: 18),
        _suggestionHighlight(
          title: 'RECOMMENDED PLAN',
          headline: '${CurrencyUtils.asRm(recurring.amount)} ${recurring.recurringType.name}',
          footer: 'For ${widget.output.endPeriodSuggestion.durationValue} ${widget.output.endPeriodSuggestion.durationUnit}',
        ),
      ],
    );
  }

  Widget _milestoneSuggestionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'These milestones keep the goal motivating and easy to track for both parent and child.',
          style: TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: Color(0xFF1B5751)),
        ),
        const SizedBox(height: 18),
        ...widget.output.milestoneSuggestions.take(4).map(
              (milestone) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _milestoneChip(milestone),
              ),
            ),
      ],
    );
  }

  Widget _suggestionHighlight({
    required String title,
    required String headline,
    required String footer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF6EF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF356C67)),
              ),
              const Spacer(),
              Text(
                headline,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0A615B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF0A615B),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              footer,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3F5755)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneChip(MilestoneSuggestion milestone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF6EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            milestone.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0A615B)),
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyUtils.asRm(milestone.amount)} - ${milestone.description}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF356C67)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String amount, String percentage) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF708092))),
          const SizedBox(height: 6),
          Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF203247))),
          const SizedBox(height: 2),
          Text(percentage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0A7B73))),
        ],
      ),
    );
  }

  Widget _boxedInput({
    required TextEditingController controller,
    String? prefix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixText: prefix == null ? null : '$prefix ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _simpleField(
    TextEditingController controller, {
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixText: prefix == null ? null : '$prefix ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dateButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked == null) return;
        setState(() => _startDate = picked);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(
              _formattedDate(_startDate),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF203247)),
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF0A7B73)),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _label(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF203247)),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF506277)),
      ),
    );
  }

  String _headerTitle() {
    return 'GOAL PLANNER AGENT';
  }

  String _questionTitle() {
    return switch (widget.section) {
      GoalPlannerSectionType.targetAmount => 'How much would you like to save?',
      GoalPlannerSectionType.contributionRatio => 'How should the goal be shared?',
      GoalPlannerSectionType.recurringPlan => 'How often would you like to save?',
      GoalPlannerSectionType.milestones => 'What milestones should unlock rewards?',
    };
  }

  String _questionSubtitle() {
    return switch (widget.section) {
      GoalPlannerSectionType.targetAmount => 'Set your target amount for your new goal.',
      GoalPlannerSectionType.contributionRatio => 'Confirm how the child and parent will split this target.',
      GoalPlannerSectionType.recurringPlan => 'Choose the recurring amount, timeline, and estimated deadline.',
      GoalPlannerSectionType.milestones => 'Review and edit milestone rewards that keep the journey exciting.',
    };
  }

  String _sheetTitle() {
    return 'Agent Suggestion';
  }

  String _sheetSubtitle() {
    return switch (widget.section) {
      GoalPlannerSectionType.targetAmount => 'Most users typically save around',
      GoalPlannerSectionType.contributionRatio => 'Suggested split for this goal',
      GoalPlannerSectionType.recurringPlan => 'Suggested recurring saving plan',
      GoalPlannerSectionType.milestones => 'Suggested milestone checkpoints',
    };
  }

  String _sheetButtonLabel() {
    return switch (widget.section) {
      GoalPlannerSectionType.targetAmount => 'Confirm Amount',
      GoalPlannerSectionType.contributionRatio => 'Confirm Split',
      GoalPlannerSectionType.recurringPlan => 'Confirm Plan',
      GoalPlannerSectionType.milestones => 'Confirm Milestones',
    };
  }

  void _adjustAmount(double delta) {
    final next = (_targetAmountValue() + delta).clamp(0, double.infinity);
    setState(() => _targetAmountController.text = next.toStringAsFixed(0));
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(
        _MilestoneDraft(
          amountController: TextEditingController(text: _targetAmountValue().toStringAsFixed(0)),
          labelController: TextEditingController(text: 'New Milestone'),
          rewardController: TextEditingController(text: 'Family reward'),
          descriptionController: TextEditingController(text: 'Custom milestone description'),
        ),
      );
    });
  }

  double _targetAmountValue() {
    return double.tryParse(_targetAmountController.text.trim()) ?? _suggestedTargetAmount();
  }

  double _suggestedTargetAmount() {
    final ratio = widget.output.contributionRatioSuggestion;
    final total = ratio.childContributionAmount + ratio.parentContributionAmount;
    return total > 0 ? total : widget.output.suggestedGoalAmount.amount;
  }

  DateTime _estimatedDeadline() {
    final endValue = int.tryParse(_endPeriodValueController.text.trim()) ?? widget.output.endPeriodSuggestion.durationValue;
    return switch (_endPeriodUnit) {
      EndPeriodUnit.days => _startDate.add(Duration(days: endValue)),
      EndPeriodUnit.weeks => _startDate.add(Duration(days: endValue * 7)),
      EndPeriodUnit.months => DateTime(_startDate.year, _startDate.month + endValue, _startDate.day),
    };
  }

  String _formattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  GoalPlannerConfirmedPlan _buildConfirmedPlan() {
    final targetAmount = _targetAmountValue();
    final childPercentage = _childPercentage;
    final parentPercentage = 100 - childPercentage;
    final childAmount = targetAmount * (childPercentage / 100);
    final parentAmount = targetAmount - childAmount;
    final milestones = _milestones
        .map(
          (m) => GoalPlannerConfirmedMilestone(
            amount: double.tryParse(m.amountController.text.trim()) ?? 0,
            label: m.labelController.text.trim(),
            rewardDescription: m.rewardController.text.trim(),
            description: m.descriptionController.text.trim(),
          ),
        )
        .toList(growable: false);

    return widget.confirmedPlan.copyWith(
      targetAmount: targetAmount,
      childContributionPercentage: childPercentage,
      parentContributionPercentage: parentPercentage,
      childContributionAmount: childAmount,
      parentContributionAmount: parentAmount,
      recurringPeriod: RecurringPeriod.values.firstWhere(
        (period) => period.name == _recurringPeriodName,
        orElse: () => widget.confirmedPlan.recurringPeriod,
      ),
      recurringAmount: double.tryParse(_recurringAmountController.text.trim()) ?? widget.confirmedPlan.recurringAmount,
      recurringStartDate: _startDate,
      endPeriodValue: int.tryParse(_endPeriodValueController.text.trim()) ?? widget.confirmedPlan.endPeriodValue,
      endPeriodUnit: _endPeriodUnit,
      deadline: _estimatedDeadline(),
      milestones: milestones,
    );
  }
}

class _SuggestionSheet extends StatelessWidget {
  const _SuggestionSheet({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.buttonLabel,
    required this.onApply,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final String buttonLabel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.44,
      minChildSize: 0.34,
      maxChildSize: 0.68,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF7AD0BD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6EBEAE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.work_history_outlined, color: Color(0xFF0A615B)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF173933)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1D4E48)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              body,
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF173933),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MilestoneDraft {
  _MilestoneDraft({
    required this.amountController,
    required this.labelController,
    required this.rewardController,
    required this.descriptionController,
  });

  final TextEditingController amountController;
  final TextEditingController labelController;
  final TextEditingController rewardController;
  final TextEditingController descriptionController;

  void dispose() {
    amountController.dispose();
    labelController.dispose();
    rewardController.dispose();
    descriptionController.dispose();
  }
}
