class OrderPayment {
  int id;
  int? mandiId;
  int orderId;
  String source; // 'cash', 'upi', 'card', 'credit'
  double amount;
  int updatedAt;
  int? isDeleted;
  int? syncStatus;

  OrderPayment({
    required this.id,
    this.mandiId,
    required this.orderId,
    required this.source,
    required this.amount,
    required this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandi_id': mandiId,
      'order_id': orderId,
      'source': source,
      'amount': amount,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
    };
  }

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] as int,
      mandiId: json['mandi_id'] as int?,
      orderId: json['order_id'] as int,
      source: json['source'] as String,
      amount: (json['amount'] as num).toDouble(),
      updatedAt: json['updated_at'] as int,
      isDeleted: json['is_deleted'] as int?,
      syncStatus: json['sync_status'] as int?,
    );
  }

  OrderPayment copyWith({
    int? id,
    int? mandiId,
    int? orderId,
    String? source,
    double? amount,
    int? updatedAt,
    int? isDeleted,
    int? syncStatus,
  }) {
    return OrderPayment(
      id: id ?? this.id,
      mandiId: mandiId ?? this.mandiId,
      orderId: orderId ?? this.orderId,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'OrderPayment{id: $id, mandiId: $mandiId, orderId: $orderId, source: $source, amount: $amount, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderPayment &&
        other.id == id &&
        other.mandiId == mandiId &&
        other.orderId == orderId &&
        other.source == source &&
        other.amount == amount &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        mandiId.hashCode ^
        orderId.hashCode ^
        source.hashCode ^
        amount.hashCode ^
        updatedAt.hashCode;
  }
}
