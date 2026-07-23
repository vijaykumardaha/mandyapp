class Customer {
  int? id;
  int? mandyId;
  String? name;
  String? phone;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  Customer({
    this.id,
    this.mandyId,
    this.name,
    this.phone,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  Customer.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        mandyId = json['mandy_id'] as int?,
        name = json['name'],
        phone = json['phone'],
        updatedAt = json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        isDeleted = json['is_deleted'] as int? ?? 0,
        syncStatus = json['sync_status'] as int? ?? 0;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['mandy_id'] = mandyId;
    data['name'] = name;
    data['phone'] = phone;
    data['updated_at'] = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
    data['is_deleted'] = isDeleted ?? 0;
    data['sync_status'] = syncStatus ?? 0;
    return data;
  }

  Customer copyWith({
    int? id,
    int? mandyId,
    String? name,
    String? phone,
    int? updatedAt,
    int? isDeleted,
    int? syncStatus,
  }) {
    return Customer(
      id: id ?? this.id,
      mandyId: mandyId ?? this.mandyId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
