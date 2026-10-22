class SchemeModel {
  final String id;
  final String name;
  final int monthlyAmount;
  final int durationMonths;
  final int maturityAmount;

  // Kept for backward compatibility with older API responses.
  final bool isWeightBased;

  // CASH | GOLD_22K | GOLD_18K | SILVER
  final String rateType;

  const SchemeModel({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.durationMonths,
    required this.maturityAmount,
    required this.isWeightBased,
    required this.rateType,
  });

  bool get isCash => rateType == 'CASH';
  bool get isGold22K => rateType == 'GOLD_22K';
  bool get isGold18K => rateType == 'GOLD_18K';
  bool get isSilver => rateType == 'SILVER';
  bool get isGold => isGold22K || isGold18K;
  bool get isMetal => !isCash;

  String get typeLabel {
    switch (rateType) {
      case 'GOLD_22K':
        return '22K Gold Weight Scheme';
      case 'GOLD_18K':
        return '18K Gold Weight Scheme';
      case 'SILVER':
        return 'Silver Weight Scheme';
      case 'CASH':
      default:
        return 'Cash Value Scheme';
    }
  }

  String get typeDescription {
    switch (rateType) {
      case 'GOLD_22K':
        return 'Your selected amount is converted into gold using the live 22K gold rate for every paid installment.';
      case 'GOLD_18K':
        return 'Your selected amount is converted into gold using the live 18K gold rate for every paid installment.';
      case 'SILVER':
        return 'Your selected amount is converted into silver grams using the live silver rate for every paid installment.';
      case 'CASH':
      default:
        return 'Your selected monthly amount remains fixed for the complete scheme.';
    }
  }

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    final rawRateType = json['rateType']?.toString().trim().toUpperCase();
    final legacyWeightBased = json['isWeightBased'] == true;

    final resolvedRateType =
        (rawRateType == null || rawRateType.isEmpty)
            ? (legacyWeightBased ? 'GOLD_22K' : 'CASH')
            : rawRateType;

    return SchemeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Scheme',
      monthlyAmount:
          int.tryParse(json['monthlyAmount']?.toString() ?? '0') ?? 0,
      durationMonths:
          int.tryParse(json['durationMonths']?.toString() ?? '0') ?? 0,
      maturityAmount:
          int.tryParse(
            (json['maturityAmount'] ?? json['maturityMonths'] ?? 0).toString(),
          ) ??
          0,
      isWeightBased: legacyWeightBased || resolvedRateType != 'CASH',
      rateType: resolvedRateType,
    );
  }
}
