class CustomerPayment {
  int? id;
  int? mandyId;
  int customerId;
  double amount;
  String type; // 'paid' or 'received'
  String source; // 'cash', 'upi', 'card', 'credit'
  String note;
  int paymentDate;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  CustomerPayment({
    this.id,
    this.mandyId,
    required this.customerId,
    required this.amount,
    required this.type,
    this.source = 'cash',
    required this.note,
    required this.paymentDate,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  CustomerPayment.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        mandyId = json['mandy_id'] as int?,
        customerId = json['customer_id'] as int,
        amount = (json['amount'] as num).toDouble(),
        type = json['type'] as String,
        source = json['source'] as String? ?? 'cash',
        note = json['note'] as String? ?? '',
        paymentDate = json['payment_date'] as int,
        updatedAt = json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        isDeleted = json['is_deleted'] as int? ?? 0,
        syncStatus = json['sync_status'] as int? ?? 0;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['mandy_id'] = mandyId;
    data['customer_id'] = customerId;
    data['amount'] = amount;
    data['type'] = type;
    data['source'] = source;
    data['note'] = note;
    data['payment_date'] = paymentDate;
    data['updated_at'] = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
    data['is_deleted'] = isDeleted ?? 0;
    data['sync_status'] = syncStatus ?? 0;
    return data;
  }

  CustomerPayment copyWith({
    int? id,
    int? mandyId,
    int? customerId,
    double? amount,
    String? type,
    String? source,
    String? note,
    int? paymentDate,
    int? updatedAt,
    int? isDeleted,
    int? syncStatus,
  }) {
    return CustomerPayment(
      id: id ?? this.id,
      mandyId: mandyId ?? this.mandyId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      source: source ?? this.source,
      note: note ?? this.note,
      paymentDate: paymentDate ?? this.paymentDate,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
