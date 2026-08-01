import 'dart:math';

import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/utils/synced_database.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DBHelper {
  DBHelper._(); // Private constructor to prevent instantiation

  static final DBHelper instance = DBHelper._();

  static SyncedDatabase? _syncedDb;

  Future<SyncedDatabase> get database async {
    if (_syncedDb != null) return _syncedDb!;

    final db = await initDB();
    _syncedDb = SyncedDatabase(db);
    return _syncedDb!;
  }

  Future<void> clearAllTables() async {
    final db = await database;
    final tables = [...DbTables.synced, DbTables.vegetables];
    for (final table in tables) {
      await db.delete(table);
    }
  }

  static int generateUuidInt() {
    final uuid = const Uuid().v4();
    final hash = uuid.hashCode.abs();

    // Convert to 8-digit number
    final random = Random(hash);
    final id = 10000000 + random.nextInt(90000000); // ensures 8 digits
    return id;
  }

  Future<Database> initDB() async {
    final String path = join(await getDatabasesPath(), 'mandiapp.db');

    return await openDatabase(
      path,
      version: 11,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY,
              mandi_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              mobile TEXT NOT NULL,
              password TEXT NOT NULL,
              role TEXT NOT NULL DEFAULT 'admin' CHECK(role IN ('admin', 'staff', 'customer')),
              is_active INTEGER NOT NULL DEFAULT 1,
              updated_at INTEGER NOT NULL,
              is_deleted INTEGER DEFAULT 0,
              sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            default_variant INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE product_variants (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            variant_name TEXT NOT NULL,
            selling_price REAL NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            image_path TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            customer_id INTEGER NOT NULL,
            order_for TEXT NOT NULL DEFAULT 'buyer' CHECK (order_for IN ('seller','buyer')),
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE order_charges (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            order_id TEXT NOT NULL,
            charge_name TEXT NOT NULL,
            charge_amount REAL NOT NULL,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE order_payments (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            order_id INTEGER NOT NULL,
            source TEXT NOT NULL, -- 'cash', 'upi', 'card', 'credit'
            amount REAL NOT NULL,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE charge_types (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            charge_name TEXT NOT NULL,
            charge_type TEXT NOT NULL DEFAULT 'fixed', -- fixed, percentage
            charge_amount REAL NOT NULL,
            charge_for TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,   -- 1 = active, 0 = disabled
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE order_expenses (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            expense_name TEXT NOT NULL,
            expense_amount REAL NOT NULL,
            expense_note TEXT,
            order_id INTEGER,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            product_ids TEXT DEFAULT '',

            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            seller_id INTEGER NOT NULL,
            buyer_order_id INTEGER,
            seller_order_id INTEGER,
            buyer_id INTEGER,
            product_id INTEGER NOT NULL,
            variant_id INTEGER NOT NULL,
            selling_price REAL NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT DEFAULT 'Kilogram',
            product_name TEXT,
            image_path TEXT,
            seller_name TEXT,
            buyer_name TEXT,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE customer_payments (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            customer_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('paid', 'received')),
            source TEXT NOT NULL DEFAULT 'cash',
            note TEXT,
            payment_date INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE vegetables (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            key TEXT NOT NULL,
            name TEXT NOT NULL,
            path TEXT NOT NULL,
            price REAL DEFAULT 0.0,
            unit TEXT DEFAULT 'Kilogram',
            common INTEGER DEFAULT 0,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE stocks (
            id INTEGER PRIMARY KEY,
            mandi_id INTEGER NOT NULL,
            seller_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            product_variant_id INTEGER,
            initial_quantity REAL NOT NULL,
            quantity REAL NOT NULL,
            sold_quantity REAL NOT NULL DEFAULT 0,
            loss_quantity REAL NOT NULL DEFAULT 0,
            purchase_amount REAL NOT NULL,
            sold_amount REAL NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            sync_status INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE stock_transactions (
            id INTEGER PRIMARY KEY,
            stock_id INTEGER NOT NULL,
            mandi_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            product_variant_id INTEGER,
            buyer_id INTEGER NOT NULL,
            bill_id INTEGER,
            buy_quantity REAL NOT NULL,
            total_amount REAL NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }
}
