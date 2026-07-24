class OrderPayment {
  int id;
  int orderId;
  String source; // 'cash', 'upi', 'card', 'credit'
  double amount;
  String updatedAt;

  OrderPayment({
    required this.id,
    required this.orderId,
    required this.source,
    required this.amount,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'source': source,
      'amount': amount,
      'updated_at': updatedAt,
    };
  }

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      source: json['source'] as String,
      amount: (json['amount'] as num).toDouble(),
      updatedAt: json['updated_at'] as String,
    );
  }

  OrderPayment copyWith({
    int? id,
    int? orderId,
    String? source,
    double? amount,
    String? updatedAt,
  }) {
    return OrderPayment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'OrderPayment{id: $id, orderId: $orderId, source: $source, amount: $amount, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderPayment &&
        other.id == id &&
        other.orderId == orderId &&
        other.source == source &&
        other.amount == amount &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        orderId.hashCode ^
        source.hashCode ^
        amount.hashCode ^
        updatedAt.hashCode;
  }
}
