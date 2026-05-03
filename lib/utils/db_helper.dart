import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DBHelper {
  DBHelper._(); // Private constructor to prevent instantiation

  static final DBHelper instance = DBHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // If the database does not exist, create it
    _database = await initDB();
    return _database!;
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
    final String path = join(await getDatabasesPath(), 'mandyapp.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY,
              mandy_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              mobile TEXT NOT NULL,
              password TEXT NOT NULL,
              role TEXT NOT NULL DEFAULT 'admin' CHECK(role IN ('admin', 'staff')),
              updated_at INTEGER NOT NULL,
              is_deleted INTEGER DEFAULT 0,
              sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            mandy_id INTEGER NOT NULL,
            default_variant INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE product_variants (
            id INTEGER PRIMARY KEY,
            mandy_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            variant_name TEXT NOT NULL,
            buying_price REAL NOT NULL,
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
            mandy_id INTEGER NOT NULL,
            customer_id INTEGER NOT NULL,
            created_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime')),
            order_for TEXT NOT NULL DEFAULT 'buyer' CHECK (order_for IN ('seller','buyer')),
            status TEXT DEFAULT 'open', -- open, completed
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE order_charges (
            id INTEGER PRIMARY KEY,
            mandy_id INTEGER NOT NULL,
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
            mandy_id INTEGER NOT NULL,
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
            mandy_id INTEGER NOT NULL,
            charge_name TEXT NOT NULL UNIQUE,
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
            mandy_id INTEGER NOT NULL,
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
            mandy_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            initial_credit REAL NOT NULL DEFAULT 0,
            borrow_amount REAL NOT NULL DEFAULT 0,
            advanced_amount REAL NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY,
            mandy_id INTEGER NOT NULL,
            seller_id INTEGER NOT NULL,
            buyer_order_id INTEGER,
            seller_order_id INTEGER,
            buyer_id INTEGER,
            product_id INTEGER NOT NULL,
            variant_id INTEGER NOT NULL,
            buying_price REAL DEFAULT 0.0,
            selling_price REAL NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT DEFAULT 'Kg',
            updated_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');
        
      }
    );
  }
}
