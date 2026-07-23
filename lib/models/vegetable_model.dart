class Vegetable {
  int? id;
  int? mandyId;
  String key;
  String name;
  String path;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  Vegetable({
    this.id,
    this.mandyId,
    required this.key,
    required this.name,
    required this.path,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['mandy_id'] = mandyId;
    data['key'] = key;
    data['name'] = name;
    data['path'] = path;
    data['updated_at'] = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
    data['is_deleted'] = isDeleted ?? 0;
    data['sync_status'] = syncStatus ?? 0;
    return data;
  }

  factory Vegetable.fromJson(Map<String, dynamic> json) {
    return Vegetable(
      id: json['id'] as int?,
      mandyId: json['mandy_id'] as int?,
      key: json['key'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      updatedAt: json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: json['is_deleted'] as int? ?? 0,
      syncStatus: json['sync_status'] as int? ?? 0,
    );
  }
}
