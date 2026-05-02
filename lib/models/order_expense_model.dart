class OrderExpense {
  int? id;
  String expenseName;
  double expenseAmount;
  String? expenseNote;
  int? orderId;
  String createdAt;
  String updatedAt;

  OrderExpense({
    this.id,
    required this.expenseName,
    required this.expenseAmount,
    this.expenseNote,
    this.orderId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderExpense.fromMap(Map<String, dynamic> map) {
    return OrderExpense(
      id: map['id']?.toInt(),
      expenseName: map['expense_name'] ?? '',
      expenseAmount: (map['expense_amount'] ?? 0.0).toDouble(),
      expenseNote: map['expense_note'],
      orderId: map['order_id']?.toInt(),
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_name': expenseName,
      'expense_amount': expenseAmount,
      'expense_note': expenseNote,
      'order_id': orderId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  OrderExpense copyWith({
    int? id,
    String? expenseName,
    double? expenseAmount,
    String? expenseNote,
    int? orderId,
    String? createdAt,
    String? updatedAt,
  }) {
    return OrderExpense(
      id: id ?? this.id,
      expenseName: expenseName ?? this.expenseName,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      expenseNote: expenseNote ?? this.expenseNote,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'OrderExpense(id: $id, expenseName: $expenseName, expenseAmount: $expenseAmount, expenseNote: $expenseNote, orderId: $orderId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OrderExpense &&
      other.id == id &&
      other.expenseName == expenseName &&
      other.expenseAmount == expenseAmount &&
      other.expenseNote == expenseNote &&
      other.orderId == orderId &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      expenseName.hashCode ^
      expenseAmount.hashCode ^
      expenseNote.hashCode ^
      orderId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
}
