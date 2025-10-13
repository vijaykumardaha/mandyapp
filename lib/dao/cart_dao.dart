import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/cart_item_model.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class CartDAO {
  final dbHelper = DBHelper.instance;

  // Insert a new cart
  Future<int> insertCart(Cart cart) async {
    final db = await dbHelper.database;
    return await db.insert('carts', cart.toJson());
  }

  // Update an existing cart
  Future<int> updateCart(Cart cart) async {
    final db = await dbHelper.database;
    return await db.update(
      'carts',
      cart.toJson(),
      where: 'id = ?',
      whereArgs: [cart.id],
    );
  }

  // Delete a cart
  Future<int> deleteCart(int id) async {
    final db = await dbHelper.database;
    // Delete all cart items first
    await db.delete('cart_items', where: 'cart_id = ?', whereArgs: [id]);
    // Then delete the cart
    return await db.delete('carts', where: 'id = ?', whereArgs: [id]);
  }

  // Get cart by ID
  Future<Cart?> getCartById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Cart.fromJson(maps.first);
    }
    return null;
  }

  // Get all carts
  Future<List<Cart>> getAllCarts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carts',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Cart.fromJson(maps[i]);
    });
  }

  // Get carts by user ID
  Future<List<Cart>> getCartsByUser(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    // Load items for each cart
    List<Cart> carts = [];
    for (var map in maps) {
      final cart = Cart.fromJson(map);
      final items = await getCartItems(cart.id);
      carts.add(cart.copyWith(id: cart.id, items: items));
    }
    return carts;
  }

  // Get open cart for user
  Future<Cart?> getOpenCartForUser(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carts',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'open'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final cart = Cart.fromJson(maps.first);
      // Load items for this cart
      final items = await getCartItems(cart.id);
      return cart.copyWith(items: items, id: DBHelper.generateUuidInt());
    }
    return null;
  }

  // Get cart with items
  Future<Cart?> getCartWithItems(int cartId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> cartMaps = await db.query(
      'carts',
      where: 'id = ?',
      whereArgs: [cartId],
    );

    if (cartMaps.isNotEmpty) {
      final items = await getCartItems(cartId);
      return Cart.fromJson(cartMaps.first, items: items);
    }
    return null;
  }

  // Update cart status
  Future<int> updateCartStatus(int cartId, String status) async {
    final db = await dbHelper.database;
    return await db.update(
      'carts',
      {'status': status},
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  // === Cart Items Methods ===

  // Insert a cart item
  Future<int> insertCartItem(CartItem item) async {
    final db = await dbHelper.database;
    return await db.insert('cart_items', item.toJson());
  }

  // Update a cart item
  Future<int> updateCartItem(CartItem item) async {
    final db = await dbHelper.database;
    return await db.update(
      'cart_items',
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Delete a cart item
  Future<int> deleteCartItem(int id) async {
    final db = await dbHelper.database;
    return await db.delete('cart_items', where: 'id = ?', whereArgs: [id]);
  }

  // Get cart item by ID
  Future<CartItem?> getCartItem(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CartItem.fromJson(maps.first);
    }
    return null;
  }

  // Get all items for a cart
  Future<List<CartItem>> getCartItems(int cartId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_items',
      where: 'cart_id = ?',
      whereArgs: [cartId],
    );

    return List.generate(maps.length, (i) {
      return CartItem.fromJson(maps[i]);
    });
  }

  // Clear all items from a cart
  Future<int> clearCart(int cartId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'cart_items',
      where: 'cart_id = ?',
      whereArgs: [cartId],
    );
  }

  // Get cart item by product ID (to check if product already in cart)
  Future<CartItem?> getCartItemByProduct(int cartId, int productId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_items',
      where: 'cart_id = ? AND product_id = ? AND variant_id IS NULL',
      whereArgs: [cartId, productId],
    );

    if (maps.isNotEmpty) {
      return CartItem.fromJson(maps.first);
    }
    return null;
  }

  // Get cart item by variant ID (to check if variant already in cart)
  Future<CartItem?> getCartItemByVariant(int cartId, int variantId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_items',
      where: 'cart_id = ? AND variant_id = ?',
      whereArgs: [cartId, variantId],
    );

    if (maps.isNotEmpty) {
      return CartItem.fromJson(maps.first);
    }
    return null;
  }

  // Get total items count in cart
  Future<int> getCartItemCount(int cartId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cart_items WHERE cart_id = ?',
      [cartId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get total price of cart
  Future<double> getCartTotalPrice(int cartId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(total_price) as total FROM cart_items WHERE cart_id = ?',
      [cartId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
