class OrderPayment {
  int id;
  int orderId;
  String source; // 'cash', 'upi', 'card', 'credit'
  double amount;
  String createdAt;

  OrderPayment({
    required this.id,
    required this.orderId,
    required this.source,
    required this.amount,
    required this.createdAt,
  });

  // Convert OrderPayment to Map for database insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'source': source,
      'amount': amount,
      'created_at': createdAt,
    };
  }

  // Create OrderPayment from Map (database query result)
  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      source: json['source'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: json['created_at'] as String,
    );
  }

  // Create a copy of OrderPayment with updated fields
  OrderPayment copyWith({
    int? id,
    int? orderId,
    String? source,
    double? amount,
    String? createdAt,
  }) {
    return OrderPayment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'OrderPayment{id: $id, orderId: $orderId, source: $source, amount: $amount, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderPayment &&
        other.id == id &&
        other.orderId == orderId &&
        other.source == source &&
        other.amount == amount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        orderId.hashCode ^
        source.hashCode ^
        amount.hashCode ^
        createdAt.hashCode;
  }
}
