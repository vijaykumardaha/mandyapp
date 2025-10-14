class Charge {
  int? id;
  String chargeName;
  double chargeAmount;
  int isActive;

  Charge({
    this.id,
    required this.chargeName,
    required this.chargeAmount,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'charge_name': chargeName,
      'charge_amount': chargeAmount,
      'is_active': isActive,
    };
  }

  factory Charge.fromJson(Map<String, dynamic> json) {
    return Charge(
      id: json['id'] as int?,
      chargeName: json['charge_name'] as String,
      chargeAmount: json['charge_amount'] as double,
      isActive: json['is_active'] as int,
    );
  }

  bool get isChargeActive => isActive == 1;
}
