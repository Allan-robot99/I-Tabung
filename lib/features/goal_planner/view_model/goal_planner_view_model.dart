import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_confirmed_plan.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_input.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_output.dart';
import 'package:i_tabung/features/goal_planner/repository/goal_planner_contracts.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:i_tabung/features/goal_planner/service/goal_planner_exception.dart';

class GoalPlannerState {
  const GoalPlannerState({
    this.input,
    this.output,
    this.confirmedPlan,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isEditMode = false,
    this.error,
    this.successMessage,
    this.idempotencyKey,
    this.createdTabungId,
  });

  final GoalPlannerInput? input;
  final GoalPlannerOutput? output;
  final GoalPlannerConfirmedPlan? confirmedPlan;
  final bool isLoading;
  final bool isSubmitting;
  final bool isEditMode;
  final String? error;
  final String? successMessage;
  final String? idempotencyKey;
  final String? createdTabungId;

  GoalPlannerState copyWith({
    GoalPlannerInput? input,
    GoalPlannerOutput? output,
    GoalPlannerConfirmedPlan? confirmedPlan,
    bool? isLoading,
    bool? isSubmitting,
    bool? isEditMode,
    String? error,
    String? successMessage,
    String? idempotencyKey,
    String? createdTabungId,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return GoalPlannerState(
      input: input ?? this.input,
      output: output ?? this.output,
      confirmedPlan: confirmedPlan ?? this.confirmedPlan,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isEditMode: isEditMode ?? this.isEditMode,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdTabungId: createdTabungId ?? this.createdTabungId,
    );
  }
}

final goalPlannerViewModelProvider = StateNotifierProvider<GoalPlannerViewModel, GoalPlannerState>((ref) {
  return GoalPlannerViewModel(
    ref.watch(goalPlannerRepositoryProvider),
    ref.watch(analyticsRepositoryProvider),
    ref.watch(userContextRepositoryProvider),
    ref.watch(tabungRepositoryProvider),
    ref.watch(milestoneRepositoryProvider),
    ref.watch(tabungRequestRepositoryProvider),
  );
});

class GoalPlannerViewModel extends StateNotifier<GoalPlannerState> {
  GoalPlannerViewModel(
    this._plannerRepo,
    this._analyticsRepo,
    this._userContextRepo,
    this._tabungRepo,
    this._milestoneRepo,
    this._requestRepo,
  ) : super(const GoalPlannerState());

  final GoalPlannerRepository _plannerRepo;
  final AnalyticsRepository _analyticsRepo;
  final UserContextRepository _userContextRepo;
  final TabungRepository _tabungRepo;
  final MilestoneRepository _milestoneRepo;
  final TabungRequestRepository _requestRepo;

