import 'package:mandiapp/models/product_model.dart';
import 'package:mandiapp/models/product_variant_model.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/db_helper.dart';
import 'package:mandiapp/utils/signup_sync.dart';

class ProductDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertProduct(Product product) async {
    product.id = DBHelper.generateUuidInt();
    product.mandiId = await AppHelper.getCurrentMandiId();
    product.updatedAt = DateTime.now().millisecondsSinceEpoch;
    product.isDeleted = 0;
    product.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert('products', product.toJson());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products', where: 'is_deleted = ?', whereArgs: [0]);
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<Product?> getProductById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
    );
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    product.updatedAt = DateTime.now().millisecondsSinceEpoch;
    product.isDeleted = 0;
    product.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      'products',
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> updateDefaultVariant(int productId, int? variantId) async {
    final db = await dbHelper.database;
    return await db.update(
      'products',
      {
        'default_variant': variantId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> restoreProduct(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'products',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'products',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Bulk upsert products
  Future<void> bulkUpsertProducts(List<Product> products) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final product in products) {
        batch.rawInsert('''
          INSERT INTO products (
            id, mandi_id, default_variant, updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            mandi_id = excluded.mandi_id,
            default_variant = excluded.default_variant,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > products.updated_at;
        ''', [
          product.id,
          product.mandiId,
          product.defaultVariant,
          product.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          product.isDeleted ?? 0,
          product.syncStatus ?? 1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> productsSync() async {
    final db = await dbHelper.database;
    final mandiId = await AppHelper.getCurrentMandiId();

    final existing = await db.query(
      'products',
      where: 'mandi_id = ? AND is_deleted = ?',
      whereArgs: [mandiId, 0],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final commonProductIds = <int>[];

    for (final veg in SignupSync.vegetables) {
      final productId = DBHelper.generateUuidInt();
      await db.insert('products', {
        'id': productId,
        'mandi_id': mandiId,
        'default_variant': 0,
        'updated_at': now,
        'is_deleted': 0,
        'sync_status': 0,
      });

      final variantId = DBHelper.generateUuidInt();
      await db.insert('product_variants', {
        'id': variantId,
        'mandi_id': mandiId,
        'product_id': productId,
        'variant_name': veg['name'],
        'selling_price': double.tryParse(veg['price'] ?? '0.0') ?? 0.0,
        'quantity': 1.0,
        'unit': veg['unit'] ?? 'Kilogram',
        'image_path': veg['path'],
        'updated_at': now,
        'is_deleted': 0,
        'sync_status': 0,
      });

      await db.update(
        'products',
        {'default_variant': variantId},
        where: 'id = ?',
        whereArgs: [productId],
      );

      if ((veg['common'] ?? 0) == 1) {
        commonProductIds.add(productId);
      }
    }

    if (commonProductIds.isNotEmpty) {
      final customers = await db.query(
        'customers',
        where: 'mandi_id = ? AND is_deleted = ?',
        whereArgs: [mandiId, 0],
      );

      for (final customer in customers) {
        final existingIds = (customer['product_ids'] as String?) ?? '';
        final currentIds = existingIds.isEmpty
            ? <int>[]
            : existingIds.split(',').map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();
        final merged = {...currentIds, ...commonProductIds}.toList();
        await db.update(
          'customers',
          {'product_ids': merged.join(',')},
          where: 'id = ?',
          whereArgs: [customer['id']],
        );
      }
    }
  }

  Future<List<Product>> getAllProductsWithVariants() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> productMaps = await db.query('products', where: 'is_deleted = ?', whereArgs: [0]);

    List<Product> products = [];
    for (var productMap in productMaps) {
      final productId = productMap['id'] as int?;
      List<ProductVariant>? variants;
      
      if (productId != null) {
        final List<Map<String, dynamic>> variantMaps = await db.query(
          'product_variants',
          where: 'product_id = ? AND is_deleted = ?',
          whereArgs: [productId, 0],
        );
        if (variantMaps.isNotEmpty) {
          variants = variantMaps.map((map) => ProductVariant.fromJson(map)).toList();
          variants.sort((a, b) => a.variantName.compareTo(b.variantName));
        }
      }

      products.add(Product.fromJson(productMap, variants: variants));
    }

    products.sort((a, b) {
      final aName = a.defaultVariantModel?.variantName.toLowerCase() ?? '';
      final bName = b.defaultVariantModel?.variantName.toLowerCase() ?? '';
      return aName.compareTo(bName);
    });
    return products;
  }

  }
