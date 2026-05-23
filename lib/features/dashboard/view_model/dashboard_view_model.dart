import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/dashboard/model/dashboard_state.dart';
import 'package:i_tabung/features/dashboard/repository/dashboard_repository.dart';
import 'package:i_tabung/features/dashboard/repository/supabase_dashboard_repository.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';

final dashboardViewModelProvider =
    StateNotifierProvider.autoDispose.family<DashboardViewModel, DashboardState, UserRole>((ref, role) {
  return DashboardViewModel(
    ref.watch(dashboardRepositoryProvider),
    role,
  )..load();
});

class DashboardViewModel extends StateNotifier<DashboardState> {
  DashboardViewModel(this._repository, this._role) : super(DashboardState.initial());

  final DashboardRepository _repository;
  final UserRole _role;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repository.loadDashboard(_role);
      final clampedIndex = data.tabungs.isEmpty ? 0 : state.selectedIndex.clamp(0, data.tabungs.length - 1);
      state = state.copyWith(
        isLoading: false,
        data: data,
        selectedIndex: clampedIndex,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> refresh() => load();

  void selectTabungIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  bool canCreateTabung() {
    if (_role != UserRole.parent) return false;
    return state.data?.hasChildInFamily ?? false;
  }

  String? familyCode() => state.data?.familyCode;

  Future<void> signOut() async {
    await _repository.signOut();
  }
}
