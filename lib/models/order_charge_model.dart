class OrderCharge {
  int? id;
  String orderId;
  String chargeName;
  double chargeAmount;

  OrderCharge({
    this.id,
    required this.orderId,
    required this.chargeName,
    required this.chargeAmount,
  });

  // Create a copy of this OrderCharge with the provided fields replaced
  OrderCharge copyWith({
    int? id,
    String? orderId,
    String? chargeName,
    double? chargeAmount,
  }) {
    return OrderCharge(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      chargeName: chargeName ?? this.chargeName,
      chargeAmount: chargeAmount ?? this.chargeAmount,
    );
  }

  // Convert OrderCharge to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'charge_name': chargeName,
      'charge_amount': chargeAmount,
    };
  }

  // Create OrderCharge from Map (database query result)
  factory OrderCharge.fromMap(Map<String, dynamic> map) {
    return OrderCharge(
      id: map['id'] as int?,
      orderId: map['order_id'] as String,
      chargeName: map['charge_name'] as String,
      chargeAmount: map['charge_amount'] as double,
    );
  }

  @override
  String toString() {
    return 'OrderCharge(id: $id, orderId: $orderId, chargeName: $chargeName, chargeAmount: $chargeAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderCharge &&
        other.id == id &&
        other.orderId == orderId &&
        other.chargeName == chargeName &&
        other.chargeAmount == chargeAmount;
  }

  @override
  int get hashCode {
    return Object.hash(id, orderId, chargeName, chargeAmount);
  }
}
