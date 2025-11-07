class Charge {
  int? id;
  String chargeName;
  String chargeType;
  double chargeAmount;
  String chargeFor;
  int isDefault;
  int isActive;

  Charge({
    this.id,
    required this.chargeName,
    this.chargeType = 'fixed',
    required this.chargeAmount,
    required this.chargeFor,
    this.isDefault = 0,
    this.isActive = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'charge_name': chargeName,
      'charge_type': chargeType,
      'charge_amount': chargeAmount,
      'charge_for': chargeFor,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }

  factory Charge.fromJson(Map<String, dynamic> json) {
    return Charge(
      id: json['id'] as int?,
      chargeName: json['charge_name'] as String,
      chargeType: (json['charge_type'] as String?) ?? 'fixed',
      chargeAmount: (json['charge_amount'] as num).toDouble(),
      chargeFor: json['charge_for'] as String,
      isDefault: json['is_default'] as int? ?? 0,
      isActive: json['is_active'] as int? ?? 1,
    );
  }

  bool get isChargeActive => isActive == 1;
}
