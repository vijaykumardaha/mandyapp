import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';
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
    final cart = await getCartById(id);
    // Delete all cart-linked item sales first
    await db.delete('item_sales', where: '${cart?.cartFor == 'seller' ? 'seller_cart_id' : 'buyer_cart_id'} = ?', whereArgs: [id]);
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
  Future<List<Cart>> getCartsByCustomer(int customerId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carts',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at ASC',
    );

    // Load items for each cart
    List<Cart> carts = [];
    for (var map in maps) {
      final cart = Cart.fromJson(map);
      final items = await getCartItems(cart.id, cartFor: cart.cartFor);
      carts.add(cart.copyWith(id: cart.id, items: items, cartFor: cart.cartFor));
    }
    return carts;
  }

  // Get open cart for user
  Future<Cart?> getOpenCartForCustomer(int customerId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'carts',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [customerId, 'open'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final cart = Cart.fromJson(maps.first);
      // Load items for this cart
      final items = await getCartItems(cart.id, cartFor: cart.cartFor);
      return cart.copyWith(items: items, id: DBHelper.generateUuidInt(), cartFor: cart.cartFor);
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
      final cart = Cart.fromJson(cartMaps.first);
      final items = await getCartItems(cartId, cartFor: cart.cartFor);
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

  // === Cart ItemSale Methods ===

  // Insert a cart item sale
  Future<int> insertCartItem(ItemSale item) async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final prepared = item.copyWith(
      id: item.id ?? DBHelper.generateUuidInt(),
      createdAt: item.createdAt.isEmpty ? now : item.createdAt,
      updatedAt: now,
    );
    return await db.insert('item_sales', prepared.toJson());
  }

  // Update a cart item sale
  Future<int> updateCartItem(ItemSale item) async {
    final db = await dbHelper.database;
    final updated = item.copyWith(updatedAt: DateTime.now().toIso8601String());
    return await db.update(
      'item_sales',
      updated.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Delete a cart item sale
  Future<int> deleteCartItem(int id) async {
    final db = await dbHelper.database;
    return await db.delete('item_sales', where: 'id = ?', whereArgs: [id]);
  }

  // Get cart item sale by ID
  Future<ItemSale?> getCartItem(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'item_sales',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ItemSale.fromJson(maps.first);
    }
    return null;
  }

  // Get all item sales for a cart
  Future<List<ItemSale>> getCartItems(
    int cartId, {
    String? cartFor,
  }) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'item_sales',
      where: '${cartFor == 'seller' ? 'seller_cart_id' : 'buyer_cart_id'} = ?',
      whereArgs: [cartId],
      orderBy: 'created_at ASC',
    );

    return maps.map(ItemSale.fromJson).toList();
  }

  // Clear all item sales from a cart
  Future<int> clearCart(int cartId) async {
    final db = await dbHelper.database;
    final cart = await getCartById(cartId);
    return await db.delete(
      'item_sales',
      where: '${cart?.cartFor == 'seller' ? 'seller_cart_id' : 'buyer_cart_id'} = ?',
      whereArgs: [cartId],
    );
  }

  // Get cart item sale by product ID (when variant not specified)
  Future<ItemSale?> getCartItemByProduct(int cartId, int productId) async {
    final db = await dbHelper.database;
    final cart = await getCartById(cartId);
    final List<Map<String, dynamic>> maps = await db.query(
      'item_sales',
      where: '${cart?.cartFor == 'seller' ? 'seller_cart_id' : 'buyer_cart_id'} = ? AND product_id = ? AND variant_id IS NULL',
      whereArgs: [cartId, productId],
    );

    if (maps.isNotEmpty) {
      return ItemSale.fromJson(maps.first);
    }
    return null;
  }

  // Get cart item sale by variant ID
  Future<ItemSale?> getCartItemByVariant(int cartId, int variantId) async {
    final db = await dbHelper.database;
    final cart = await getCartById(cartId);
    final List<Map<String, dynamic>> maps = await db.query(
      'item_sales',
      where: '${cart?.cartFor == 'seller' ? 'seller_cart_id' : 'buyer_cart_id'} = ? AND variant_id = ?',
      whereArgs: [cartId, variantId],
    );

    if (maps.isNotEmpty) {
      return ItemSale.fromJson(maps.first);
    }
    return null;
  }

  // Get total items count in cart
  Future<int> getCartItemCount(int cartId) async {
    final db = await dbHelper.database;
    final cart = await getCartById(cartId);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM item_sales WHERE ${cart?.cartFor == 'seller' ? 'seller_cart_id' : 'buyer_cart_id'} = ?',
      [cartId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

}
