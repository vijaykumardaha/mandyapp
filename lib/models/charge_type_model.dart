class ChargeType {
  int? id;
  int? mandyId;
  String chargeName;
  String chargeType;
  double chargeAmount;
  String chargeFor;
  int isDefault;
  int isActive;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  ChargeType({
    this.id,
    this.mandyId,
    required this.chargeName,
    this.chargeType = 'fixed',
    required this.chargeAmount,
    required this.chargeFor,
    this.isDefault = 0,
    this.isActive = 1,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandy_id': mandyId,
      'charge_name': chargeName,
      'charge_type': chargeType,
      'charge_amount': chargeAmount,
      'charge_for': chargeFor,
      'is_default': isDefault,
      'is_active': isActive,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
    };
  }

  factory ChargeType.fromJson(Map<String, dynamic> json) {
    return ChargeType(
      id: json['id'] as int?,
      mandyId: json['mandy_id'] as int?,
      chargeName: json['charge_name'] as String,
      chargeType: (json['charge_type'] as String?) ?? 'fixed',
      chargeAmount: (json['charge_amount'] as num).toDouble(),
      chargeFor: json['charge_for'] as String,
      isDefault: json['is_default'] as int? ?? 0,
      isActive: json['is_active'] as int? ?? 1,
      updatedAt: json['updated_at'] as int?,
      isDeleted: json['is_deleted'] as int? ?? 0,
      syncStatus: json['sync_status'] as int? ?? 0,
    );
  }

  bool get isChargeActive => isActive == 1;
}
