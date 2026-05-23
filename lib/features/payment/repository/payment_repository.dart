import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:i_tabung/features/payment/model/payment_review_request.dart';
import 'package:i_tabung/features/payment/model/payment_review_response.dart';
import 'package:i_tabung/features/payment/model/payment_transaction_draft.dart';
import 'package:i_tabung/features/payment/service/payment_agent_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(paymentAgentServiceProvider),
  );
});

abstract class PaymentRepository {
  Future<PaymentUserContext> resolveUserContext();

  Future<PaymentReviewResponse> requestReview({
    required PaymentTransactionDraft draft,
    required PaymentLocationContext locationContext,
  });

  Future<void> confirmPayment({
    required PaymentTransactionDraft draft,
    required PaymentReviewResponse review,
    required PaymentLocationContext locationContext,
  });
}

class SupabasePaymentRepository implements PaymentRepository {
  SupabasePaymentRepository(this._client, this._agentService);

  final SupabaseClient _client;
  final PaymentAgentService _agentService;

  @override
  Future<PaymentUserContext> resolveUserContext() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('User must be logged in.');
    }

    final familyRows = await _client.from('family_members').select('family_id').eq('user_id', userId).limit(1);
    if ((familyRows as List).isEmpty) {
      throw Exception('No family membership found for the current user.');
    }

    return PaymentUserContext(
      userId: userId,
      familyId: familyRows.first['family_id'] as String,
    );
  }

  @override
  Future<PaymentReviewResponse> requestReview({
    required PaymentTransactionDraft draft,
    required PaymentLocationContext locationContext,
  }) async {
    final context = await resolveUserContext();
    final request = PaymentReviewRequest(
      userId: context.userId,
      familyId: context.familyId,
      tabungId: draft.tabung.id,
      paymentAmount: draft.amount,
      buyingPurpose: draft.buyingPurpose,
      locationContext: locationContext,
    );
    return _agentService.reviewPayment(request);
  }

  @override
  Future<void> confirmPayment({
    required PaymentTransactionDraft draft,
    required PaymentReviewResponse review,
    required PaymentLocationContext locationContext,
  }) async {
    final context = await resolveUserContext();
    final tabungRows = await _client
        .from('tabung_goals')
        .select('current_amount')
        .eq('id', draft.tabung.id)
        .limit(1);

    if ((tabungRows as List).isEmpty) {
      throw Exception('Selected tabung could not be found.');
    }

    final currentAmount = (tabungRows.first['current_amount'] as num?)?.toDouble() ?? 0;
    final nextAmount = currentAmount - draft.amount;
    if (nextAmount < 0) {
      throw Exception('Payment amount is higher than your tabung balance.');
    }

    await _client.from('payment_transactions').insert({
      'user_id': context.userId,
      'family_id': context.familyId,
      'tabung_id': draft.tabung.id,
      'amount': draft.amount,
      'purpose': draft.buyingPurpose,
      'category': review.guessedSpendingPlace.placeCategory,
      'coach_response': review.toJson(),
      'impact_warning': review.spendingImpact.impactWarning,
      'recurring_target_reminder': review.recurringTargetReminder.message,
      'estimated_delay_text':
          '${review.spendingImpact.estimatedDelayValue} ${review.spendingImpact.estimatedDelayUnit}',
      'alternative_suggestion': jsonEncode(
        review.alternativeSuggestions.map((item) => item.toJson()).toList(growable: false),
      ),
      'budget_health_tip': review.recommendation.message,
      'should_proceed': review.recommendation.shouldProceed,
      'status': 'confirmed',
      'confirmed_at': DateTime.now().toIso8601String(),
      'latitude': locationContext.latitude,
      'longitude': locationContext.longitude,
      'location_accuracy': locationContext.accuracyMeters,
      'location_permission_status': locationContext.permissionStatus,
      'guessed_place_name': review.guessedSpendingPlace.placeName,
      'guessed_place_category': review.guessedSpendingPlace.placeCategory,
      'guessed_place_confidence': review.guessedSpendingPlace.confidence,
      'guessed_place_reason': review.guessedSpendingPlace.reason,
    });

    await _client.from('tabung_goals').update({'current_amount': nextAmount}).eq('id', draft.tabung.id);
  }
}
