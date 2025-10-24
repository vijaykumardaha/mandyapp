class CartPayment {
  int id;
  int cartId;
  double itemTotal;
  double chargesTotal;
  double receiveAmount;
  double pendingAmount;
  double pendingPayment;
  double paymentAmount;
  bool cashPayment; // 1 = yes, 0 = no
  bool upiPayment; // 1 = yes, 0 = no
  bool cardPayment; // 1 = yes, 0 = no
  bool creditPayment; // 1 = yes, 0 = no
  double cashAmount;
  double upiAmount;
  double cardAmount;
  String createdAt;
  String updatedAt;

  CartPayment({
    required this.id,
    required this.cartId,
    required this.itemTotal,
    required this.chargesTotal,
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

  // Convert CartPayment to Map for database insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'item_total': itemTotal,
      'charges_total': chargesTotal,
      'receive_amount': receiveAmount,
      'pending_amount': pendingAmount,
      'pending_payment': pendingPayment,
      'payment_amount': paymentAmount,
      'cash_payment': cashPayment ? 1 : 0,
      'upi_payment': upiPayment ? 1 : 0,
      'card_payment': cardPayment ? 1 : 0,
      'credit_payment': creditPayment ? 1 : 0,
      'cash_amount': cashAmount,
      'upi_amount': upiAmount,
      'card_amount': cardAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create CartPayment from Map (database query result)
  factory CartPayment.fromJson(Map<String, dynamic> json) {
    return CartPayment(
      id: json['id'] as int,
      cartId: json['cart_id'] as int,
      itemTotal: (json['item_total'] as num).toDouble(),
      chargesTotal: (json['charges_total'] as num).toDouble(),
      receiveAmount: (json['receive_amount'] as num).toDouble(),
      pendingAmount: (json['pending_amount'] as num).toDouble(),
      pendingPayment: (json['pending_payment'] as num?)?.toDouble() ?? 0.0,
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      cashPayment: (json['cash_payment'] as int) == 1,
      upiPayment: (json['upi_payment'] as int) == 1,
      cardPayment: (json['card_payment'] as int) == 1,
      creditPayment: (json['credit_payment'] as int) == 1,
      cashAmount: (json['cash_amount'] as num).toDouble(),
      upiAmount: (json['upi_amount'] as num).toDouble(),
      cardAmount: (json['card_amount'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  // Create a copy of CartPayment with updated fields
  CartPayment copyWith({
    int? id,
    int? cartId,
    double? itemTotal,
    double? chargesTotal,
    double? receiveAmount,
    double? pendingAmount,
    double? pendingPayment,
    double? paymentAmount,
    bool? cashPayment,
    bool? upiPayment,
    bool? cardPayment,
    bool? creditPayment,
    double? cashAmount,
    double? upiAmount,
    double? cardAmount,
    String? createdAt,
    String? updatedAt,
  }) {
    return CartPayment(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      itemTotal: itemTotal ?? this.itemTotal,
      chargesTotal: chargesTotal ?? this.chargesTotal,
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
  double get totalAmount => itemTotal + chargesTotal;

  // Helper method to get total pending (pendingAmount + pendingPayment)
  double get totalPending => pendingAmount + pendingPayment;

  // Helper method to check if payment is fully settled
  bool get isFullyPaid => totalPending <= 0;

  @override
  String toString() {
    return 'CartPayment{id: $id, cartId: $cartId, itemTotal: $itemTotal, chargesTotal: $chargesTotal, receiveAmount: $receiveAmount, pendingAmount: $pendingAmount, pendingPayment: $pendingPayment, totalPaid: $totalPaid}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartPayment &&
        other.id == id &&
        other.cartId == cartId &&
        other.itemTotal == itemTotal &&
        other.chargesTotal == chargesTotal &&
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
        cartId.hashCode ^
        itemTotal.hashCode ^
        chargesTotal.hashCode ^
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
