import 'package:mandiapp/utils/constants.dart';
import 'package:mandiapp/utils/db_helper.dart';

class ReportDAO {
  final dbHelper = DBHelper.instance;

  // 1. Daily Sales Report
  Future<List<Map<String, dynamic>>> getDailySalesReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        date(order_items.updated_at / 1000, 'unixepoch', 'localtime') as date,
        order_items.product_id,
        order_items.variant_id,
        pv.variant_name,
        pv.unit,
        SUM(order_items.quantity) as total_quantity,
        COUNT(*) as transaction_count,
        SUM(order_items.quantity * order_items.selling_price) as total_revenue,
        AVG(order_items.selling_price) as avg_price
      FROM order_items
      LEFT JOIN product_variants pv ON order_items.variant_id = pv.id
      WHERE date(order_items.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(order_items.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
      GROUP BY date(order_items.updated_at / 1000, 'unixepoch', 'localtime'), order_items.product_id, order_items.variant_id, pv.variant_name, pv.unit
      ORDER BY date DESC, total_revenue DESC
    ''';

    return db.rawQuery(sql, [
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0]
    ]);
  }

  // 1b. Daily Purchase Report
  Future<List<Map<String, dynamic>>> getDailyPurchaseReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        date(oi.updated_at / 1000, 'unixepoch', 'localtime') as date,
        oi.product_id,
        oi.variant_id,
        pv.variant_name,
        pv.unit,
        SUM(oi.quantity) as total_quantity,
        COUNT(*) as transaction_count,
        SUM(oi.quantity * oi.selling_price) as total_cost,
        AVG(oi.selling_price) as avg_price
      FROM order_items oi
      LEFT JOIN product_variants pv ON oi.variant_id = pv.id
      WHERE date(oi.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(oi.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
        AND oi.seller_order_id IS NOT NULL
      GROUP BY date(oi.updated_at / 1000, 'unixepoch', 'localtime'), oi.product_id, oi.variant_id, pv.variant_name, pv.unit
      ORDER BY date DESC, total_cost DESC
    ''';

    return db.rawQuery(sql, [
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0]
    ]);
  }

  // 4. Mandi Profit Report
  Future<List<Map<String, dynamic>>> getMandiProfitReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        date(oc.updated_at / 1000, 'unixepoch', 'localtime') as date,
        SUM(oc.charge_amount) as daily_profit,
        SUM(oi.quantity * oi.selling_price) as daily_revenue,
        0.0 as daily_cost,
        COUNT(DISTINCT oi.buyer_order_id) as transactions,
        AVG(oc.charge_amount) as avg_transaction_profit
      FROM order_charges oc
      LEFT JOIN order_items oi ON oc.order_id = oi.buyer_order_id
      WHERE date(oc.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(oc.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
      GROUP BY date(oc.updated_at / 1000, 'unixepoch', 'localtime')
      ORDER BY date DESC
    ''';

    return db.rawQuery(sql, [
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0]
    ]);
  }

  // 5. Customer Ledger Report
  Future<List<Map<String, dynamic>>> getCustomerLedgerReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        c.id as customer_id,
        c.name as customer_name,
        c.phone as customer_phone,
        COUNT(*) as total_transactions,
        SUM(CASE WHEN oi.buyer_order_id IS NOT NULL THEN oi.quantity * oi.selling_price ELSE 0 END) as total_purchases,
        0.0 as total_sales,
        (SUM(CASE WHEN oi.buyer_order_id IS NOT NULL THEN oi.quantity * oi.selling_price ELSE 0 END) - 0.0) as net_balance
      FROM order_items oi
      LEFT JOIN customers c ON (oi.buyer_id = c.id OR oi.seller_id = c.id)
      WHERE date(oi.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(oi.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
      GROUP BY c.id, c.name, c.phone
      HAVING total_transactions > 0
      ORDER BY net_balance DESC
    ''';

    return db.rawQuery(sql, [
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0]
    ]);
  }

