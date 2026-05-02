class User {
  int? id;
  String? name;
  String? mobile;
  String? password;
  String? role;
  int? createdBy;

  User(
      {this.id,
      this.name,
      this.mobile,
      this.password,
      this.role = 'admin',
      this.createdBy});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    mobile = json['mobile'];
    password = json['password'];
    name = json['name'];
    role = json['role'] ?? 'admin';
    createdBy = json['created_by'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['mobile'] = mobile;
    data['password'] = password;
    data['role'] = role;
    data['created_by'] = createdBy;
    return data;
  }
}
