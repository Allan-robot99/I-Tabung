import 'package:i_tabung/features/dashboard/model/dashboard_models.dart';
import 'package:i_tabung/features/payment/model/payment_review_request.dart';

class PaymentTransactionDraft {
  const PaymentTransactionDraft({
    required this.tabung,
    required this.amount,
    required this.buyingPurpose,
  });

  final DashboardTabungSummary tabung;
  final double amount;
  final String buyingPurpose;

  PaymentTransactionDraft copyWith({
    DashboardTabungSummary? tabung,
    double? amount,
    String? buyingPurpose,
  }) {
    return PaymentTransactionDraft(
      tabung: tabung ?? this.tabung,
      amount: amount ?? this.amount,
      buyingPurpose: buyingPurpose ?? this.buyingPurpose,
    );
  }
}

class PaymentUserContext {
  const PaymentUserContext({
    required this.userId,
    required this.familyId,
  });

  final String userId;
  final String familyId;
}

class PaymentReviewBundle {
  const PaymentReviewBundle({
    required this.request,
    required this.locationContext,
  });

  final PaymentReviewRequest request;
  final PaymentLocationContext locationContext;
}
