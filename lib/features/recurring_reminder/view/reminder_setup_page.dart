import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/features/goaldashboard/models/goal_model.dart';
import 'package:i_tabung/features/recurring_reminder/repository/recurring_reminder_repository.dart';
import 'package:i_tabung/features/recurring_reminder/view/reminder_preview_page.dart';
import 'package:i_tabung/features/recurring_reminder/view_model/recurring_reminder_view_model.dart';

class ReminderSetupPage extends ConsumerStatefulWidget {
  const ReminderSetupPage({
    super.key,
    required this.goal,
  });

  final GoalModel goal;

  @override
  ConsumerState<ReminderSetupPage> createState() => _ReminderSetupPageState();
}

class _ReminderSetupPageState extends ConsumerState<ReminderSetupPage> {
  late final RecurringReminderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecurringReminderViewModel(
      ref.read(recurringReminderRepositoryProvider),
      widget.goal,
    );
    _viewModel.addListener(_handleStateChanged);
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F8FA),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Goal Reminder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryCard(goal: widget.goal),
                        const SizedBox(height: 18),
                        const Text(
                          'Reminder Time',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF172638)),
                        ),
                        const SizedBox(height: 10),
                        _SelectionButton(
                          label: state.selectedTime == null
                              ? 'Choose time'
                              : DateFormat('h:mm a').format(
                                  DateTime(2000, 1, 1, state.selectedTime!.hour, state.selectedTime!.minute),
                                ),
                          onTap: _pickTime,
                        ),
                        if (widget.goal.recurringPeriod == 'weekly') ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Reminder Day',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF172638)),
                          ),
                          const SizedBox(height: 10),
                          _DayDropdown(
                            value: state.selectedDayOfWeek ?? 'Monday',
                            onChanged: (value) => _viewModel.setDayOfWeek(value),
                          ),
                        ],
                        if (widget.goal.recurringPeriod == 'monthly') ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Reminder Date',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF172638)),
                          ),
                          const SizedBox(height: 10),
                          _MonthDayDropdown(
                            value: state.selectedDayOfMonth ?? 1,
                            onChanged: (value) => _viewModel.setDayOfMonth(value),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Text(
                          'Calendar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF172638)),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                state.context?.isCalendarConnected == true
                                    ? Icons.calendar_month_rounded
                                    : Icons.link_rounded,
                                color: const Color(0xFF0B5D56),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.context?.isCalendarConnected == true
                                      ? 'Google Calendar connected'
                                      : 'Connect Google Calendar',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF172638),
                                  ),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: state.isConnecting ? null : _viewModel.connectGoogleCalendar,
                                child: state.isConnecting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(state.context?.isCalendarConnected == true ? 'Reconnect' : 'Connect'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.isSubmitting ? null : _previewReminder,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0B7A63),
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: state.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Preview Reminder',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _viewModel.state.selectedTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) {
      _viewModel.setTime(picked);
    }
  }

  Future<void> _previewReminder() async {
    final success = await _viewModel.previewReminder();
    if (!mounted || !success) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReminderPreviewPage(viewModel: _viewModel)),
    );
    if (!mounted || created != true) return;
    Navigator.of(context).pop(true);
  }

  void _handleStateChanged() {
    final error = _viewModel.state.error;
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    _viewModel.clearError();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.goal});

  final GoalModel goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF172638))),
          const SizedBox(height: 14),
          Text('Target: ${CurrencyUtils.asRm(goal.targetAmount)}'),
          Text('Saved: ${CurrencyUtils.asRm(goal.savedAmount)}'),
          Text('Recurring Target: ${CurrencyUtils.asRm(goal.periodTarget)} ${goal.recurringPeriod}'),
        ],
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(label),
    );
  }
}

class _DayDropdown extends StatelessWidget {
  const _DayDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: days
          .map((day) => DropdownMenuItem<String>(value: day, child: Text(day)))
          .toList(growable: false),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}

class _MonthDayDropdown extends StatelessWidget {
  const _MonthDayDropdown({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      items: List.generate(
        28,
        (index) => DropdownMenuItem<int>(value: index + 1, child: Text('Day ${index + 1}')),
      ),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}
