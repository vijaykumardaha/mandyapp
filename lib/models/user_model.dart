class User {
  int? id;
  String? name;
  String? mobile;
  String? password;

  User(
      {this.id,
      this.name,
      this.mobile,
      this.password});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    mobile = json['mobile'];
    password = json['password'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['mobile'] = mobile;
    data['password'] = password;
    return data;
  }
}
