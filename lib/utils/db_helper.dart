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
              name TEXT NOT NULL,
              mobile TEXT NOT NULL,
              password TEXT NOT NULL,
              role TEXT NOT NULL DEFAULT 'admin' CHECK(role IN ('admin', 'staff')),
              created_by INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            default_variant INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE product_variants (
            id INTEGER PRIMARY KEY,
            product_id INTEGER NOT NULL,
            variant_name TEXT NOT NULL,
            buying_price REAL NOT NULL,
            selling_price REAL NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            image_path TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY,
            customer_id INTEGER NOT NULL,
            created_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime')),
            order_for TEXT NOT NULL DEFAULT 'buyer' CHECK (order_for IN ('seller','buyer')),
            status TEXT DEFAULT 'open' -- open, completed
          );
        ''');

        await db.execute('''
          CREATE TABLE order_charges (
            id INTEGER PRIMARY KEY,
            order_id TEXT NOT NULL,
            charge_name TEXT NOT NULL,
            charge_amount REAL NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE order_payments (
            id INTEGER PRIMARY KEY,
            order_id INTEGER NOT NULL,
            item_total REAL NOT NULL DEFAULT 0,
            charge_total REAL NOT NULL DEFAULT 0,
            receive_amount REAL NOT NULL DEFAULT 0,
            pending_amount REAL NOT NULL DEFAULT 0,
            pending_payment REAL NOT NULL DEFAULT 0,
            payment_amount REAL NOT NULL DEFAULT 0,
            cash_payment INTEGER NOT NULL DEFAULT 0,   -- 1 = yes, 0 = no
            upi_payment INTEGER NOT NULL DEFAULT 0,    -- 1 = yes, 0 = no
            card_payment INTEGER NOT NULL DEFAULT 0,   -- 1 = yes, 0 = no
            credit_payment INTEGER NOT NULL DEFAULT 0, -- 1 = yes, 0 = no
            cash_amount REAL NOT NULL DEFAULT 0,
            upi_amount REAL NOT NULL DEFAULT 0,
            card_amount REAL NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime')),
            updated_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime'))
          );
        ''');

        await db.execute('''
          CREATE TABLE charge_types (
            id INTEGER PRIMARY KEY,
            charge_name TEXT NOT NULL UNIQUE,
            charge_type TEXT NOT NULL DEFAULT 'fixed', -- fixed, percentage
            charge_amount REAL NOT NULL,
            charge_for TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,   -- 1 = active, 0 = disabled
            created_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime')),
            updated_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime'))
          )
        ''');

        await db.execute('''
          CREATE TABLE order_expenses (
            id INTEGER PRIMARY KEY,
            expense_name TEXT NOT NULL,
            expense_amount REAL NOT NULL,
            expense_note TEXT,
            order_id INTEGER,
            created_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime')),
            updated_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime'))
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            initial_credit REAL NOT NULL DEFAULT 0,
            borrow_amount REAL NOT NULL DEFAULT 0,
            advanced_amount REAL NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime'))
          );
        ''');

        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY,
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
            created_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime')),
            updated_at TEXT NOT NULL DEFAULT (DATETIME('now', 'localtime'))
          )
        ''');
        
      }
    );
  }
}
