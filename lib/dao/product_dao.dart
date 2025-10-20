import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class ProductDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertProduct(Product product) async {
    product.id = DBHelper.generateUuidInt();
    final db = await dbHelper.database;
    return await db.insert('products', product.toJson());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<Product?> getProductById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
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
      {'default_variant': variantId},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getAllProductsWithVariants() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> productMaps = await db.query('products');

    List<Product> products = [];
    for (var productMap in productMaps) {
      final productId = productMap['id'] as int?;
      List<ProductVariant>? variants;
      
      if (productId != null) {
        final List<Map<String, dynamic>> variantMaps = await db.query(
          'product_variants',
          where: 'product_id = ?',
          whereArgs: [productId],
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

  Future<List<Product>> getProductsByCategoryWithVariants(int categoryId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> productMaps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );

    List<Product> products = [];
    for (var productMap in productMaps) {
      final productId = productMap['id'] as int?;
      List<ProductVariant>? variants;
      
      if (productId != null) {
        final List<Map<String, dynamic>> variantMaps = await db.query(
          'product_variants',
          where: 'product_id = ?',
          whereArgs: [productId],
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
