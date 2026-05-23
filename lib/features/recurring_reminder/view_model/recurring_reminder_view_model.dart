import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:i_tabung/features/goaldashboard/models/goal_model.dart';
import 'package:i_tabung/features/recurring_reminder/model/reminder_setup_request.dart';
import 'package:i_tabung/features/recurring_reminder/model/reminder_setup_response.dart';
import 'package:i_tabung/features/recurring_reminder/repository/recurring_reminder_repository.dart';

class RecurringReminderState {
  const RecurringReminderState({
    this.context,
    this.preview,
    this.selectedTime,
    this.selectedDayOfWeek,
    this.selectedDayOfMonth,
    this.isLoading = false,
    this.isConnecting = false,
    this.isSubmitting = false,
    this.error,
  });

  final ReminderContext? context;
  final ReminderSetupResponse? preview;
  final TimeOfDay? selectedTime;
  final String? selectedDayOfWeek;
  final int? selectedDayOfMonth;
  final bool isLoading;
  final bool isConnecting;
  final bool isSubmitting;
  final String? error;

  RecurringReminderState copyWith({
    ReminderContext? context,
    ReminderSetupResponse? preview,
    TimeOfDay? selectedTime,
    String? selectedDayOfWeek,
    int? selectedDayOfMonth,
    bool? isLoading,
    bool? isConnecting,
    bool? isSubmitting,
    String? error,
    bool clearPreview = false,
    bool clearError = false,
  }) {
    return RecurringReminderState(
      context: context ?? this.context,
      preview: clearPreview ? null : (preview ?? this.preview),
      selectedTime: selectedTime ?? this.selectedTime,
      selectedDayOfWeek: selectedDayOfWeek ?? this.selectedDayOfWeek,
      selectedDayOfMonth: selectedDayOfMonth ?? this.selectedDayOfMonth,
      isLoading: isLoading ?? this.isLoading,
      isConnecting: isConnecting ?? this.isConnecting,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RecurringReminderViewModel extends ChangeNotifier {
  RecurringReminderViewModel(this._repository, this.goal);

  final RecurringReminderRepository _repository;
  final GoalModel goal;

  RecurringReminderState _state = const RecurringReminderState();
  RecurringReminderState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();
    try {
      final context = await _repository.loadContext();
      _state = _state.copyWith(
        context: context,
        selectedDayOfWeek: _state.selectedDayOfWeek ?? 'Monday',
        selectedDayOfMonth: _state.selectedDayOfMonth ?? 1,
        isLoading: false,
        clearError: true,
      );
      notifyListeners();
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''), isLoading: false);
    }
  }

  void setTime(TimeOfDay value) {
    _state = _state.copyWith(selectedTime: value, clearPreview: true, clearError: true);
    notifyListeners();
  }

  void setDayOfWeek(String value) {
    _state = _state.copyWith(selectedDayOfWeek: value, clearPreview: true, clearError: true);
    notifyListeners();
  }

  void setDayOfMonth(int value) {
    _state = _state.copyWith(selectedDayOfMonth: value, clearPreview: true, clearError: true);
    notifyListeners();
  }

  Future<void> connectGoogleCalendar() async {
    _state = _state.copyWith(isConnecting: true, clearError: true);
    notifyListeners();
    try {
      await _repository.connectGoogleCalendar();
      final context = await _repository.loadContext();
      _state = _state.copyWith(context: context, isConnecting: false, clearError: true);
      notifyListeners();
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''), isConnecting: false);
    }
  }

  Future<bool> previewReminder() async {
    try {
      final request = _buildRequest(mode: 'preview');
      _state = _state.copyWith(isSubmitting: true, clearError: true, clearPreview: true);
      notifyListeners();
      final preview = await _repository.previewReminder(request);
      _state = _state.copyWith(preview: preview, isSubmitting: false, clearError: true);
      notifyListeners();
      return true;
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''), isSubmitting: false);
      return false;
    }
  }

  Future<bool> createReminder() async {
    try {
      final request = _buildRequest(mode: 'create');
      _state = _state.copyWith(isSubmitting: true, clearError: true);
      notifyListeners();
      final preview = await _repository.createReminder(request);
      _state = _state.copyWith(preview: preview, isSubmitting: false, clearError: true);
      notifyListeners();
      return true;
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''), isSubmitting: false);
      return false;
    }
  }

  void clearError() {
    if (_state.error == null) return;
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  ReminderSetupRequest _buildRequest({required String mode}) {
    final context = _state.context;
    if (context == null) {
      throw Exception('Reminder context is not ready.');
    }
    final time = _state.selectedTime;
    if (time == null) {
      throw Exception('Please choose reminder time.');
    }
    if (goal.periodTarget <= 0) {
      throw Exception('Please setup recurring target first.');
    }

    final timeText = DateFormat('HH:mm').format(DateTime(2000, 1, 1, time.hour, time.minute));
    if (goal.recurringPeriod == 'weekly' && (_state.selectedDayOfWeek == null || _state.selectedDayOfWeek!.trim().isEmpty)) {
      throw Exception('Please choose reminder day.');
    }
    if (goal.recurringPeriod == 'monthly' && _state.selectedDayOfMonth == null) {
      throw Exception('Please choose reminder date.');
    }

    return ReminderSetupRequest(
      mode: mode,
      userId: context.userId,
      familyId: context.familyId,
      tabungId: goal.id,
      timezone: 'Asia/Kuala_Lumpur',
      reminderSettings: ReminderSettings(
        reminderTime: timeText,
        reminderDayOfWeek: goal.recurringPeriod == 'weekly' ? _state.selectedDayOfWeek : null,
        reminderDayOfMonth: goal.recurringPeriod == 'monthly' ? _state.selectedDayOfMonth : null,
        googleCalendarId: context.googleCalendarId,
      ),
    );
  }

  void _setError(String message, {bool? isLoading, bool? isConnecting, bool? isSubmitting}) {
    _state = _state.copyWith(
      error: message,
      isLoading: isLoading ?? _state.isLoading,
      isConnecting: isConnecting ?? _state.isConnecting,
      isSubmitting: isSubmitting ?? _state.isSubmitting,
    );
    notifyListeners();
  }
}
