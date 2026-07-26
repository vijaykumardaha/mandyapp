class OrderExpense {
  int? id;
  int? mandyId;
  String expenseName;
  double expenseAmount;
  String? expenseNote;
  int? orderId;
  int updatedAt;
  int? isDeleted;
  int? syncStatus;

  OrderExpense({
    this.id,
    this.mandyId,
    required this.expenseName,
    required this.expenseAmount,
    this.expenseNote,
    this.orderId,
    required this.updatedAt,
    this.isDeleted,
    this.syncStatus,
  });

  factory OrderExpense.fromMap(Map<String, dynamic> map) {
    return OrderExpense(
      id: map['id']?.toInt(),
      mandyId: map['mandy_id']?.toInt(),
      expenseName: map['expense_name'] ?? '',
      expenseAmount: (map['expense_amount'] ?? 0.0).toDouble(),
      expenseNote: map['expense_note'],
      orderId: map['order_id']?.toInt(),
      updatedAt: map['updated_at'] ?? 0,
      isDeleted: map['is_deleted']?.toInt(),
      syncStatus: map['sync_status']?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mandy_id': mandyId,
      'expense_name': expenseName,
      'expense_amount': expenseAmount,
      'expense_note': expenseNote,
      'order_id': orderId,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
    };
  }

  OrderExpense copyWith({
    int? id,
    int? mandyId,
    String? expenseName,
    double? expenseAmount,
    String? expenseNote,
    int? orderId,
    int? updatedAt,
    int? isDeleted,
    int? syncStatus,
  }) {
    return OrderExpense(
      id: id ?? this.id,
      mandyId: mandyId ?? this.mandyId,
      expenseName: expenseName ?? this.expenseName,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      expenseNote: expenseNote ?? this.expenseNote,
      orderId: orderId ?? this.orderId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'OrderExpense(id: $id, mandyId: $mandyId, expenseName: $expenseName, expenseAmount: $expenseAmount, expenseNote: $expenseNote, orderId: $orderId, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderExpense &&
      other.id == id &&
      other.mandyId == mandyId &&
      other.expenseName == expenseName &&
      other.expenseAmount == expenseAmount &&
      other.expenseNote == expenseNote &&
      other.orderId == orderId &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      mandyId.hashCode ^
      expenseName.hashCode ^
      expenseAmount.hashCode ^
      expenseNote.hashCode ^
      orderId.hashCode ^
      updatedAt.hashCode;
  }
}
