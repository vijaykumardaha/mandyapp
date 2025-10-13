import 'package:mandyapp/models/cart_item_model.dart';

class Cart {
  int id;
  int userId;
  String? name;
  String createdAt;
  String status; // 'open', 'completed', 'cancelled'
  List<CartItem>? items;

  Cart({
    required this.id,
    required this.userId,
    this.name,
    required this.createdAt,
    this.status = 'open',
    this.items,
  });

  // Convert Cart to Map for database insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt,
      'status': status,
    };
  }

  // Create Cart from Map (database query result)
  factory Cart.fromJson(Map<String, dynamic> json, {List<CartItem>? items}) {
    return Cart(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String?,
      createdAt: json['created_at'] as String,
      status: json['status'] as String? ?? 'open',
      items: items,
    );
  }

  // Create a copy of Cart with updated fields
  Cart copyWith({
    required int id,
    int? userId,
    String? name,
    String? createdAt,
    String? status,
    List<CartItem>? items,
  }) {
    return Cart(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  // Check if cart is open
  bool get isOpen => status == 'open';

  // Check if cart is completed
  bool get isCompleted => status == 'completed';

  // Check if cart is cancelled
  bool get isCancelled => status == 'cancelled';

  // Get total number of items in cart (total quantity, not number of line items)
  int get itemCount {
    if (items == null || items!.isEmpty) return 0;
    return totalQuantity.toInt();
  }

  // Get number of different line items in cart (for counting distinct products)
  int get lineItemCount => items?.length ?? 0;

  // Get total quantity of all items
  double get totalQuantity {
    if (items == null || items!.isEmpty) return 0.0;
    return items!.fold(0.0, (sum, item) => sum + item.quantity);
  }

  // Get total price of all items
  double get totalPrice {
    if (items == null || items!.isEmpty) return 0.0;
    return items!.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Check if cart is empty
  bool get isEmpty => items == null || items!.isEmpty;

  // Check if cart has items
  bool get hasItems => items != null && items!.isNotEmpty;

  @override
  String toString() {
    return 'Cart{id: $id, userId: $userId, name: $name, createdAt: $createdAt, status: $status, itemCount: $itemCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        status.hashCode;
  }
}