  // 6. Pending Payment Report
  Future<List<Map<String, dynamic>>> getPendingPaymentReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        c.name as customer_name,
        c.phone as customer_phone,
        c.id as customer_id,
        COUNT(*) as total_bills,
        SUM(CASE WHEN order_items.buyer_order_id IS NOT NULL THEN order_items.quantity * order_items.selling_price ELSE 0 END) as total_amount,
        COALESCE(SUM(cp.amount), 0) as paid_amount,
        (SUM(CASE WHEN order_items.buyer_order_id IS NOT NULL THEN order_items.quantity * order_items.selling_price ELSE 0 END) -
         COALESCE(SUM(cp.amount), 0)) as pending_amount,
        MIN(date(order_items.updated_at / 1000, 'unixepoch', 'localtime')) as oldest_bill_date,
        MAX(date(order_items.updated_at / 1000, 'unixepoch', 'localtime')) as latest_bill_date
      FROM order_items
      LEFT JOIN customers c ON order_items.buyer_id = c.id
      LEFT JOIN order_payments cp ON order_items.buyer_order_id = cp.order_id
      WHERE date(order_items.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(order_items.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
        AND order_items.buyer_order_id IS NOT NULL
      GROUP BY c.id, c.name, c.phone
      HAVING pending_amount > 0
      ORDER BY pending_amount DESC
    ''';

    return db.rawQuery(sql, [
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0]
    ]);
  }

  // Summary Report (Combined metrics)
  Future<Map<String, dynamic>> getReportsSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        COUNT(DISTINCT date(oi.updated_at / 1000, 'unixepoch', 'localtime')) as total_days,
        COUNT(DISTINCT oi.buyer_order_id) as total_transactions,
        SUM(oi.quantity * oi.selling_price) as total_revenue,
        0.0 as total_cost,
        COALESCE((SELECT SUM(oc.charge_amount) FROM order_charges oc
          JOIN order_items oi2 ON oc.order_id = oi2.buyer_order_id
          WHERE date(oc.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
            AND date(oc.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
            AND oi2.buyer_order_id IS NOT NULL), 0) as total_profit,
        COUNT(DISTINCT oi.product_id) as unique_products,
        COUNT(DISTINCT CASE WHEN oi.buyer_order_id IS NOT NULL THEN oi.buyer_id END) as unique_buyers,
        COUNT(DISTINCT CASE WHEN oi.seller_order_id IS NOT NULL THEN oi.seller_id END) as unique_sellers,
        AVG(oi.quantity * oi.selling_price) as avg_transaction_value
      FROM order_items oi
      WHERE date(oi.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(oi.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
    ''';

    final result = await db.rawQuery(sql, [
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0],
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0],
    ]);
    return result.isNotEmpty ? result.first : {};
  }

  // Payment Summary Methods
  Future<Map<String, dynamic>> getPaymentSummary({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await dbHelper.database;

    final bool hasDateFilter = fromDate != null && toDate != null;
    late final String fDate = fromDate!.toIso8601String().split('T')[0];
    late final String tDate = toDate!.toIso8601String().split('T')[0];

    String filter(String alias) {
      if (!hasDateFilter) return '';
      return "AND date($alias.updated_at / 1000, 'unixepoch', 'localtime') >= date(?) "
          "AND date($alias.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)";
    }

    List<String> args() => hasDateFilter ? [fDate, tDate] : [];
    List<String> args2() => hasDateFilter ? [fDate, tDate, fDate, tDate] : [];

    // Get total received amount from buyers
    final receivedAmountSql = '''
      SELECT COALESCE(SUM(op.amount), 0) as total_received
      FROM order_payments op
      WHERE op.amount > 0
        ${filter('op')}
        AND op.order_id IN (
          SELECT DISTINCT buyer_order_id FROM order_items
          WHERE buyer_order_id IS NOT NULL
        )
    ''';

    // Get pending payments from buyers: cart items not checked out + bill pending
    final pendingPaymentsSql = '''
      SELECT COALESCE(SUM(pending_amount), 0) as total_pending
      FROM (
        SELECT SUM(quantity * selling_price) as pending_amount
        FROM order_items
        WHERE buyer_order_id IS NULL
          AND buyer_id IS NOT NULL
          AND (is_deleted IS NULL OR is_deleted = 0)
          ${filter(DbTables.orderItems)}
        UNION ALL
        SELECT
          item_totals.item_total
          + COALESCE(charge_totals.total_charges, 0)
          + COALESCE(expense_totals.total_expenses, 0)
          - COALESCE(payment_totals.total_paid, 0) as pending_amount
        FROM (
          SELECT buyer_order_id as order_id, SUM(quantity * selling_price) as item_total
          FROM order_items
          WHERE buyer_order_id IS NOT NULL
          ${filter(DbTables.orderItems)}
          GROUP BY buyer_order_id
        ) item_totals
        LEFT JOIN (
          SELECT CAST(order_id AS INTEGER) as order_id, SUM(charge_amount) as total_charges
          FROM order_charges
          GROUP BY order_id
        ) charge_totals ON item_totals.order_id = charge_totals.order_id
        LEFT JOIN (
          SELECT order_id, SUM(expense_amount) as total_expenses
          FROM order_expenses
          GROUP BY order_id
        ) expense_totals ON item_totals.order_id = expense_totals.order_id
        LEFT JOIN (
          SELECT order_id, SUM(amount) as total_paid
          FROM order_payments
          GROUP BY order_id
        ) payment_totals ON item_totals.order_id = payment_totals.order_id
      ) sub
      WHERE pending_amount > 0
    ''';

    // Get total paid to sellers (actual payments made to sellers)
    final paidToSellersSql = '''
      SELECT COALESCE(SUM(op.amount), 0) as total_paid_to_sellers
      FROM order_payments op
      WHERE op.amount > 0
        ${filter('op')}
        AND op.order_id IN (
          SELECT DISTINCT seller_order_id FROM order_items
          WHERE seller_order_id IS NOT NULL
        )
    ''';

    // Get pending payments to sellers: cart items not yet checked out + bill pending
    final pendingToSellersSql = '''
      SELECT COALESCE(SUM(pending_amount), 0) as total_pending_to_sellers
      FROM (
        SELECT SUM(quantity * selling_price) as pending_amount
        FROM order_items
        WHERE seller_order_id IS NULL
          AND seller_id IS NOT NULL
          AND (is_deleted IS NULL OR is_deleted = 0)
          ${filter(DbTables.orderItems)}
        UNION ALL
        SELECT
          item_totals.item_total
          - COALESCE(charge_totals.total_charges, 0)
          - COALESCE(expense_totals.total_expenses, 0)
          - COALESCE(payment_totals.total_paid, 0) as pending_amount
        FROM (
          SELECT seller_order_id as order_id, SUM(quantity * selling_price) as item_total
          FROM order_items
          WHERE seller_order_id IS NOT NULL
          ${filter(DbTables.orderItems)}
          GROUP BY seller_order_id
        ) item_totals
        LEFT JOIN (
          SELECT CAST(order_id AS INTEGER) as order_id, SUM(charge_amount) as total_charges
          FROM order_charges
          GROUP BY order_id
        ) charge_totals ON item_totals.order_id = charge_totals.order_id
        LEFT JOIN (
          SELECT order_id, SUM(expense_amount) as total_expenses
          FROM order_expenses
          GROUP BY order_id
        ) expense_totals ON item_totals.order_id = expense_totals.order_id
        LEFT JOIN (
          SELECT order_id, SUM(amount) as total_paid
          FROM order_payments
          GROUP BY order_id
        ) payment_totals ON item_totals.order_id = payment_totals.order_id
      ) sub
      WHERE pending_amount > 0
    ''';

    final receivedResult = await db.rawQuery(receivedAmountSql, args());
    final pendingResult = await db.rawQuery(pendingPaymentsSql, args2());
    final paidToSellersResult = await db.rawQuery(paidToSellersSql, args());
    final pendingToSellersResult =
        await db.rawQuery(pendingToSellersSql, args2());

    return {
      'total_received':
          (receivedResult.first['total_received'] as num?)?.toDouble() ?? 0.0,
      'total_pending':
          (pendingResult.first['total_pending'] as num?)?.toDouble() ?? 0.0,
      'total_paid_to_sellers':
          (paidToSellersResult.first['total_paid_to_sellers'] as num?)
                  ?.toDouble() ??
              0.0,
      'total_pending_to_sellers':
          (pendingToSellersResult.first['total_pending_to_sellers'] as num?)
                  ?.toDouble() ??
              0.0,
    };
  }

  // Get today's orders count
  Future<int> getTodayOrdersCount() async {
    final db = await dbHelper.database;
    final today = DateTime.now().millisecondsSinceEpoch;

    const sql = '''
      SELECT COUNT(DISTINCT buyer_order_id) as orders_count
      FROM order_items
      WHERE date(updated_at / 1000, 'unixepoch', 'localtime') = date(?)
        AND buyer_order_id IS NOT NULL
    ''';

    final result = await db.rawQuery(sql, [today]);
    return (result.first['orders_count'] as num?)?.toInt() ?? 0;
  }

  // Get net balance (cash in hand + UPI - payables)
  Future<double> getNetBalance({DateTime? fromDate, DateTime? toDate}) async {
    final db = await dbHelper.database;
    final bool hasDateFilter = fromDate != null && toDate != null;
    late final String fDate = fromDate!.toIso8601String().split('T')[0];
    late final String tDate = toDate!.toIso8601String().split('T')[0];
    final List<String> args = hasDateFilter ? [fDate, tDate] : [];

    String filter(String alias) {
      if (!hasDateFilter) return '';
      return "AND date($alias.updated_at / 1000, 'unixepoch', 'localtime') >= date(?) "
          "AND date($alias.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)";
    }

    // Get cash in hand + UPI (received payments)
    final receivedSql = '''
      SELECT COALESCE(SUM(amount), 0) as total_received
      FROM order_payments
      WHERE amount > 0
        ${filter(DbTables.orderPayments)}
    ''';

    // Get total payables (pending payments to sellers)
    final payablesSql = '''
      SELECT COALESCE(SUM(order_charges.charge_amount), 0) as total_payables
      FROM order_charges
      JOIN order_items oi ON order_charges.order_id = oi.buyer_order_id
      WHERE oi.seller_order_id IS NULL
        AND oi.buyer_order_id IS NOT NULL
        ${filter(DbTables.orderCharges)}
    ''';

    final receivedResult = await db.rawQuery(receivedSql, args);
    final payablesResult = await db.rawQuery(payablesSql, args);

    final totalReceived =
        (receivedResult.first['total_received'] as num?)?.toDouble() ?? 0.0;
    final totalPayables =
        (payablesResult.first['total_payables'] as num?)?.toDouble() ?? 0.0;

    return totalReceived - totalPayables;
  }

  // Stock Transaction Report
  Future<List<Map<String, dynamic>>> getStockTransactionReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        date(st.updated_at / 1000, 'unixepoch', 'localtime') as date,
        st.stock_id,
        st.product_id,
        st.product_variant_id,
        pv.variant_name,
        pv.unit,
        COALESCE(pv.variant_name, 'Product ' || st.product_id) as product_name,
        st.buyer_id,
        c.name as buyer_name,
        SUM(st.buy_quantity) as buy_quantity,
        SUM(st.total_amount) as total_amount,
        AVG(st.total_amount / st.buy_quantity) as avg_price
      FROM stock_transactions st
      LEFT JOIN product_variants pv ON st.product_variant_id = pv.id
      LEFT JOIN customers c ON st.buyer_id = c.id
      WHERE date(st.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(st.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
        AND st.is_deleted = 0
      GROUP BY date(st.updated_at / 1000, 'unixepoch', 'localtime'),
        st.stock_id, st.product_id, st.product_variant_id,
        st.buyer_id, c.name, pv.variant_name, pv.unit
      ORDER BY date DESC, total_amount DESC
    ''';

    return db.rawQuery(sql, [
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0],
    ]);
  }

  // Stock Summary Report
  Future<List<Map<String, dynamic>>> getStockSummaryReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        s.id as stock_id,
        s.product_id,
        s.product_variant_id,
        COALESCE(pv.variant_name, 'Product ' || s.product_id) as product_name,
        pv.variant_name,
        pv.unit,
        s.initial_quantity,
        s.quantity,
        s.sold_quantity,
        s.loss_quantity,
        s.purchase_amount,
        s.sold_amount
      FROM stocks s
      LEFT JOIN product_variants pv ON s.product_variant_id = pv.id
      WHERE date(s.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(s.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
        AND s.is_deleted = 0
      ORDER BY s.updated_at DESC
    ''';

    return db.rawQuery(sql, [
      fromDate.toIso8601String().split('T')[0],
      toDate.toIso8601String().split('T')[0],
    ]);
  }
}
