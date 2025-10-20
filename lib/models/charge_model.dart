class Charge {
  int? id;
  String chargeName;
  String chargeType;
  double chargeAmount;
  int isActive;

  Charge({
    this.id,
    required this.chargeName,
    this.chargeType = 'fixed',
    required this.chargeAmount,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'charge_name': chargeName,
      'charge_type': chargeType,
      'charge_amount': chargeAmount,
      'is_active': isActive,
    };
  }

  factory Charge.fromJson(Map<String, dynamic> json) {
    return Charge(
      id: json['id'] as int?,
      chargeName: json['charge_name'] as String,
      chargeType: (json['charge_type'] as String?) ?? 'fixed',
      chargeAmount: (json['charge_amount'] as num).toDouble(),
      isActive: json['is_active'] as int,
    );
  }

  bool get isChargeActive => isActive == 1;
}
