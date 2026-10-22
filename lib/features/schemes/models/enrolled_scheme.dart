class EnrolledScheme {
  final String id;
  final String schemeId;
  final String name;

  final double totalAmount;
  final double amountPaid;
  final double amountBalance;

  final int monthsPaid;
  final int totalMonths;

  final String lastPaymentDate;
  final String nextDueDate;

  // Kept for compatibility with older UI.
  final bool isWeightBased;

  // CASH | GOLD_22K | GOLD_18K | SILVER
  final String rateType;

  final double accumulatedGrams;

  // Customer-selected monthly installment amount.
  final double installmentAmount;

  // Grams added in the most recent payment.
  final double lastPaymentGrams;

  // Monthly installment state returned by the backend.
  final bool hasMissedInstallments;
  final int missedInstallmentCount;
  final bool canPayOnline;
  final bool isCompleted;
  final bool isPaidThisMonth;
  final bool isNextInstallmentDue;
  final bool scheduleMissing;

  final int? nextInstallmentNumber;
  final String nextInstallmentStatus;

  EnrolledScheme({
    required this.id,
    required this.schemeId,
    required this.name,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountBalance,
    required this.monthsPaid,
    required this.totalMonths,
    required this.lastPaymentDate,
    required this.nextDueDate,
    required this.isWeightBased,
    required this.rateType,
    required this.accumulatedGrams,
    required this.installmentAmount,
    required this.hasMissedInstallments,
    required this.missedInstallmentCount,
    required this.canPayOnline,
    required this.isCompleted,
    required this.isPaidThisMonth,
    required this.isNextInstallmentDue,
    required this.scheduleMissing,
    required this.nextInstallmentNumber,
    required this.nextInstallmentStatus,
    this.lastPaymentGrams = 0.0,
  });

  bool get isCash => rateType == 'CASH';
  bool get isGold22K => rateType == 'GOLD_22K';
  bool get isGold18K => rateType == 'GOLD_18K';
  bool get isSilver => rateType == 'SILVER';
  bool get isGold => isGold22K || isGold18K;
  bool get isMetal => !isCash;

  String get assetLabel {
    switch (rateType) {
      case 'GOLD_22K':
        return '22K Gold';
      case 'GOLD_18K':
        return '18K Gold';
      case 'SILVER':
        return 'Silver';
      case 'CASH':
      default:
        return 'Cash';
    }
  }

  String get accumulatedLabel {
    if (isSilver) return 'Silver Accumulated';
    if (isGold) return 'Gold Accumulated';
    return 'Cash Saved';
  }
}
