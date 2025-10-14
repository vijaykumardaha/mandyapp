class CartCharge {
  final int? id;
  final String cartId;
  final String chargeName;
  final double chargeAmount;

  const CartCharge({
    this.id,
    required this.cartId,
    required this.chargeName,
    required this.chargeAmount,
  });

  // Create a copy of this CartCharge with the provided fields replaced
  CartCharge copyWith({
    int? id,
    String? cartId,
    String? chargeName,
    double? chargeAmount,
  }) {
    return CartCharge(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      chargeName: chargeName ?? this.chargeName,
      chargeAmount: chargeAmount ?? this.chargeAmount,
    );
  }

  // Convert CartCharge to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'charge_name': chargeName,
      'charge_amount': chargeAmount,
    };
  }

  // Create CartCharge from JSON (database record)
  factory CartCharge.fromJson(Map<String, dynamic> json) {
    return CartCharge(
      id: json['id'] as int?,
      cartId: json['cart_id'] as String,
      chargeName: json['charge_name'] as String,
      chargeAmount: (json['charge_amount'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'CartCharge(id: $id, cartId: $cartId, chargeName: $chargeName, chargeAmount: $chargeAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartCharge &&
        other.id == id &&
        other.cartId == cartId &&
        other.chargeName == chargeName &&
        other.chargeAmount == chargeAmount;
  }

  @override
  int get hashCode {
    return id.hashCode ^ cartId.hashCode ^ chargeName.hashCode ^ chargeAmount.hashCode;
  }
}
