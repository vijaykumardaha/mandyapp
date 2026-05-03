class OrderCharge {
  int? id;
  int? mandyId;
  String orderId;
  String chargeName;
  double chargeAmount;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  OrderCharge({
    this.id,
    this.mandyId,
    required this.orderId,
    required this.chargeName,
    required this.chargeAmount,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  // Create a copy of this OrderCharge with the provided fields replaced
  OrderCharge copyWith({
    int? id,
    int? mandyId,
    String? orderId,
    String? chargeName,
    double? chargeAmount,
    int? updatedAt,
    int? isDeleted,
    int? syncStatus,
  }) {
    return OrderCharge(
      id: id ?? this.id,
      mandyId: mandyId ?? this.mandyId,
      orderId: orderId ?? this.orderId,
      chargeName: chargeName ?? this.chargeName,
      chargeAmount: chargeAmount ?? this.chargeAmount,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Convert OrderCharge to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mandy_id': mandyId,
      'order_id': orderId,
      'charge_name': chargeName,
      'charge_amount': chargeAmount,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
    };
  }

  // Create OrderCharge from Map (database query result)
  factory OrderCharge.fromMap(Map<String, dynamic> map) {
    return OrderCharge(
      id: map['id'] as int?,
      mandyId: map['mandy_id'] as int?,
      orderId: map['order_id'] as String,
      chargeName: map['charge_name'] as String,
      chargeAmount: map['charge_amount'] as double,
      updatedAt: map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: map['is_deleted'] as int? ?? 0,
      syncStatus: map['sync_status'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'OrderCharge(id: $id, mandyId: $mandyId, orderId: $orderId, chargeName: $chargeName, chargeAmount: $chargeAmount, updatedAt: $updatedAt, isDeleted: $isDeleted, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderCharge &&
        other.id == id &&
        other.mandyId == mandyId &&
        other.orderId == orderId &&
        other.chargeName == chargeName &&
        other.chargeAmount == chargeAmount;
  }

  @override
  int get hashCode {
    return Object.hash(id, mandyId, orderId, chargeName, chargeAmount);
  }
}
