import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';

class TabungCreationCoordinatorState {
  const TabungCreationCoordinatorState({
    this.currentStep = 0,
    this.creatorRole = UserRole.child,
  });

  final int currentStep;
  final UserRole creatorRole;

  TabungCreationCoordinatorState copyWith({
    int? currentStep,
    UserRole? creatorRole,
  }) {
    return TabungCreationCoordinatorState(
      currentStep: currentStep ?? this.currentStep,
      creatorRole: creatorRole ?? this.creatorRole,
    );
  }
}

final tabungCreationCoordinatorProvider =
    StateNotifierProvider<TabungCreationCoordinatorViewModel, TabungCreationCoordinatorState>(
  (ref) => TabungCreationCoordinatorViewModel(),
);

class TabungCreationCoordinatorViewModel extends StateNotifier<TabungCreationCoordinatorState> {
  TabungCreationCoordinatorViewModel() : super(const TabungCreationCoordinatorState());

  void setCreatorRole(UserRole role) {
    state = state.copyWith(creatorRole: role);
  }

  void moveToStep(int step) {
    state = state.copyWith(currentStep: step);
  }
}
