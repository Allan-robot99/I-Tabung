import 'package:i_tabung/features/dashboard/model/dashboard_models.dart';

class DashboardState {
  const DashboardState({
    required this.isLoading,
    required this.selectedIndex,
    this.data,
    this.error,
  });

  final bool isLoading;
  final int selectedIndex;
  final DashboardData? data;
  final String? error;

  factory DashboardState.initial() => const DashboardState(
        isLoading: true,
        selectedIndex: 0,
      );

  DashboardState copyWith({
    bool? isLoading,
    int? selectedIndex,
    DashboardData? data,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      data: data ?? this.data,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
