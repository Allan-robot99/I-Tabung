import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i_tabung/features/transactions/model/transaction_flow_type.dart';
import 'package:i_tabung/features/goal_planner/repository/supabase_goal_planner_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return SupabaseTransactionRepository(ref.watch(supabaseClientProvider));
});

abstract class TransactionRepository {
  Future<void> submitTransaction({
    required TransactionFlowType flowType,
    required String tabungId,
    required String tabungName,
    required double amount,
    String? purpose,
    String? paymentMethod,
  });
}

class SupabaseTransactionRepository implements TransactionRepository {
  SupabaseTransactionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> submitTransaction({
    required TransactionFlowType flowType,
    required String tabungId,
    required String tabungName,
    required double amount,
    String? purpose,
    String? paymentMethod,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('User must be logged in.');
    }

    final familyRows = await _client.from('family_members').select('family_id').eq('user_id', userId).limit(1);
    if ((familyRows as List).isEmpty) {
      throw Exception('No family membership found for the current user.');
    }
    final familyId = familyRows.first['family_id'] as String;

    final tabungRows = await _client
        .from('tabung_goals')
        .select('current_amount')
        .eq('id', tabungId)
        .limit(1);
    if ((tabungRows as List).isEmpty) {
      throw Exception('Selected tabung could not be found.');
    }

    final currentAmount = (tabungRows.first['current_amount'] as num?)?.toDouble() ?? 0;
    final nextAmount = flowType == TransactionFlowType.deposit ? currentAmount + amount : currentAmount - amount;

    if (flowType == TransactionFlowType.spend && nextAmount < 0) {
      throw Exception('Spending amount cannot be more than the current tabung amount.');
    }

    if (flowType == TransactionFlowType.deposit) {
      await _client.from('savings_entries').insert({
        'tabung_id': tabungId,
        'user_id': userId,
        'amount': amount,
        'source': 'deposit',
        'note': purpose?.trim().isNotEmpty == true ? purpose!.trim() : 'Deposit to $tabungName',
      });
    } else {
      await _client
          .from('tabung_goals')
          .update({'current_amount': nextAmount})
          .eq('id', tabungId);
    }

    final transactionPurpose = flowType == TransactionFlowType.deposit
        ? 'Deposit to $tabungName'
        : (purpose?.trim().isNotEmpty == true ? purpose!.trim() : 'Spending from $tabungName');

    final payload = <String, dynamic>{
      'user_id': userId,
      'family_id': familyId,
      'tabung_id': tabungId,
      'purpose': transactionPurpose,
      'amount': amount,
      'status': 'confirmed',
      'confirmed_at': DateTime.now().toIso8601String(),
      if (paymentMethod != null && paymentMethod.trim().isNotEmpty) 'bank_transfer_reference': paymentMethod.trim(),
    };

    try {
      await _client.from('payment_transactions').insert(payload);
    } catch (_) {
      // Keep balance updates resilient even if transaction logging has additional DB constraints.
    }
  }
}
