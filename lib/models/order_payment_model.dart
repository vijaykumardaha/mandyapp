class OrderPayment {
  int id;
  int orderId;
  double itemTotal;
  double chargeTotal;
  double receiveAmount;
  double pendingAmount;
  double pendingPayment;
  double paymentAmount;
  int cashPayment; // 1 = yes, 0 = no
  int upiPayment; // 1 = yes, 0 = no
  int cardPayment; // 1 = yes, 0 = no
  int creditPayment; // 1 = yes, 0 = no
  double cashAmount;
  double upiAmount;
  double cardAmount;
  String createdAt;
  String updatedAt;

  OrderPayment({
    required this.id,
    required this.orderId,
    required this.itemTotal,
    required this.chargeTotal,
    required this.receiveAmount,
    required this.pendingAmount,
    required this.pendingPayment,
    required this.paymentAmount,
    required this.cashPayment,
    required this.upiPayment,
    required this.cardPayment,
    required this.creditPayment,
    required this.cashAmount,
    required this.upiAmount,
    required this.cardAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert OrderPayment to Map for database insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'item_total': itemTotal,
      'charge_total': chargeTotal,
      'receive_amount': receiveAmount,
      'pending_amount': pendingAmount,
      'pending_payment': pendingPayment,
      'payment_amount': paymentAmount,
      'cash_payment': cashPayment,
      'upi_payment': upiPayment,
      'card_payment': cardPayment,
      'credit_payment': creditPayment,
      'cash_amount': cashAmount,
      'upi_amount': upiAmount,
      'card_amount': cardAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create OrderPayment from Map (database query result)
  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      itemTotal: (json['item_total'] as num).toDouble(),
      chargeTotal: (json['charge_total'] as num).toDouble(),
      receiveAmount: (json['receive_amount'] as num).toDouble(),
      pendingAmount: (json['pending_amount'] as num).toDouble(),
      pendingPayment: (json['pending_payment'] as num?)?.toDouble() ?? 0.0,
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      cashPayment: json['cash_payment'] as int,
      upiPayment: json['upi_payment'] as int,
      cardPayment: json['card_payment'] as int,
      creditPayment: json['credit_payment'] as int,
      cashAmount: (json['cash_amount'] as num).toDouble(),
      upiAmount: (json['upi_amount'] as num).toDouble(),
      cardAmount: (json['card_amount'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  // Create a copy of OrderPayment with updated fields
  OrderPayment copyWith({
    int? id,
    int? orderId,
    double? itemTotal,
    double? chargeTotal,
    double? receiveAmount,
    double? pendingAmount,
    double? pendingPayment,
    double? paymentAmount,
    int? cashPayment,
    int? upiPayment,
    int? cardPayment,
    int? creditPayment,
    double? cashAmount,
    double? upiAmount,
    double? cardAmount,
    String? createdAt,
    String? updatedAt,
  }) {
    return OrderPayment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemTotal: itemTotal ?? this.itemTotal,
      chargeTotal: chargeTotal ?? this.chargeTotal,
      receiveAmount: receiveAmount ?? this.receiveAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      pendingPayment: pendingPayment ?? this.pendingPayment,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      cashPayment: cashPayment ?? this.cashPayment,
      upiPayment: upiPayment ?? this.upiPayment,
      cardPayment: cardPayment ?? this.cardPayment,
      creditPayment: creditPayment ?? this.creditPayment,
      cashAmount: cashAmount ?? this.cashAmount,
      upiAmount: upiAmount ?? this.upiAmount,
      cardAmount: cardAmount ?? this.cardAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get total paid amount
  double get totalPaid => cashAmount + upiAmount + cardAmount;

  // Helper method to get total amount (item + charges)
  double get totalAmount => itemTotal + chargeTotal;

  // Helper method to get total pending (pendingAmount + pendingPayment)
  double get totalPending => pendingAmount + pendingPayment;

  // Helper method to check if payment is fully settled
  bool get isFullyPaid => totalPending <= 0;

  @override
  String toString() {
    return 'OrderPayment{id: $id, orderId: $orderId, itemTotal: $itemTotal, chargeTotal: $chargeTotal, receiveAmount: $receiveAmount, pendingAmount: $pendingAmount, pendingPayment: $pendingPayment, totalPaid: $totalPaid}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderPayment &&
        other.id == id &&
        other.orderId == orderId &&
        other.itemTotal == itemTotal &&
        other.chargeTotal == chargeTotal &&
        other.receiveAmount == receiveAmount &&
        other.pendingAmount == pendingAmount &&
        other.pendingPayment == pendingPayment &&
        other.paymentAmount == paymentAmount &&
        other.cashPayment == cashPayment &&
        other.upiPayment == upiPayment &&
        other.cardPayment == cardPayment &&
        other.creditPayment == creditPayment &&
        other.cashAmount == cashAmount &&
        other.upiAmount == upiAmount &&
        other.cardAmount == cardAmount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        orderId.hashCode ^
        itemTotal.hashCode ^
        chargeTotal.hashCode ^
        receiveAmount.hashCode ^
        pendingAmount.hashCode ^
        pendingPayment.hashCode ^
        paymentAmount.hashCode ^
        cashPayment.hashCode ^
        upiPayment.hashCode ^
        cardPayment.hashCode ^
        creditPayment.hashCode ^
        cashAmount.hashCode ^
        upiAmount.hashCode ^
        cardAmount.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