  Future<void> generatePlan(GoalPlannerInput input) async {
    final nextKey = state.idempotencyKey ?? '${DateTime.now().microsecondsSinceEpoch}-${input.tabungName}';
    state = GoalPlannerState(
      isLoading: true,
      idempotencyKey: nextKey,
    );

    try {
      final context = await _userContextRepo.resolveSubmissionContext(input.userRole);

      final enrichedInput = input.copyWith(
        idempotencyKey: nextKey,
        userId: context.userId,
        familyId: context.familyId,
      );

      final output = await _plannerRepo.generatePlan(enrichedInput);
      await _analyticsRepo.trackEvent(
        name: 'goal_plan_generated',
        properties: {
          'tabungType': enrichedInput.tabungType.name,
          'suggestedGoalAmount': output.suggestedGoalAmount.amount,
          'idempotencyKey': nextKey,
        },
      );
      state = state.copyWith(isLoading: false, input: enrichedInput, output: output);
      state = state.copyWith(
        confirmedPlan: GoalPlannerConfirmedPlan.fromPlan(input: enrichedInput, output: output),
      );
    } catch (e) {
      await _analyticsRepo.trackEvent(
        name: 'goal_plan_generate_failed',
        properties: {'error': e.toString(), 'idempotencyKey': nextKey},
      );
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  void reset() {
    state = const GoalPlannerState();
  }

  void setEditMode(bool value) {
    state = state.copyWith(isEditMode: value);
  }

  void updateConfirmedPlan(GoalPlannerConfirmedPlan confirmedPlan) {
    state = state.copyWith(confirmedPlan: confirmedPlan, clearError: true, clearSuccess: true);
  }

  Future<void> submitPlan() async {
    final input = state.input;
    final output = state.output;
    final confirmedPlan = state.confirmedPlan;
    if (input == null || output == null || confirmedPlan == null) {
      state = state.copyWith(error: 'Generate plan first.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);

    try {
      final context = await _userContextRepo.resolveSubmissionContext(input.userRole);
      final finalInput = _buildConfirmedInput(input, confirmedPlan);
      final finalOutput = _buildConfirmedOutput(output, confirmedPlan, finalInput.tabungName);

      late final String tabungId;
      if (input.userRole == UserRole.child) {
        tabungId = await _tabungRepo.createPendingTabungWithPlan(
          input: finalInput,
          output: finalOutput,
          confirmedPlan: confirmedPlan,
          familyId: context.familyId,
          childId: context.childId,
          createdBy: context.userId,
        );
        await _milestoneRepo.insertSuggestedMilestones(tabungId: tabungId, milestones: finalOutput.milestoneRewardSuggestions);
        await _requestRepo.createRequest(
          tabungId: tabungId,
          requestedBy: context.userId,
          familyId: context.familyId,
          parentId: context.parentId,
        );
        await _analyticsRepo.trackEvent(
          name: 'goal_plan_submitted_to_parent',
          properties: {'tabungId': tabungId, 'familyId': context.familyId},
        );
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Plan submitted to parent for approval.',
          createdTabungId: tabungId,
        );
      } else {
        tabungId = await _tabungRepo.activateParentCreatedTabung(
          input: finalInput,
          output: finalOutput,
          confirmedPlan: confirmedPlan,
          familyId: context.familyId,
          childId: context.childId,
          createdBy: context.userId,
        );
        await _milestoneRepo.insertSuggestedMilestones(tabungId: tabungId, milestones: finalOutput.milestoneRewardSuggestions);
        await _analyticsRepo.trackEvent(
          name: 'goal_plan_parent_activated',
          properties: {'tabungId': tabungId, 'familyId': context.familyId},
        );
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Parent plan accepted and activated.',
          createdTabungId: tabungId,
        );
      }
    } catch (e) {
      await _analyticsRepo.trackEvent(
        name: 'goal_plan_submit_failed',
        properties: {'error': e.toString()},
      );
      state = state.copyWith(isSubmitting: false, error: _friendlyError(e));
    }
  }

  String _friendlyError(Object error) {
    if (error is GoalPlannerException) {
      switch (error.code) {
        case 'invalid_input':
          final message = error.message.trim();
          return message.isNotEmpty
              ? message
              : 'Some required goal details are missing. Please review your inputs.';
        case 'agent_timeout':
          return 'The planner took too long. Please retry once.';
        case 'schema_invalid':
          return 'Planner response format was invalid. Please retry.';
        case 'service_unavailable':
          return 'Planner service is temporarily unavailable. Please try again shortly.';
      }
    }
    final message = error.toString().toLowerCase();
    if (message.contains('timeout')) {
      return 'The planner timed out. Please retry.';
    }
    return 'Unable to process the goal plan right now. Please try again.';
  }

  GoalPlannerInput _buildConfirmedInput(GoalPlannerInput input, GoalPlannerConfirmedPlan confirmedPlan) {
    return GoalPlannerInput(
      userRole: input.userRole,
      tabungType: input.tabungType,
      tabungName: input.tabungName,
      tabungDescription: input.tabungDescription,
      idempotencyKey: input.idempotencyKey,
      userId: input.userId,
      familyId: input.familyId,
      tabungId: input.tabungId,
    );
  }

  GoalPlannerOutput _buildConfirmedOutput(
    GoalPlannerOutput output,
    GoalPlannerConfirmedPlan confirmedPlan,
    String tabungName,
  ) {
    final milestoneSuggestions = confirmedPlan.milestones
        .map(
          (m) => MilestoneSuggestion(
            targetAmount: m.amount,
            milestoneLabel: m.label,
            rewardSuggestion: m.rewardDescription,
            reason: m.description,
          ),
        )
        .toList(growable: false);

    return GoalPlannerOutput(
      suggestedGoalAmount: SuggestedGoalAmount(
        amount: confirmedPlan.targetAmount,
        reason: output.suggestedGoalAmount.reason,
      ),
      recurringTargetSuggestion: RecurringTargetSuggestion(
        recurringType: confirmedPlan.recurringPeriod,
        amount: confirmedPlan.recurringAmount,
        reason: output.recurringTargetSuggestion.reason,
      ),
      milestoneRewardSuggestions: milestoneSuggestions,
      endPeriodSuggestion: EndPeriodSuggestion(
        durationValue: confirmedPlan.endPeriodValue,
        durationUnit: confirmedPlan.endPeriodUnit.name,
        reason: output.endPeriodSuggestion.reason,
      ),
      contributionRatioSuggestion: ContributionRatioSuggestion(
        childContributionAmount: confirmedPlan.childContributionAmount,
        parentContributionAmount: confirmedPlan.parentContributionAmount,
        childContributionPercentage: confirmedPlan.childContributionPercentage,
        parentContributionPercentage: confirmedPlan.parentContributionPercentage,
        reason: output.contributionRatioSuggestion.reason,
      ),
      summary:
          'For $tabungName, save RM${confirmedPlan.recurringAmount.toStringAsFixed(2)} ${confirmedPlan.recurringPeriod.name} until ${confirmedPlan.deadline.toIso8601String().split('T').first}.',
    );
  }
}
