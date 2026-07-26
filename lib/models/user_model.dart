class User {
  int? id;
  int? mandyId;
  String? name;
  String? mobile;
  String? password;
  String? role;
  int? isActive;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  User({
    this.id,
    this.mandyId,
    this.name,
    this.mobile,
    this.password,
    this.role = 'admin',
    this.isActive = 1,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  bool get isEnabled => isActive == 1;
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    mandyId = json['mandy_id'];
    mobile = json['mobile'];
    password = json['password'];
    name = json['name'];
    role = json['role'] ?? 'admin';
    isActive = json['is_active'] ?? 1;
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
    data['is_active'] = isActive ?? 1;
    data['updated_at'] = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
    data['is_deleted'] = isDeleted ?? 0;
    data['sync_status'] = syncStatus ?? 0;
    return data;
  }
}
