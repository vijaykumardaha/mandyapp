class BillSummary {
  final int cartId;
  final int customerId;
  final DateTime createdAt;
  final double itemTotal;
  final double chargesTotal;
  final double receiveAmount;
  final double pendingAmount;
  final double pendingPayment;
  final double totalAmount;
  final int? billNumber;
  final String status;
  final String billType;

  const BillSummary({
    required this.cartId,
    required this.customerId,
    required this.createdAt,
    required this.itemTotal,
    required this.chargesTotal,
    required this.receiveAmount,
    required this.pendingAmount,
    required this.pendingPayment,
    required this.totalAmount,
    this.billNumber,
    this.status = 'open',
    this.billType = 'buyer',
  });

  double get totalCollected => receiveAmount;

  bool get isPending => pendingAmount > 0;

  bool get isOpen => status.toLowerCase() == 'open';

  bool get isCompleted => status.toLowerCase() == 'completed';

  // Payment status based on cart type and pending amounts
  String get paymentStatus {
    if (billType == 'seller') {
      // For seller bills, check if payment is fully received
      return pendingPayment <= 0 ? 'Paid' : 'Unpaid';
    } else {
      // For buyer bills, check if all amount is collected
      return pendingAmount <= 0 ? 'Paid' : 'Unpaid';
    }
  }

  bool get isPaid {
    return paymentStatus == 'Paid';
  }

  bool get isUnpaid {
    return paymentStatus == 'Unpaid';
  }
}
