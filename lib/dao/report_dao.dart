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
        date(order_items.created_at) as date,
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
      WHERE date(order_items.created_at) >= date(?)
        AND date(order_items.created_at) <= date(?)
      GROUP BY date(order_items.created_at), order_items.product_id, order_items.variant_id, pv.variant_name, pv.unit
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
        SUM(order_items.quantity * order_items.buying_price) as total_cost,
        SUM(order_items.quantity) as total_quantity,
        AVG(order_items.buying_price) as avg_buying_price
      FROM order_items
      LEFT JOIN customers c ON order_items.seller_id = c.id
      WHERE date(order_items.created_at) >= date(?)
        AND date(order_items.created_at) <= date(?)
        AND order_items.seller_order_id IS NULL
        AND order_items.buyer_order_id IS NULL
      GROUP BY order_items.seller_id, c.name, c.phone
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
      WHERE date(order_items.created_at) >= date(?)
        AND date(order_items.created_at) <= date(?)
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
        date(order_items.created_at) as date,
        SUM((order_items.selling_price - order_items.buying_price) * order_items.quantity) as daily_profit,
        SUM(order_items.quantity * order_items.selling_price) as daily_revenue,
        SUM(order_items.quantity * order_items.buying_price) as daily_cost,
        COUNT(*) as transactions,
        AVG((order_items.selling_price - order_items.buying_price) * order_items.quantity) as avg_transaction_profit
      FROM order_items
      WHERE date(order_items.created_at) >= date(?)
        AND date(order_items.created_at) <= date(?)
      GROUP BY date(order_items.created_at)
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
        SUM(CASE WHEN order_items.buyer_order_id IS NOT NULL THEN order_items.quantity * order_items.selling_price ELSE 0 END) as total_purchases,
        SUM(CASE WHEN order_items.seller_order_id IS NOT NULL THEN order_items.quantity * order_items.buying_price ELSE 0 END) as total_sales,
        (SUM(CASE WHEN order_items.buyer_order_id IS NOT NULL THEN order_items.quantity * order_items.selling_price ELSE 0 END) -
         SUM(CASE WHEN order_items.seller_order_id IS NOT NULL THEN order_items.quantity * order_items.buying_price ELSE 0 END)) as net_balance
      FROM order_items
      LEFT JOIN customers c ON (order_items.buyer_id = c.id OR order_items.seller_id = c.id)
      WHERE date(order_items.created_at) >= date(?)
        AND date(order_items.created_at) <= date(?)
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
        COALESCE(SUM(cp.receive_amount), 0) as paid_amount,
        (SUM(CASE WHEN order_items.buyer_order_id IS NOT NULL THEN order_items.quantity * order_items.selling_price ELSE 0 END) -
         COALESCE(SUM(cp.receive_amount), 0)) as pending_amount,
        MIN(date(order_items.created_at)) as oldest_bill_date,
        MAX(date(order_items.created_at)) as latest_bill_date
      FROM order_items
      LEFT JOIN customers c ON order_items.buyer_id = c.id
      LEFT JOIN order_payments cp ON order_items.buyer_order_id = cp.order_id
      WHERE date(order_items.created_at) >= date(?)
        AND date(order_items.created_at) <= date(?)
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
        cp.payment_method,
        COUNT(*) as transaction_count,
        SUM(cp.receive_amount) as total_amount,
        AVG(cp.receive_amount) as avg_transaction,
        MIN(date(cp.created_at)) as first_payment_date,
        MAX(date(cp.created_at)) as last_payment_date
      FROM order_payments cp
      WHERE date(cp.created_at) >= date(?)
        AND date(cp.created_at) <= date(?)
        AND cp.receive_amount > 0
      GROUP BY cp.payment_method
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
        MAX(date(order_items.created_at)) as last_sold_date,
        RANK() OVER (ORDER BY SUM(order_items.quantity * order_items.selling_price) DESC) as revenue_rank,
        RANK() OVER (ORDER BY SUM(order_items.quantity) DESC) as quantity_rank
      FROM order_items
      LEFT JOIN product_variants pv ON order_items.variant_id = pv.id
      WHERE date(order_items.created_at) >= date(?)
        AND date(order_items.created_at) <= date(?)
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
        COUNT(DISTINCT cc.cart_id) as unique_carts,
        (SUM(cc.charge_amount) / COUNT(DISTINCT cc.cart_id)) as avg_charge_per_cart
      FROM order_charges cc
      WHERE date(cc.created_at) >= date(?)
        AND date(cc.created_at) <= date(?)
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
        COUNT(DISTINCT date(order_items.created_at)) as total_days,
        COUNT(*) as total_transactions,
        SUM(order_items.quantity * order_items.selling_price) as total_revenue,
        SUM(order_items.quantity * order_items.buying_price) as total_cost,
        SUM((order_items.selling_price - order_items.buying_price) * order_items.quantity) as total_profit,
        COUNT(DISTINCT order_items.product_id) as unique_products,
        COUNT(DISTINCT CASE WHEN order_items.buyer_order_id IS NOT NULL THEN order_items.buyer_id END) as unique_buyers,
        COUNT(DISTINCT CASE WHEN order_items.seller_order_id IS NOT NULL THEN order_items.seller_id END) as unique_sellers,
        AVG(order_items.quantity * order_items.selling_price) as avg_transaction_value
      FROM order_items
      WHERE date(order_items.created_at) >= date(?)
        AND date(order_items.created_at) <= date(?)
    ''';

    final result = await db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
    return result.isNotEmpty ? result.first : {};
  }

  // Payment Summary Methods
  Future<Map<String, dynamic>> getPaymentSummary() async {
    final db = await dbHelper.database;

    // Get total received amount from buyers
    const receivedAmountSql = '''
      SELECT COALESCE(SUM(receive_amount), 0) as total_received
      FROM order_payments
      WHERE receive_amount > 0
    ''';

    // Get pending payments from buyers
    const pendingPaymentsSql = '''
      SELECT COALESCE(SUM(pending_amount), 0) as total_pending
      FROM (
        SELECT
          SUM(CASE WHEN order_items.buyer_order_id IS NOT NULL THEN order_items.quantity * order_items.selling_price ELSE 0 END) -
           COALESCE(SUM(cp.receive_amount), 0) as pending_amount
        FROM order_items
        LEFT JOIN order_payments cp ON order_items.buyer_order_id = cp.order_id
        WHERE order_items.buyer_order_id IS NOT NULL
        GROUP BY order_items.buyer_order_id
        HAVING pending_amount > 0
      )
    ''';

    // Get total paid to sellers
    const paidToSellersSql = '''
      SELECT COALESCE(SUM(order_items.quantity * order_items.buying_price), 0) as total_paid_to_sellers
      FROM order_items
      WHERE order_items.seller_order_id IS NOT NULL
    ''';

    // Get pending payments to sellers (unpaid purchases)
    const pendingToSellersSql = '''
      SELECT COALESCE(SUM(order_items.quantity * order_items.buying_price), 0) as total_pending_to_sellers
      FROM order_items
      WHERE order_items.seller_order_id IS NULL
        AND order_items.buyer_order_id IS NULL
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
    final today = DateTime.now().toIso8601String().split('T')[0];

    const sql = '''
      SELECT COUNT(DISTINCT buyer_order_id) as orders_count
      FROM order_items
      WHERE date(created_at) = date(?)
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
      SELECT COALESCE(SUM(receive_amount), 0) as total_received
      FROM order_payments
      WHERE receive_amount > 0
    ''';

    // Get total payables (pending payments to sellers)
    const payablesSql = '''
      SELECT COALESCE(SUM(order_items.quantity * order_items.buying_price), 0) as total_payables
      FROM order_items
      WHERE order_items.seller_order_id IS NULL
        AND order_items.buyer_order_id IS NULL
    ''';

    final receivedResult = await db.rawQuery(receivedSql);
    final payablesResult = await db.rawQuery(payablesSql);

    final totalReceived = (receivedResult.first['total_received'] as num?)?.toDouble() ?? 0.0;
    final totalPayables = (payablesResult.first['total_payables'] as num?)?.toDouble() ?? 0.0;

    return totalReceived - totalPayables;
  }
}
