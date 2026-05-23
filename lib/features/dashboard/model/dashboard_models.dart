class DashboardData {
  const DashboardData({
    required this.fullName,
    required this.familyCode,
    required this.hasChildInFamily,
    required this.tabungs,
    required this.transactions,
  });

  final String fullName;
  final String? familyCode;
  final bool hasChildInFamily;
  final List<DashboardTabungSummary> tabungs;
  final List<DashboardTransactionSummary> transactions;

  factory DashboardData.empty() => const DashboardData(
        fullName: 'User',
        familyCode: null,
        hasChildInFamily: false,
        tabungs: [],
        transactions: [],
      );
}

class DashboardTabungSummary {
  const DashboardTabungSummary({
    required this.id,
    required this.name,
    required this.goalAmount,
    required this.currentAmount,
    required this.status,
    required this.type,
  });

  final String id;
  final String name;
  final double goalAmount;
  final double currentAmount;
  final String status;
  final String type;
}

class DashboardTransactionSummary {
  const DashboardTransactionSummary({
    required this.purpose,
    required this.amount,
  });

  final String purpose;
  final double amount;
}
