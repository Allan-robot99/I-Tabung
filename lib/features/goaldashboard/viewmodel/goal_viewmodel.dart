import 'package:flutter/foundation.dart';
import 'package:i_tabung/features/goaldashboard/models/goal_model.dart';
import 'package:i_tabung/features/goaldashboard/repository/goal_summary_repository.dart';

class GoalViewModel extends ChangeNotifier {
  GoalViewModel(this._repository);

  final GoalSummaryRepository _repository;

  GoalModel? _goal;
  GoalModel? get goal => _goal;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String tabungId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _goal = await _repository.loadGoal(tabungId);
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_goal == null) return;
    await load(_goal!.id);
  }

  void viewInCalendar() {
    debugPrint('Calendar sync status: ${_goal?.calendarSync?.syncStatus}');
  }

  String get greetingMessage {
    final currentGoal = _goal;
    if (currentGoal == null) return '';
    if (currentGoal.isOnTrack) {
      return "Great job! You're on track with your savings this ${currentGoal.periodLabel}.";
    }
    return 'You planned to save RM${currentGoal.periodTarget.toStringAsFixed(0)} this ${currentGoal.periodLabel}, '
        'but you\'ve saved RM${currentGoal.periodSaved.toStringAsFixed(0)}. '
        'You only need ${currentGoal.formattedRemaining} more!';
  }
}
