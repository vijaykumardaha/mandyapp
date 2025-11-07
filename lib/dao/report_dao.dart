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
        date(item_sales.created_at) as date,
        item_sales.product_id,
        item_sales.variant_id,
        pv.variant_name,
        pv.unit,
        SUM(item_sales.quantity) as total_quantity,
        COUNT(*) as transaction_count,
        SUM(item_sales.quantity * item_sales.selling_price) as total_revenue,
        AVG(item_sales.selling_price) as avg_price
      FROM item_sales
      LEFT JOIN product_variants pv ON item_sales.variant_id = pv.id
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
      GROUP BY date(item_sales.created_at), item_sales.product_id, item_sales.variant_id, pv.variant_name, pv.unit
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
        SUM(item_sales.quantity * item_sales.buying_price) as total_cost,
        SUM(item_sales.quantity) as total_quantity,
        AVG(item_sales.buying_price) as avg_buying_price
      FROM item_sales
      LEFT JOIN customers c ON item_sales.seller_id = c.id
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
        AND item_sales.seller_cart_id IS NULL
        AND item_sales.buyer_cart_id IS NULL
      GROUP BY item_sales.seller_id, c.name, c.phone
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
        COUNT(DISTINCT item_sales.buyer_cart_id) as total_bills,
        SUM(item_sales.quantity * item_sales.selling_price) as total_revenue,
        SUM(item_sales.quantity) as total_quantity,
        AVG(item_sales.selling_price) as avg_selling_price
      FROM item_sales
      LEFT JOIN customers c ON item_sales.buyer_id = c.id
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
        AND item_sales.buyer_cart_id IS NOT NULL
      GROUP BY item_sales.buyer_id, c.name, c.phone
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
        date(item_sales.created_at) as date,
        SUM((item_sales.selling_price - item_sales.buying_price) * item_sales.quantity) as daily_profit,
        SUM(item_sales.quantity * item_sales.selling_price) as daily_revenue,
        SUM(item_sales.quantity * item_sales.buying_price) as daily_cost,
        COUNT(*) as transactions,
        AVG((item_sales.selling_price - item_sales.buying_price) * item_sales.quantity) as avg_transaction_profit
      FROM item_sales
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
      GROUP BY date(item_sales.created_at)
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
        SUM(CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN item_sales.quantity * item_sales.selling_price ELSE 0 END) as total_purchases,
        SUM(CASE WHEN item_sales.seller_cart_id IS NOT NULL THEN item_sales.quantity * item_sales.buying_price ELSE 0 END) as total_sales,
        (SUM(CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN item_sales.quantity * item_sales.selling_price ELSE 0 END) -
         SUM(CASE WHEN item_sales.seller_cart_id IS NOT NULL THEN item_sales.quantity * item_sales.buying_price ELSE 0 END)) as net_balance
      FROM item_sales
      LEFT JOIN customers c ON (item_sales.buyer_id = c.id OR item_sales.seller_id = c.id)
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
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
        SUM(CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN item_sales.quantity * item_sales.selling_price ELSE 0 END) as total_amount,
        COALESCE(SUM(cp.receive_amount), 0) as paid_amount,
        (SUM(CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN item_sales.quantity * item_sales.selling_price ELSE 0 END) -
         COALESCE(SUM(cp.receive_amount), 0)) as pending_amount,
        MIN(date(item_sales.created_at)) as oldest_bill_date,
        MAX(date(item_sales.created_at)) as latest_bill_date
      FROM item_sales
      LEFT JOIN customers c ON item_sales.buyer_id = c.id
      LEFT JOIN cart_payments cp ON item_sales.buyer_cart_id = cp.cart_id
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
        AND item_sales.buyer_cart_id IS NOT NULL
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
      FROM cart_payments cp
      WHERE date(cp.created_at) >= date(?)
        AND date(cp.created_at) <= date(?)
        AND cp.receive_amount > 0
      GROUP BY cp.payment_method
      ORDER BY total_amount DESC
    ''';

    return db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
  }

  // 8. Stock Movement Report
  Future<List<Map<String, dynamic>>> getStockMovementReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await dbHelper.database;
    const sql = '''
      SELECT
        p.id as product_id,
        pv.variant_name,
        pv.unit,
        SUM(CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN item_sales.quantity ELSE 0 END) as quantity_sold,
        SUM(CASE WHEN item_sales.seller_cart_id IS NOT NULL THEN item_sales.quantity ELSE 0 END) as quantity_purchased,
        (SUM(CASE WHEN item_sales.seller_cart_id IS NOT NULL THEN item_sales.quantity ELSE 0 END) -
         SUM(CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN item_sales.quantity ELSE 0 END)) as net_stock_change,
        COUNT(CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN 1 END) as sales_transactions,
        COUNT(CASE WHEN item_sales.seller_cart_id IS NOT NULL THEN 1 END) as purchase_transactions
      FROM item_sales
      LEFT JOIN product_variants pv ON item_sales.variant_id = pv.id
      LEFT JOIN products p ON item_sales.product_id = p.id
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
      GROUP BY item_sales.product_id, item_sales.variant_id, pv.variant_name, pv.unit
      ORDER BY ABS(net_stock_change) DESC
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
        item_sales.product_id,
        item_sales.variant_id,
        pv.variant_name,
        pv.unit,
        SUM(item_sales.quantity) as total_quantity_sold,
        SUM(item_sales.quantity * item_sales.selling_price) as total_revenue,
        COUNT(*) as transaction_count,
        AVG(item_sales.selling_price) as avg_selling_price,
        MAX(date(item_sales.created_at)) as last_sold_date,
        RANK() OVER (ORDER BY SUM(item_sales.quantity * item_sales.selling_price) DESC) as revenue_rank,
        RANK() OVER (ORDER BY SUM(item_sales.quantity) DESC) as quantity_rank
      FROM item_sales
      LEFT JOIN product_variants pv ON item_sales.variant_id = pv.id
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
        AND item_sales.buyer_cart_id IS NOT NULL
      GROUP BY item_sales.product_id, item_sales.variant_id, pv.variant_name, pv.unit
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
      FROM cart_charges cc
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
        COUNT(DISTINCT date(item_sales.created_at)) as total_days,
        COUNT(*) as total_transactions,
        SUM(item_sales.quantity * item_sales.selling_price) as total_revenue,
        SUM(item_sales.quantity * item_sales.buying_price) as total_cost,
        SUM((item_sales.selling_price - item_sales.buying_price) * item_sales.quantity) as total_profit,
        COUNT(DISTINCT item_sales.product_id) as unique_products,
        COUNT(DISTINCT CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN item_sales.buyer_id END) as unique_buyers,
        COUNT(DISTINCT CASE WHEN item_sales.seller_cart_id IS NOT NULL THEN item_sales.seller_id END) as unique_sellers,
        AVG(item_sales.quantity * item_sales.selling_price) as avg_transaction_value
      FROM item_sales
      WHERE date(item_sales.created_at) >= date(?)
        AND date(item_sales.created_at) <= date(?)
    ''';

    final result = await db.rawQuery(sql, [fromDate.toIso8601String().split('T')[0], toDate.toIso8601String().split('T')[0]]);
    return result.isNotEmpty ? result.first : {};
  }

  // Stock Summary Methods
  Future<Map<String, dynamic>> getStockSummary() async {
    final db = await dbHelper.database;

    // Get total available stock
    const totalStockSql = '''
      SELECT
        SUM(current_stock) as total_stock,
        COUNT(*) as total_items
      FROM product_stocks
    ''';

    // Get low stock items (less than or equal to 10 units)
    const lowStockSql = '''
      SELECT COUNT(*) as low_stock_count
      FROM product_stocks
      WHERE current_stock <= 10 AND current_stock > 0
    ''';

    // Get out of stock items (zero stock)
    const outOfStockSql = '''
      SELECT COUNT(*) as out_of_stock_count
      FROM product_stocks
      WHERE current_stock = 0
    ''';

    final totalStockResult = await db.rawQuery(totalStockSql);
    final lowStockResult = await db.rawQuery(lowStockSql);
    final outOfStockResult = await db.rawQuery(outOfStockSql);

    return {
      'total_stock': (totalStockResult.first['total_stock'] as num?)?.toDouble() ?? 0.0,
      'total_items': (totalStockResult.first['total_items'] as num?)?.toInt() ?? 0,
      'low_stock_count': (lowStockResult.first['low_stock_count'] as num?)?.toInt() ?? 0,
      'out_of_stock_count': (outOfStockResult.first['out_of_stock_count'] as num?)?.toInt() ?? 0,
    };
  }

  // Payment Summary Methods
  Future<Map<String, dynamic>> getPaymentSummary() async {
    final db = await dbHelper.database;

    // Get total received amount from buyers
    const receivedAmountSql = '''
      SELECT COALESCE(SUM(receive_amount), 0) as total_received
      FROM cart_payments
      WHERE receive_amount > 0
    ''';

    // Get pending payments from buyers
    const pendingPaymentsSql = '''
      SELECT COALESCE(SUM(pending_amount), 0) as total_pending
      FROM (
        SELECT
          (SUM(CASE WHEN item_sales.buyer_cart_id IS NOT NULL THEN item_sales.quantity * item_sales.selling_price ELSE 0 END) -
           COALESCE(SUM(cp.receive_amount), 0)) as pending_amount
        FROM item_sales
        LEFT JOIN cart_payments cp ON item_sales.buyer_cart_id = cp.cart_id
        WHERE item_sales.buyer_cart_id IS NOT NULL
        GROUP BY item_sales.buyer_cart_id
        HAVING pending_amount > 0
      )
    ''';

    // Get total paid to sellers
    const paidToSellersSql = '''
      SELECT COALESCE(SUM(item_sales.quantity * item_sales.buying_price), 0) as total_paid_to_sellers
      FROM item_sales
      WHERE item_sales.seller_cart_id IS NOT NULL
    ''';

    // Get pending payments to sellers (unpaid purchases)
    const pendingToSellersSql = '''
      SELECT COALESCE(SUM(item_sales.quantity * item_sales.buying_price), 0) as total_pending_to_sellers
      FROM item_sales
      WHERE item_sales.seller_cart_id IS NULL
        AND item_sales.buyer_cart_id IS NULL
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
      SELECT COUNT(DISTINCT buyer_cart_id) as orders_count
      FROM item_sales
      WHERE date(created_at) = date(?)
        AND buyer_cart_id IS NOT NULL
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
      FROM cart_payments
      WHERE receive_amount > 0
    ''';

    // Get total payables (pending payments to sellers)
    const payablesSql = '''
      SELECT COALESCE(SUM(item_sales.quantity * item_sales.buying_price), 0) as total_payables
      FROM item_sales
      WHERE item_sales.seller_cart_id IS NULL
        AND item_sales.buyer_cart_id IS NULL
    ''';

    final receivedResult = await db.rawQuery(receivedSql);
    final payablesResult = await db.rawQuery(payablesSql);

    final totalReceived = (receivedResult.first['total_received'] as num?)?.toDouble() ?? 0.0;
    final totalPayables = (payablesResult.first['total_payables'] as num?)?.toDouble() ?? 0.0;

    return totalReceived - totalPayables;
  }
}
