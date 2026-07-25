import 'package:mandyapp/utils/db_helper.dart';

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

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
  }

   // 2. Seller Purchase Summary
  Future<List<Map<String, dynamic>>> getSellerPurchaseSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        c.name as seller_name,
        c.phone as seller_phone,
        COUNT(*) as total_purchases,
        COALESCE(SUM(order_charges.charge_amount), 0) as total_cost,
        SUM(oi.quantity) as total_quantity,
      FROM order_items oi
      LEFT JOIN customers c ON oi.seller_id = c.id
      LEFT JOIN order_charges order_charges ON oi.buyer_order_id = order_charges.order_id
      WHERE date(oi.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(oi.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
        AND oi.seller_order_id IS NULL
        AND oi.buyer_order_id IS NULL
      GROUP BY oi.seller_id, c.name, c.phone
      ORDER BY total_cost DESC
    ''';

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
  }

  // 3. Buyer Sales Summary
  Future<List<Map<String, dynamic>>> getBuyerSalesSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        c.name as buyer_name,
        c.phone as buyer_phone,
        COUNT(DISTINCT order_items.buyer_order_id) as total_bills,
        SUM(order_items.quantity * order_items.selling_price) as total_revenue,
        SUM(order_items.quantity) as total_quantity,
        AVG(order_items.selling_price) as avg_selling_price
      FROM order_items
      LEFT JOIN customers c ON order_items.buyer_id = c.id
      WHERE date(order_items.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(order_items.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
        AND order_items.buyer_order_id IS NOT NULL
      GROUP BY order_items.buyer_id, c.name, c.phone
      ORDER BY total_revenue DESC
    ''';

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
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

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
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

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
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

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
  }

  // 7. Payment Mode Summary
  Future<List<Map<String, dynamic>>> getPaymentModeSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        cp.source as payment_method,
        COUNT(*) as transaction_count,
        SUM(cp.amount) as total_amount,
        AVG(cp.amount) as avg_transaction,
        MIN(date(cp.updated_at / 1000, 'unixepoch', 'localtime')) as first_payment_date,
        MAX(date(cp.updated_at / 1000, 'unixepoch', 'localtime')) as last_payment_date
      FROM order_payments cp
      WHERE date(cp.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(cp.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
        AND cp.amount > 0
      GROUP BY cp.source
      ORDER BY total_amount DESC
    ''';

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
  }

  // 9. Top Selling Products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        order_items.product_id,
        order_items.variant_id,
        pv.variant_name,
        pv.unit,
        SUM(order_items.quantity) as total_quantity_sold,
        SUM(order_items.quantity * order_items.selling_price) as total_revenue,
        COUNT(*) as transaction_count,
        AVG(order_items.selling_price) as avg_selling_price,
        MAX(date(order_items.updated_at / 1000, 'unixepoch', 'localtime')) as last_sold_date,
        RANK() OVER (ORDER BY SUM(order_items.quantity * order_items.selling_price) DESC) as revenue_rank,
        RANK() OVER (ORDER BY SUM(order_items.quantity) DESC) as quantity_rank
      FROM order_items
      LEFT JOIN product_variants pv ON order_items.variant_id = pv.id
      WHERE date(order_items.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(order_items.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
        AND order_items.buyer_order_id IS NOT NULL
      GROUP BY order_items.product_id, order_items.variant_id, pv.variant_name, pv.unit
      ORDER BY total_revenue DESC
      LIMIT 20
    ''';

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
  }

  // 10. Charges Performance Report
  Future<List<Map<String, dynamic>>> getChargesPerformanceReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        cc.charge_name,
        COUNT(*) as times_applied,
        SUM(cc.charge_amount) as total_charge_amount,
        AVG(cc.charge_amount) as avg_charge_amount,
        COUNT(DISTINCT cc.order_id) as unique_carts,
        (SUM(cc.charge_amount) / COUNT(DISTINCT cc.order_id)) as avg_charge_per_cart
      FROM order_charges cc
      WHERE date(cc.updated_at / 1000, 'unixepoch', 'localtime') >= date(?)
        AND date(cc.updated_at / 1000, 'unixepoch', 'localtime') <= date(?)
      GROUP BY cc.charge_name
      ORDER BY total_charge_amount DESC
    ''';

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
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
  Future<Map<String, dynamic>> getPaymentSummary() async {
    final db = await dbHelper.database;

    // Get total received amount from buyers (exclude pending/unpaid)
    const receivedAmountSql = '''
      SELECT COALESCE(SUM(op.amount), 0) as total_received
      FROM order_payments op
      WHERE op.amount > 0
        AND op.order_id IN (
          SELECT DISTINCT buyer_order_id FROM order_items
          WHERE buyer_order_id IS NOT NULL
        )
    ''';

    // Get pending payments from buyers (unpaid balance)
    const pendingPaymentsSql = '''
      SELECT COALESCE(SUM(pending_amount), 0) as total_pending
      FROM (
        SELECT
          SUM(CASE WHEN oi.buyer_order_id IS NOT NULL THEN oi.quantity * oi.selling_price ELSE 0 END) -
           COALESCE(SUM(CASE WHEN cp.order_id IS NOT NULL THEN cp.amount ELSE 0 END), 0) as pending_amount
        FROM order_items oi
        LEFT JOIN order_payments cp ON oi.buyer_order_id = cp.order_id
        WHERE oi.buyer_order_id IS NOT NULL
        GROUP BY oi.buyer_order_id
        HAVING pending_amount > 0
      )
    ''';

    // Get total paid to sellers (charges on fulfilled buyer orders + seller directly placed orders)
    const paidToSellersSql = '''
      SELECT COALESCE(SUM(charge_amount), 0) as total_paid_to_sellers
      FROM order_charges
      WHERE order_id IN (
        SELECT DISTINCT buyer_order_id FROM order_items
        WHERE buyer_order_id IS NOT NULL AND seller_order_id IS NOT NULL
        UNION
        SELECT DISTINCT seller_order_id FROM order_items
        WHERE buyer_order_id IS NULL AND seller_order_id IS NOT NULL
      )
    ''';

    // Get pending payments to sellers (unpaid purchases)
    const pendingToSellersSql = '''
      SELECT COALESCE(SUM(charge_amount), 0) as total_pending_to_sellers
      FROM order_charges
      WHERE order_id IN (
        SELECT DISTINCT buyer_order_id FROM order_items
        WHERE buyer_order_id IS NOT NULL AND seller_order_id IS NULL
      )
    ''';

    final receivedResult = await db.rawQuery(receivedAmountSql);
    final pendingResult = await db.rawQuery(pendingPaymentsSql);
    final paidToSellersResult = await db.rawQuery(paidToSellersSql);
    final pendingToSellersResult = await db.rawQuery(pendingToSellersSql);

    return {
      'total_received': (receivedResult.first['total_received'] as num?)?.toDouble() ?? 0.0,
      'total_pending': (pendingResult.first['total_pending'] as num?)?.toDouble() ?? 0.0,
      'total_paid_to_sellers': (paidToSellersResult.first['total_paid_to_sellers'] as num?)?.toDouble() ?? 0.0,
      'total_pending_to_sellers': (pendingToSellersResult.first['total_pending_to_sellers'] as num?)?.toDouble() ?? 0.0,
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
  Future<double> getNetBalance() async {
    final db = await dbHelper.database;

    // Get cash in hand + UPI (received payments)
    const receivedSql = '''
      SELECT COALESCE(SUM(amount), 0) as total_received
      FROM order_payments
      WHERE amount > 0
    ''';

    // Get total payables (pending payments to sellers)
    const payablesSql = '''
      SELECT COALESCE(SUM(order_charges.charge_amount), 0) as total_payables
      FROM order_charges
      JOIN order_items oi ON order_charges.order_id = oi.buyer_order_id
      WHERE oi.seller_order_id IS NULL
        AND oi.buyer_order_id IS NOT NULL
    ''';

    final receivedResult = await db.rawQuery(receivedSql);
    final payablesResult = await db.rawQuery(payablesSql);

    final totalReceived = (receivedResult.first['total_received'] as num?)?.toDouble() ?? 0.0;
    final totalPayables = (payablesResult.first['total_payables'] as num?)?.toDouble() ?? 0.0;

    return totalReceived - totalPayables;
  }
}
