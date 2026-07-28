class Vegetable {
  int? id;
  int? mandiId;
  String key;
  String name;
  String path;
  double price;
  String unit;
  int common;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  Vegetable({
    this.id,
    this.mandiId,
    required this.key,
    required this.name,
    required this.path,
    this.price = 0.0,
    this.unit = 'Kilogram',
    this.common = 0,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['mandi_id'] = mandiId;
    data['key'] = key;
    data['name'] = name;
    data['path'] = path;
    data['price'] = price;
    data['unit'] = unit;
    data['common'] = common;
    data['updated_at'] = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
    data['is_deleted'] = isDeleted ?? 0;
    data['sync_status'] = syncStatus ?? 0;
    return data;
  }

  factory Vegetable.fromJson(Map<String, dynamic> json) {
    return Vegetable(
      id: json['id'] as int?,
      mandiId: json['mandi_id'] as int?,
      key: json['key'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'Kilogram',
      common: json['common'] as int? ?? 0,
      updatedAt: json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: json['is_deleted'] as int? ?? 0,
      syncStatus: json['sync_status'] as int? ?? 0,
    );
  }
}
