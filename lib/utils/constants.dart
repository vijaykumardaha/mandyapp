// Centralized database + shared-preferences constants.
//
// Use these instead of raw string literals so renames/typos surface as
// compile errors instead of silent runtime failures.

class DbTables {
  DbTables._();

  static const String users = 'users';
  static const String products = 'products';
  static const String productVariants = 'product_variants';
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
  static const String orderPayments = 'order_payments';
  static const String orderCharges = 'order_charges';
  static const String orderExpenses = 'order_expenses';
  static const String chargeTypes = 'charge_types';
  static const String customers = 'customers';
  static const String customerPayments = 'customer_payments';
  static const String vegetables = 'vegetables';
  static const String stocks = 'stocks';
  static const String stockTransactions = 'stock_transactions';
  static const String otherTransactions = 'other_transactions';

  /// Tables that participate in dirty-record sync.
  ///
  /// Note: `vegetables` is bulk-synced by [SyncService] but intentionally
  /// excluded here (it is not written through [SyncedDatabase]).
  static const List<String> synced = [
    users,
    products,
    productVariants,
    orders,
    orderItems,
    orderPayments,
    orderCharges,
    orderExpenses,
    chargeTypes,
    customers,
    customerPayments,
    stocks,
    stockTransactions,
    otherTransactions,
  ];
}

/// Centralized column names for the database tables.
class DbColumns {
  DbColumns._();

  /// Columns shared across tables.
  static const String id = 'id';
  static const String mandiId = 'mandi_id';
  static const String updatedAt = 'updated_at';
  static const String isDeleted = 'is_deleted';
  static const String syncStatus = 'sync_status';

  /// `other_transactions` columns.
  static const String transactionNote = 'transaction_note';
  static const String transactionType = 'transaction_type';
  static const String transactionAmount = 'amount';
}

class PrefsKeys {
  PrefsKeys._();

  static const String user = 'user';
}
