import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:i_tabung/core/utils/currency_utils.dart';
import 'package:i_tabung/features/recurring_reminder/view_model/recurring_reminder_view_model.dart';

class ReminderPreviewPage extends StatefulWidget {
  const ReminderPreviewPage({
    super.key,
    required this.viewModel,
  });

  final RecurringReminderViewModel viewModel;

  @override
  State<ReminderPreviewPage> createState() => _ReminderPreviewPageState();
}

class _ReminderPreviewPageState extends State<ReminderPreviewPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final preview = widget.viewModel.state.preview;
        if (preview == null) {
          return const Scaffold(
            body: Center(child: Text('Reminder preview is unavailable.')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F8FA),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Reminder Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview.reminderPlan.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF172638),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Every ${preview.reminderPlan.suggestedReminderDay} at ${_prettyTime(preview.reminderPlan.suggestedReminderTime)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B5D56),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'From ${_prettyDate(preview.reminderPlan.startDate)} until ${_prettyDate(preview.reminderPlan.endDate)}',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF667487)),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          preview.googleCalendarEvent.description,
                          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF42556A)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF7F4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Recurring Target: ${CurrencyUtils.asRm(preview.reminderPlan.recurringAmount)} ${preview.reminderPlan.recurringPeriod}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B5D56),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.viewModel.state.isSubmitting ? null : _createReminder,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B7A63),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: widget.viewModel.state.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Create Calendar Reminder',
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

  Future<void> _createReminder() async {
    final success = await widget.viewModel.createReminder();
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.viewModel.state.preview?.userMessage ?? 'Calendar reminder created.')),
    );
    Navigator.of(context).pop(true);
  }

  void _handleStateChanged() {
    final error = widget.viewModel.state.error;
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    widget.viewModel.clearError();
  }

  static String _prettyDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('d MMMM y').format(date);
  }

  static String _prettyTime(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return raw;
    final hour = int.tryParse(parts.first) ?? 20;
    final minute = int.tryParse(parts.last) ?? 0;
    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
  }
}
