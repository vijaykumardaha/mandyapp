class Customer {
  int? id;
  String? name;
  String? phone;
  double borrowAmount;
  double advancedAmount;

  Customer({
    this.id,
    this.name,
    this.phone,
    this.borrowAmount = 0.0,
    this.advancedAmount = 0.0,
  });

  Customer.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        phone = json['phone'],
        borrowAmount = (json['borrow_amount'] as num?)?.toDouble() ?? 0.0,
        advancedAmount = (json['advanced_amount'] as num?)?.toDouble() ?? 0.0;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['borrow_amount'] = borrowAmount;
    data['advanced_amount'] = advancedAmount;
    return data;
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    double? borrowAmount,
    double? advancedAmount,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      borrowAmount: borrowAmount ?? this.borrowAmount,
      advancedAmount: advancedAmount ?? this.advancedAmount,
    );
  }
}
