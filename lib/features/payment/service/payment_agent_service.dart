import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:i_tabung/features/payment/model/payment_review_request.dart';
import 'package:i_tabung/features/payment/model/payment_review_response.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final paymentAgentServiceProvider = Provider<PaymentAgentService>((ref) {
  return SupabasePaymentAgentService(ref.watch(supabaseClientProvider));
});

abstract class PaymentAgentService {
  Future<PaymentReviewResponse> reviewPayment(PaymentReviewRequest request);
}

class SupabasePaymentAgentService implements PaymentAgentService {
  SupabasePaymentAgentService(this._client);

  final SupabaseClient _client;

  @override
  Future<PaymentReviewResponse> reviewPayment(PaymentReviewRequest request) async {
    final response = await _client.functions.invoke(
      'spending-habit-coach-agent',
      body: request.toJson(),
    );

    final data = response.data;
    if (response.status >= 200 && response.status < 300 && data is Map<String, dynamic>) {
      return PaymentReviewResponse.fromJson(data);
    }

    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        throw Exception(error['message']?.toString() ?? 'Payment coach request failed.');
      }
    }

    throw Exception('Invalid payment coach response.');
  }
}
