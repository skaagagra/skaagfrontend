class RechargePlan {
  final int id;
  final int operatorId;
  final String operatorName;
  final String amount;
  final String data;
  final String validity;
  final String additionalBenefits;
  final String planType;

  RechargePlan({
    required this.id,
    required this.operatorId,
    required this.operatorName,
    required this.amount,
    required this.data,
    required this.validity,
    required this.additionalBenefits,
    required this.planType,
  });

  factory RechargePlan.fromJson(Map<String, dynamic> json) {
    return RechargePlan(
      id: json['id'],
      operatorId: json['operator'],
      operatorName: json['operator_name'] ?? '',
      amount: json['amount'].toString(),
      data: json['data'] ?? '',
      validity: json['validity'] ?? '',
      additionalBenefits: json['additional_benefits'] ?? '',
      planType: json['plan_type'] ?? 'OTHER',
    );
  }
}
