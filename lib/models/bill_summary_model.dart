class BillSummary {
  final int cartId;
  final int customerId;
  final DateTime createdAt;
  final double itemTotal;
  final double chargesTotal;
  final double expensesTotal;
  final double receiveAmount;
  final double pendingAmount;
  final double pendingPayment;
  final double totalAmount;
  final int? billNumber;
  final String billType;

  const BillSummary({
    required this.cartId,
    required this.customerId,
    required this.createdAt,
    required this.itemTotal,
    required this.chargesTotal,
    required this.expensesTotal,
    required this.receiveAmount,
    required this.pendingAmount,
    required this.pendingPayment,
    required this.totalAmount,
    this.billNumber,
    this.billType = 'buyer',
  });

  double get totalCollected => receiveAmount;

  bool get isPending => pendingAmount > 0;

  String get paymentStatus {
    if (billType == 'seller') {
      return pendingPayment <= 0 ? 'Paid' : 'Unpaid';
    } else {
      return pendingAmount <= 0 ? 'Paid' : 'Unpaid';
    }
  }

  bool get isPaid => paymentStatus == 'Paid';

  bool get isUnpaid => paymentStatus == 'Unpaid';
}
