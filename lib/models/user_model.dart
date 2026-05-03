class User {
  int? id;
  int? mandyId;
  String? name;
  String? mobile;
  String? password;
  String? role;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  User(
      {this.id,
      this.mandyId,
      this.name,
      this.mobile,
      this.password,
      this.role = 'admin',
      this.updatedAt,
      this.isDeleted = 0,
      this.syncStatus = 0});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    mandyId = json['mandy_id'];
    mobile = json['mobile'];
    password = json['password'];
    name = json['name'];
    role = json['role'] ?? 'admin';
    updatedAt = json['updated_at'] ?? DateTime.now().millisecondsSinceEpoch;
    isDeleted = json['is_deleted'] ?? 0;
    syncStatus = json['sync_status'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['mandy_id'] = mandyId;
    data['name'] = name;
    data['mobile'] = mobile;
    data['password'] = password;
    data['role'] = role;
    data['updated_at'] = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
    data['is_deleted'] = isDeleted ?? 0;
    data['sync_status'] = syncStatus ?? 0;
    return data;
  }
}
